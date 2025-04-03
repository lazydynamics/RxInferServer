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
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"

    julia> to_json(s, [1 3; 2 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    ```

    !!! note
        Julia uses column-major ordering for multi-dimensional arrays, but this setting explicitly uses row-major ordering.
    """
    ArrayOfArrays

    """
    Encodes the data of multi-dimensional arrays as a flattened array using column-major ordering.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.ReshapeColumnMajor);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"reshape_column_major\\",\\"shape\\":[2,2],\\"data\\":[1,3,2,4]}"

    julia> to_json(s, [1 3; 2 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"reshape_column_major\\",\\"shape\\":[2,2],\\"data\\":[1,2,3,4]}"
    ```

    !!! note
        Julia uses column-major ordering for multi-dimensional arrays, so this encoding preserves the natural ordering of elements in memory.
    """
    ReshapeColumnMajor

    """
    Encodes the data of multi-dimensional arrays as a flattened array using row-major ordering.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.ReshapeRowMajor);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"reshape_row_major\\",\\"shape\\":[2,2],\\"data\\":[1,2,3,4]}"

    julia> to_json(s, [1 3; 2 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"reshape_row_major\\",\\"shape\\":[2,2],\\"data\\":[1,3,2,4]}"
    ```

    !!! note
        This encoding traverses the array in row-major order, which is different from Julia's native column-major storage,
        but is compatible with `numpy.ndarray` memory layout.
    """
    ReshapeRowMajor

    """
    Encodes the data of multi-dimensional arrays as a single array containing only the diagonal elements of the parent array.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.Diagonal);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"diagonal\\",\\"shape\\":[2,2],\\"data\\":[1,4]}"
    """
    Diagonal

    """
    Removes the multi-dimensional array data from the response entirely.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.None);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"none\\",\\"shape\\":[2,2],\\"data\\":null}"
    ```

    !!! note
        Use [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Data`](@ref) to remove everything.
    """
    None
end

# This is mostly for convenience to convert the preference to a UInt8.
Base.convert(::Type{UInt8}, preference::MultiDimensionalArrayData.T) = Integer(preference)::UInt8
@inline Base.:(==)(a::UInt8, b::MultiDimensionalArrayData.T) = a == Integer(b)
@inline Base.:(==)(a::MultiDimensionalArrayData.T, b::UInt8) = Integer(a) == b

function Base.convert(::Type{MultiDimensionalArrayData.T}, preference::AbstractString)
    if preference == "array_of_arrays"
        return MultiDimensionalArrayData.ArrayOfArrays
    elseif preference == "reshape_column_major"
        return MultiDimensionalArrayData.ReshapeColumnMajor
    elseif preference == "reshape_row_major"
        return MultiDimensionalArrayData.ReshapeRowMajor
    elseif preference == "diagonal"
        return MultiDimensionalArrayData.Diagonal
    elseif preference == "none"
        return MultiDimensionalArrayData.None
    else
        throw(UnsupportedPreferenceError(:mdarray_data, MultiDimensionalArrayData, preference))
    end
end

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
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"
    ```
    """
    Dict

    """
    Same as [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref), but excludes the `encoding` key, leaving only the `type`, `shape` and `data` keys.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictTypeAndShape, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"
    ```
    """
    DictTypeAndShape

    """
    Same as [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref), but excludes the `encoding` and `type` keys, leaving only the `shape` and `data` keys.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictShape, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "{\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"
    ```
    """
    DictShape

    """
    Compact representation of the multi-dimensional array as returned from the transformation.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.Data, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "[[1,2],[3,4]]"
    ```
    """
    Data
end

# This is mostly for convenience to convert the preference to a UInt8.
Base.convert(::Type{UInt8}, preference::MultiDimensionalArrayRepr.T) = Integer(preference)::UInt8
@inline Base.:(==)(a::UInt8, b::MultiDimensionalArrayRepr.T) = a == Integer(b)
@inline Base.:(==)(a::MultiDimensionalArrayRepr.T, b::UInt8) = Integer(a) == b

function Base.convert(::Type{MultiDimensionalArrayRepr.T}, preference::AbstractString)
    if preference == "dict"
        return MultiDimensionalArrayRepr.Dict
    elseif preference == "dict_type_and_shape"
        return MultiDimensionalArrayRepr.DictTypeAndShape
    elseif preference == "dict_shape"
        return MultiDimensionalArrayRepr.DictShape
    elseif preference == "data"
        return MultiDimensionalArrayRepr.Data
    else
        throw(UnsupportedPreferenceError(:mdarray_repr, MultiDimensionalArrayRepr, preference))
    end
end

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
        show_pair(io, JSON.StandardSerialization(), :encoding => __mdarray_data_encoding(mdarray_data))
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
        __show_mdarray_data_array_of_arrays(io, serialization, value)
    elseif mdarray_data == MultiDimensionalArrayData.ReshapeColumnMajor
        __show_mdarray_data_reshape_column_major(io, serialization, value)
    elseif mdarray_data == MultiDimensionalArrayData.ReshapeRowMajor
        __show_mdarray_data_reshape_row_major(io, serialization, value)
    elseif mdarray_data == MultiDimensionalArrayData.Diagonal
        __show_mdarray_data_diagonal(io, serialization, value)
    elseif mdarray_data == MultiDimensionalArrayData.None
        __show_mdarray_data_none(io, serialization, value)
    else
        throw(UnsupportedPreferenceError(:mdarray_data, MultiDimensionalArrayData, mdarray_data))
    end

    if mdarray_repr != MultiDimensionalArrayRepr.Data
        end_object(io)
    end
end

function __mdarray_data_encoding(mdarray_data::UInt8)
    if mdarray_data == MultiDimensionalArrayData.ArrayOfArrays
        return :array_of_arrays
    elseif mdarray_data == MultiDimensionalArrayData.ReshapeColumnMajor
        return :reshape_column_major
    elseif mdarray_data == MultiDimensionalArrayData.ReshapeRowMajor
        return :reshape_row_major
    elseif mdarray_data == MultiDimensionalArrayData.Diagonal
        return :diagonal
    elseif mdarray_data == MultiDimensionalArrayData.None
        return :none
    else
        throw(UnsupportedPreferenceError(:mdarray_data, MultiDimensionalArrayData, mdarray_data))
    end
end

## MultiDimensionalArrayData.ArrayOfArrays implementation
function __show_mdarray_data_array_of_arrays(
    io::StructuralContext, serialization::JSONSerialization, array::AbstractVector
)
    show_json(io, serialization, array)
end
function __show_mdarray_data_array_of_arrays(
    io::StructuralContext, serialization::JSONSerialization, array::AbstractArray
)
    # This function recursively calls itself for each slice of the tensor untill an abstract vector is reached.
    # In this case the function above is called
    begin_array(io)
    foreach(eachslice(array, dims = 1)) do row
        delimit(io)
        indent(io)
        __show_mdarray_data_array_of_arrays(io, serialization, row)
    end
    end_array(io)
end

## MultiDimensionalArrayData.ReshapeColumnMajor implementation
function __show_mdarray_data_reshape_column_major(
    io::StructuralContext, serialization::JSONSerialization, array::AbstractArray
)
    # Julia is already using column-major ordering, so we just need to flatten the array
    begin_array(io)
    foreach(Iterators.flatten(array)) do element
        show_element(io, serialization, element)
    end
    end_array(io)
end

## MultiDimensionalArrayData.ReshapeRowMajor implementation
function __show_mdarray_data_reshape_row_major(
    io::StructuralContext, serialization::JSONSerialization, array::AbstractVector; first = true
)
    foreach(element -> show_element(io, serialization, element), array)
end
function __show_mdarray_data_reshape_row_major(
    io::StructuralContext, serialization::JSONSerialization, array::AbstractArray; first = true
)
    # This function recursively calls itself for each slice of the tensor untill an abstract vector is reached.
    # In this case the function above is called
    first && begin_array(io)
    foreach(eachslice(array, dims = 1)) do row
        __show_mdarray_data_reshape_row_major(io, serialization, row; first = false)
    end
    first && end_array(io)
end

## MultiDimensionalArrayData.Diagonal implementation, only supports Array objects
function __show_mdarray_data_diagonal(
    io::StructuralContext, serialization::JSONSerialization, array::AbstractArray
)
    if firstindex(array) !== 1
        throw(ArgumentError("Diagonal encoding only supports 1-based indexing"))
    end
    begin_array(io)
    k = min(size(array)...)
    l = length(size(array))
    for i in 1:k
        show_element(io, serialization, array[ntuple(_ -> i, l)...])
    end
    end_array(io)
end

## MultiDimensionalArrayData.None implementation
function __show_mdarray_data_none(
    io::StructuralContext, serialization::JSONSerialization, array::AbstractArray
)
    show_json(io, serialization, nothing)
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
  "data"     => Any[Any[1, 2], Any[3, 4]]
  "type"     => "mdarray"
```

Note: No post-processing is performed on the deserialized value.
"""
from_json(string) = JSON.parse(string)

end
