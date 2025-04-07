module Serialization

"""
    UnsupportedPreferenceError(option, options)

Error thrown when an unknown `options` value is used for a given set of `options`.
"""
struct UnsupportedPreferenceError{T, P} <: Exception
    option::T
    options::P
end

function Base.showerror(io::IO, e::UnsupportedPreferenceError)
    print(io, "unknown preference `$(e.option)` for `$(e.options.OptionName)`.")
    print(io, "Available preferences are ")
    join(io, map(s -> string('`', e.options.to_string(s), '`'), e.options.AvailableOptions), ", ", " and ")
end

# Using `JSON` instead for `to_json` of `JSON3` here is intentional.
# `JSON3` does not support custom serializers, and `JSON` does.
import JSON
import JSON.Writer:
    StructuralContext,
    begin_object,
    end_object,
    begin_array,
    end_array,
    show_pair,
    show_key,
    show_json,
    show_element,
    delimit,
    indent

"""
    JSONSerialization(; kwargs...)

Type-safe JSON serializer for OpenAPI data types with configurable multi-dimensional array handling.

# Keywords
- `mdarray_repr`: Multi-dimensional array representation format, see [`RxInferServer.Serialization.MultiDimensionalArrayRepr`](@ref)
- `mdarray_data`: Multi-dimensional array data encoding format, see [`RxInferServer.Serialization.MultiDimensionalArrayData`](@ref)
"""
Base.@kwdef struct JSONSerialization <: JSON.Serializations.Serialization
    mdarray_repr::UInt8 = MultiDimensionalArrayRepr.Dict
    mdarray_data::UInt8 = MultiDimensionalArrayData.ArrayOfArrays

    distributions_repr::UInt8 = DistributionsRepr.Dict
    distributions_data::UInt8 = DistributionsData.NamedParams
end

struct UnsupportedTypeSerializationError <: Exception
    type::Type
end

function Base.showerror(io::IO, e::UnsupportedTypeSerializationError)
    print(io, "serialization of type $(e.type) is not supported")
end

function show_json(::StructuralContext, ::JSONSerialization, value)
    throw(UnsupportedTypeSerializationError(typeof(value)))
end

# Include the serialization functions for default types
include("serialization_default.jl")

# Include the serialization functions for multi-dimensional arrays
include("serialization_mdarrays.jl")

# Include the serialization functions for distributions
include("serialization_distributions.jl")

"""
    to_json([io::IO], [serialization::JSONSerialization], value)

Serialize `value` to JSON using the specified serialization strategy.

Returns a string if `io` is not provided.

See also: [`RxInferServer.Serialization.JSONSerialization`](@ref)
"""
function to_json end

to_json(value) = to_json(JSONSerialization(), value)
to_json(s::JSONSerialization, value) = sprint(show_json, s, value)
to_json(io::IO, value) = show_json(io, JSONSerialization(), value)
to_json(io::IO, s::JSONSerialization, value) = show_json(io, s, value)

"""
    from_json(string)

Parse a JSON string into Julia data structures.

```jldoctest
julia> import RxInferServer.Serialization: JSONSerialization, MultiDimensionalArrayRepr, MultiDimensionalArrayData, to_json, from_json

julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.Dict, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

julia> from_json(to_json(s, [1 2; 3 4]))
Dict{String, Any} with 4 entries:
  "shape"    => Any[2, 2]
  "encoding" => "array_of_arrays"
  "data"     => Any[Any[1, 2], Any[3, 4]]
  "type"     => "mdarray"
```

Note: No post-processing is performed on the deserialized value.
"""
from_json(string) = JSON.parse(string)

end
