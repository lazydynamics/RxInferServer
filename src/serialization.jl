module Serialization

# Preference based serialization of multidimensional arrays, such as matrices and tensors.
# The major problem and potential solution is described here:
# https://github.com/lazydynamics/RxInferServer/issues/59
using EnumX

"""
Specifies the encoding format for multi-dimensional array data.

See also: [`RxInferServer.Serialization.MultiDimensionalArrayRepr`](@ref)
"""
@enumx MultiDimensionalArrayData::UInt8 begin
    """
    Encodes the data of multi-dimensional arrays as nested arrays of arrays with row-major ordering.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"

    julia> to_json(s, [1 3; 2 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"
    ```

    !!! note
        Julia uses column-major ordering for multi-dimensional arrays, but this setting explicitly uses row-major ordering.
    """
    ArrayOfArrays
end

# This is mostly for convenience to convert the preference to a UInt8.
Base.convert(::Type{UInt8}, preference::MultiDimensionalArrayData.T) = Integer(preference)::UInt8
@inline Base.:(==)(a::UInt8, b::MultiDimensionalArrayData.T) = a == Integer(b)
@inline Base.:(==)(a::MultiDimensionalArrayData.T, b::UInt8) = Integer(a) == b

"""
Specifies the JSON representation format for multi-dimensional arrays.

See also: [`RxInferServer.Serialization.MultiDimensionalArrayData`](@ref)
"""
@enumx MultiDimensionalArrayRepr::UInt8 begin
    """
    Represents the multi-dimensional array as a dictionary with the following keys:
    - `type` set to `"mdarray"`
    - `encoding` set to to a selected transformation of the array, e.g. `"array_of_arrays"`
    - `shape` set to the size of the array
    - `data` set to the encoded array itself as defined by the transformation

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.Dict, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    ```
    """
    Dict

    """
    Same as [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref), but excludes the `encoding` key, leaving only the `type`, `shape` and `data` keys.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictTypeAndShape, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    ```
    """
    DictTypeAndShape

    """
    Same as [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref), but excludes the `encoding` and `type` keys, leaving only the `shape` and `data` keys.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictShape, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "{\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    ```
    """
    DictShape

    """
    Compact representation of the multi-dimensional array as returned from the transformation.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.Data, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "[[1,3],[2,4]]"
    ```
    """
    Data
end

# This is mostly for convenience to convert the preference to a UInt8.
Base.convert(::Type{UInt8}, preference::MultiDimensionalArrayRepr.T) = Integer(preference)::UInt8
@inline Base.:(==)(a::UInt8, b::MultiDimensionalArrayRepr.T) = a == Integer(b)
@inline Base.:(==)(a::MultiDimensionalArrayRepr.T, b::UInt8) = Integer(a) == b

"""
    UnsupportedPreferenceError(option, available, preference)

Error thrown when an unknown `preference` value is used for a given `option`.
"""
struct UnsupportedPreferenceError{A, P} <: Exception
    option::Symbol
    available::A
    preference::P
end

function Base.showerror(io::IO, e::UnsupportedPreferenceError)
    print(io, "unknown preference value `$(e.preference)` for `$(e.option)`. Available preferences are:")
    for preference in instances(e.available.T)
        print(io, " ", preference, "=", Integer(preference))
    end
end

# Using `JSON` instead for `to_json` of `JSON3` here is intentional.
# `JSON3` does not support custom serializers, and `JSON` does.
import JSON
import JSON.Writer:
    StructuralContext, begin_object, end_object, begin_array, end_array, show_pair, show_key, show_json, show_element

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

# OpenAPI has the following types defined
# https://swagger.io/docs/specification/v3_0/data-models/data-types/
# - string (this includes dates and files)
# - number 
# - integer
# - boolean
# - array 
# - object
show_json(io::StructuralContext, ::JSONSerialization, value::String) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::JSONSerialization, value::Number) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::JSONSerialization, value::Bool) = show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::JSONSerialization, value::Union{Missing, Nothing}) =
    show_json(io, JSON.StandardSerialization(), value)

# String - date-time including timezones
using Dates, TimeZones

show_json(io::StructuralContext, ::JSONSerialization, value::DateTime) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::JSONSerialization, value::ZonedDateTime) =
    show_json(io, JSON.StandardSerialization(), value)

# Vector-like values
show_json(io::StructuralContext, s::JSONSerialization, value::Tuple) = __json_serialization_vector_like(io, s, value)
show_json(io::StructuralContext, s::JSONSerialization, value::AbstractVector) =
    __json_serialization_vector_like(io, s, value)

function __json_serialization_vector_like(io::StructuralContext, s::JSONSerialization, vectorlike)
    begin_array(io)
    foreach(element -> show_element(io, s, element), vectorlike)
    end_array(io)
end

# Dict-like values
show_json(io::StructuralContext, s::JSONSerialization, value::NamedTuple) = __json_serialization_dict_like(io, s, value)
show_json(io::StructuralContext, s::JSONSerialization, value::AbstractDict) =
    __json_serialization_dict_like(io, s, value)

function __json_serialization_dict_like(io::StructuralContext, s::JSONSerialization, dictlike)
    begin_object(io)
    foreach(pair -> show_pair(io, s, pair), pairs(dictlike))
    end_object(io)
end

# We also support serialization of OpenAPI defined types, which are subtypes of `APIModel`
using RxInferServerOpenAPI

function show_json(io::StructuralContext, s::JSONSerialization, value::RxInferServerOpenAPI.OpenAPI.APIModel)
    begin_object(io)
    for field in propertynames(value)
        show_pair(io, s, field => getproperty(value, field))
    end
    end_object(io)
end

# Multi-dimensional arrays, preference based serialization

function show_json(io::StructuralContext, serialization::JSONSerialization, value::AbstractArray)
    mdarray_data = serialization.mdarray_data
    mdarray_repr = serialization.mdarray_repr

    if mdarray_repr != MultiDimensionalArrayRepr.Data
        begin_object(io)
    end

    if mdarray_repr == MultiDimensionalArrayRepr.Dict
        show_pair(io, JSON.StandardSerialization(), :type => :mdarray)
        show_pair(io, JSON.StandardSerialization(), :encoding => :array_of_arrays)
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif mdarray_repr == MultiDimensionalArrayRepr.DictTypeAndShape
        show_pair(io, JSON.StandardSerialization(), :type => :mdarray)
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif mdarray_repr == MultiDimensionalArrayRepr.DictShape
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif mdarray_repr == MultiDimensionalArrayRepr.Data
        # noop
    else
        throw(UnsupportedPreferenceError(:mdarray_repr, MultiDimensionalArrayRepr, mdarray_repr))
    end

    if mdarray_data == MultiDimensionalArrayData.ArrayOfArrays
        show_json(io, JSON.StandardSerialization(), value)
    else
        throw(UnsupportedPreferenceError(:mdarray_data, MultiDimensionalArrayData, mdarray_data))
    end

    if mdarray_repr != MultiDimensionalArrayRepr.Data
        end_object(io)
    end
end

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
  "data"     => Any[Any[1, 3], Any[2, 4]]
  "type"     => "mdarray"
```

Note: No post-processing is performed on the deserialized value.
"""
from_json(string) = JSON.parse(string)

end
