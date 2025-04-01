module Serialization

# Preference based serialization of multidimensional arrays, such as matrices and tensors.
# The major problem and potential solution is described here:
# https://github.com/lazydynamics/RxInferServer/issues/59
using EnumX

"""
    MultiDimensionalArrayTransform

Preference for serializing multi-dimensional arrays as arrays of arrays.

Possible options are:
- [`RxInferServer.Serialization.MultiDimensionalArrayTransform.ArrayOfArrays`](@ref)

The serialized objects include metadata information by default. 
See [`RxInferServer.Serialization.MultiDimensionalArrayMetadata`](@ref) for more details.
"""
@enumx MultiDimensionalArrayTransform::UInt8 begin
    """
    Encodes multi-dimensional arrays as arrays of arrays with row-major ordering and metadata information.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayTransform, SerializationPreferences, to_json

    julia> p = SerializationPreferences(mdarray_transform=MultiDimensionalArrayTransform.ArrayOfArrays);

    julia> to_json(p, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"

    julia> to_json(p, [1 3; 2 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"
    ```

    !!! note
        Julia uses column-major ordering for multi-dimensional arrays, but this preference uses row-major ordering.
    """
    ArrayOfArrays
end

# This is mostly for convenience to convert the preference to a UInt8.
Base.convert(::Type{UInt8}, preference::MultiDimensionalArrayTransform.T) = Integer(preference)::UInt8
@inline Base.:(==)(a::UInt8, b::MultiDimensionalArrayTransform.T) = a == Integer(b)
@inline Base.:(==)(a::MultiDimensionalArrayTransform.T, b::UInt8) = Integer(a) == b

"""
    MultiDimensionalArrayMetadata

Preference for including metadata in the serialization of multi-dimensional arrays.
Choosing different options might be beneficial to save network bandwidth and/or storage.

Possible options are:
- [`RxInferServer.Serialization.MultiDimensionalArrayMetadata.All`](@ref)
- [`RxInferServer.Serialization.MultiDimensionalArrayMetadata.TypeAndShape`](@ref)
- [`RxInferServer.Serialization.MultiDimensionalArrayMetadata.Shape`](@ref)
- [`RxInferServer.Serialization.MultiDimensionalArrayMetadata.Compact`](@ref)

See [`RxInferServer.Serialization.MultiDimensionalArrayTransform`](@ref) for more details about the serialization transformation preferences.
"""
@enumx MultiDimensionalArrayMetadata::UInt8 begin
    """
    Include all metadata for multi-dimensional arrays, which includes:
    - `type` set to `"mdarray"`
    - `encoding` set to to a selected transformation of the array, e.g. `"array_of_arrays"`
    - `shape` set to the size of the array
    - `data` set to the encoded array itself as defined by the transformation

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayTransform, MultiDimensionalArrayMetadata, SerializationPreferences, to_json

    julia> p = SerializationPreferences(mdarray_transform=MultiDimensionalArrayTransform.ArrayOfArrays, mdarray_metadata=MultiDimensionalArrayMetadata.All);

    julia> to_json(p, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"array_of_arrays\\",\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    ```
    """
    All

    """
    Include `type`, `shape` and `data` in the metadata. `type` is always set to `"mdarray"`.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayTransform, MultiDimensionalArrayMetadata, SerializationPreferences, to_json

    julia> p = SerializationPreferences(mdarray_transform=MultiDimensionalArrayTransform.ArrayOfArrays, mdarray_metadata=MultiDimensionalArrayMetadata.TypeAndShape);

    julia> to_json(p, [1 2; 3 4])
    "{\\"type\\":\\"mdarray\\",\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    """
    TypeAndShape

    """
    Include only the `shape` and `data` of the multi-dimensional array in the metadata.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayTransform, MultiDimensionalArrayMetadata, SerializationPreferences, to_json

    julia> p = SerializationPreferences(mdarray_transform=MultiDimensionalArrayTransform.ArrayOfArrays, mdarray_metadata=MultiDimensionalArrayMetadata.Shape);

    julia> to_json(p, [1 2; 3 4])
    "{\\"shape\\":[2,2],\\"data\\":[[1,3],[2,4]]}"
    """
    Shape

    """
    Returns the compact representation of the multi-dimensional array as returned from the transformation.

    ```jldoctest
    julia> import RxInferServer.Serialization: MultiDimensionalArrayTransform, MultiDimensionalArrayMetadata, SerializationPreferences, to_json

    julia> p = SerializationPreferences(mdarray_transform=MultiDimensionalArrayTransform.ArrayOfArrays, mdarray_metadata=MultiDimensionalArrayMetadata.Compact);

    julia> to_json(p, [1 2; 3 4])
    "[[1,3],[2,4]]"
    """
    Compact
