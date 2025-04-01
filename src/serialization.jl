module Serialization

# Preference based serialization of multidimensional arrays, such as matrices and tensors.
# The major problem and potential solution is described here:
# https://github.com/lazydynamics/RxInferServer/issues/59
using EnumX

"""
    MultiDimensionalArrayData

Preference for serializing the underlying data of multi-dimensional arrays.

Possible options are:
- [`RxInferServer.Serialization.MultiDimensionalArrayData.ArrayOfArrays`](@ref)

Also see [`RxInferServer.Serialization.MultiDimensionalArrayRepr`](@ref) for different representations of multi-dimensional arrays.
"""
@enumx MultiDimensionalArrayData::UInt8 begin
    """
    Encodes the data of multi-dimensional arrays as arrays of arrays with row-major ordering.

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
    MultiDimensionalArrayRepr

Preference for the representation of multi-dimensional arrays during the serialization.
Choosing different options might be beneficial to save network bandwidth and/or storage.

Possible options are:
- [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref)
- [`RxInferServer.Serialization.MultiDimensionalArrayRepr.DictTypeAndShape`](@ref)
- [`RxInferServer.Serialization.MultiDimensionalArrayRepr.DictShape`](@ref)
- [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Data`](@ref)

See [`RxInferServer.Serialization.MultiDimensionalArrayData`](@ref) for more details about the serialization of the underlying data.
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

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictAll, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

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
    "{\\"type\\":\\"mdarray\\",\\"shape\\":[2,2]}"
    """
    DictTypeAndShape

    """
    Same as [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref), but excludes the `encoding` and `type` keys, leaving only the `shape` and `data` keys.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictShape, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "{\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    """
    DictShape

    """
    Compact representation of the multi-dimensional array as returned from the transformation.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

    julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.Data, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

    julia> to_json(s, [1 2; 3 4])
    "[[1,3],[2,4]]"
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
using JSON

import JSON.Writer: StructuralContext, begin_object, end_object, show_pair, show_key, show_json

"""
    JSONSerialization(; preferences::SerializationPreferences)

Default serialization of Julia objects to JSON used by RxInferServer, which natively supports OpenAPI data-types.
Provides additional preferences for serializing objects that are not natively supported by OpenAPI specification.

The following preferences are supported:
- `mdarray_repr`: Preference for multidimensional arrays representation in the serialization of multi-dimensional arrays. See [`RxInferServer.Serialization.MultiDimensionalArrayTransform`](@ref) for more details.
- `mdarray_data`: Preference for serialization of multidimensional arrays data. See [`RxInferServer.Serialization.MultiDimensionalArrayTransform`](@ref) for more details.
"""
Base.@kwdef struct JSONSerialization <: JSON.Serializations.Serialization
    mdarray_repr::UInt8 = MultiDimensionalArrayRepr.All
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
show_json(io::StructuralContext, ::JSONSerialization, value::AbstractVector) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::JSONSerialization, value::AbstractDict) =
    show_json(io, JSON.StandardSerialization(), value)

# Multi-dimensional arrays, preference based serialization

function show_json(io::StructuralContext, serialization::JSONSerialization, value::AbstractArray)
    mdarray_data = serialization.mdarray_data
    mdarray_repr = serialization.mdarray_repr

    if mdarray_repr != MultiDimensionalArrayMetadata.Compact
        begin_object(io)
    end

    if mdarray_repr == MultiDimensionalArrayMetadata.All
        show_pair(io, JSON.StandardSerialization(), :type => :mdarray)
        show_pair(io, JSON.StandardSerialization(), :encoding => :array_of_arrays)
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif mdarray_repr == MultiDimensionalArrayMetadata.TypeAndShape
        show_pair(io, JSON.StandardSerialization(), :type => :mdarray)
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif mdarray_repr == MultiDimensionalArrayMetadata.Shape
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif mdarray_repr == MultiDimensionalArrayMetadata.Compact
        # noop
    else
        throw(UnsupportedPreferenceError(:mdarray_repr, MultiDimensionalArrayMetadata, mdarray_repr))
    end

    if mdarray_data == MultiDimensionalArrayTransform.ArrayOfArrays
        show_json(io, JSON.StandardSerialization(), value)
    else
        throw(UnsupportedPreferenceError(:mdarray_transform, MultiDimensionalArrayTransform, mdarray_data))
    end

    if mdarray_repr != MultiDimensionalArrayMetadata.Compact
        end_object(io)
    end
end

"""
    to_json([io::IO], [preferences::SerializationPreferences], value)

Serialize a `value` to `io` as a JSON string using the given `preferences`.
The `io` argument is optional, returns a string if not provided.
The `preferences` argument is optional, defaults to `SerializationPreferences()`.

See [`RxInferServer.Serialization.SerializationPreferences`](@ref) for more details about the preferences.
"""
function to_json end

to_json(io::IO, value) = to_json(io, JSONSerialization(), value)
to_json(s::JSONSerialization, value) = sprint(show_json, s, value)

from_json(string) = JSON.parse(string)

end