end

# This is mostly for convenience to convert the preference to a UInt8.
Base.convert(::Type{UInt8}, preference::MultiDimensionalArrayMetadata.T) = Integer(preference)::UInt8
@inline Base.:(==)(a::UInt8, b::MultiDimensionalArrayMetadata.T) = a == Integer(b)
@inline Base.:(==)(a::MultiDimensionalArrayMetadata.T, b::UInt8) = Integer(a) == b

"""
    SerializationPreferences

Preferences for serializing objects that are not natively supported by OpenAPI specification.

The following preferences are supported:
- `mdarray_transform`: Preference for serializing multi-dimensional arrays, such as matrices and tensors. See [`RxInferServer.Serialization.MultiDimensionalArrayTransform`](@ref) for more details.
- `mdarray_metadata`: Preference for including metadata in the serialization of multi-dimensional arrays. See [`RxInferServer.Serialization.MultiDimensionalArrayMetadata`](@ref) for more details.

See also [`RxInferServer.Serialization.to_json`](@ref).
"""
Base.@kwdef struct SerializationPreferences
    mdarray_transform::UInt8 = MultiDimensionalArrayTransform.ArrayOfArrays
    mdarray_metadata::UInt8 = MultiDimensionalArrayMetadata.All
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
using JSON

import JSON.Writer: StructuralContext, begin_object, end_object, show_pair, show_key, show_json

"""
    DefaultSerialization(; preferences::SerializationPreferences)

Default serialization of Julia objects to JSON used by RxInferServer.
The main reason for using a custom serialization instead of built-in from `JSON` is that
- Only support OpenAPI data-types and explicitly exclude all other types.
- Additional support for preference based serialization of multidimensional arrays and distributions.
See [`RxInferServer.Serialization.SerializationPreferences`](@ref) for more details about different preferences.
"""
Base.@kwdef struct DefaultSerialization <: JSON.Serializations.Serialization
    preferences::SerializationPreferences = SerializationPreferences()
end

struct UnsupportedTypeSerializationError <: Exception
    type::Type
end

function Base.showerror(io::IO, e::UnsupportedTypeSerializationError)
    print(io, "serialization of type $(e.type) is not supported")
end

function show_json(::StructuralContext, ::DefaultSerialization, value)
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
show_json(io::StructuralContext, ::DefaultSerialization, value::String) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::DefaultSerialization, value::Number) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::DefaultSerialization, value::Bool) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::DefaultSerialization, value::AbstractVector) =
    show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::DefaultSerialization, value::AbstractDict) =
    show_json(io, JSON.StandardSerialization(), value)

# Multi-dimensional arrays, preference based serialization

function show_json(io::StructuralContext, serialization::DefaultSerialization, value::AbstractArray)
    preference = serialization.preferences.mdarray_transform
    metadata = serialization.preferences.mdarray_metadata

    if metadata != MultiDimensionalArrayMetadata.Compact
        begin_object(io)
    end

    if metadata == MultiDimensionalArrayMetadata.All
        show_pair(io, JSON.StandardSerialization(), :type => :mdarray)
        show_pair(io, JSON.StandardSerialization(), :encoding => :array_of_arrays)
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif metadata == MultiDimensionalArrayMetadata.TypeAndShape
        show_pair(io, JSON.StandardSerialization(), :type => :mdarray)
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    elseif metadata == MultiDimensionalArrayMetadata.Shape
        show_pair(io, JSON.StandardSerialization(), :shape => size(value))
        show_key(io, :data)
    end

    if preference == MultiDimensionalArrayTransform.ArrayOfArrays
        show_json(io, JSON.StandardSerialization(), value)
    else
        throw(UnsupportedPreferenceError(:mdarray_transform, MultiDimensionalArrayTransform, preference))
    end

    if metadata != MultiDimensionalArrayMetadata.Compact
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

to_json(io::IO, preferences::SerializationPreferences, value) = show_json(io, DefaultSerialization(preferences), value)
to_json(io::IO, value) = to_json(io, SerializationPreferences(), value)

to_json(value) = sprint(to_json, value)
to_json(preferences::SerializationPreferences, value) = sprint(to_json, preferences, value)

from_json(string) = JSON.parse(string)

end