module Serialization

# Preference based serialization of multidimensional arrays, such as matrices and tensors.
# The major problem and potential solution is described here:
# https://github.com/lazydynamics/RxInferServer/issues/59
using EnumX

"""
    MultiDimensionalArrayTransformPreference

Preference for serializing multi-dimensional arrays as arrays of arrays.
Possible options are:
- [`MultiDimensionalArrayTransformPreference.ArrayOfArrays`](@ref)
See documentation for each option individually for more details.
"""
@enumx MultiDimensionalArrayTransformPreference::UInt8 begin
    """
    This is the default behaviour of most JSON serializers. 
    Encodes multi-dimensional arrays as arrays of arrays with row-major ordering.
    For example, a 2x2 matrix [ 1 2; 3 4 ] will be encoded as `[[1, 2], [3, 4]]`.
    """
    ArrayOfArrays
end

# This is mostly for convenience to convert the preference to a UInt8.
Base.convert(::Type{UInt8}, preference::MultiDimensionalArrayTransformPreference.T) = Integer(preference)::UInt8
@inline Base.:(==)(a::UInt8, b::MultiDimensionalArrayTransformPreference.T) = a == Integer(b)
@inline Base.:(==)(a::MultiDimensionalArrayTransformPreference.T, b::UInt8) = Integer(a) == b

"""
    SerializationPreferences

Preferences for serializing objects that are not natively supported by OpenAPI specification.

The following preferences are supported:
- `mdarray_transform`: Preference for serializing multi-dimensional arrays, such as matrices and tensors. See [`RxInferServer.Serialization.MultiDimensionalArrayTransformPreference`](@ref) for more details.
"""
Base.@kwdef struct SerializationPreferences
    mdarray_transform::UInt8 = MultiDimensionalArrayTransformPreference.ArrayOfArrays
end

"""
    UnsupportedPreferenceError{A, P}

Error thrown when an unknown preference value is used.

# Arguments
- `scope::Symbol`: The scope of the preference.
- `available::A`: The available preferences.
- `preference::P`: The unknown preference value.
"""
struct UnsupportedPreferenceError{A, P} <: Exception
    scope::Symbol
    available::A
    preference::P
end

function Base.showerror(io::IO, e::UnsupportedPreferenceError)
    print(io, "unknown preference value `$(e.preference)` for `$(e.scope)`. Available preferences are:")
    for preference in instances(e.available.T)
        print(io, " ", preference, "=", Integer(preference))
    end
end

# Using `JSON` instead for `to_json` of `JSON3` here is intentional.
# `JSON3` does not support custom serializers, and `JSON` does.
using JSON

import JSON.Writer: begin_object, end_object, show_pair, show_json

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

function show_json(io::IO, ::DefaultSerialization, value)
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
show_json(io::IO, ::DefaultSerialization, value::String) = show_json(io, JSON.StandardSerialization(), value)
show_json(io::IO, ::DefaultSerialization, value::Number) = show_json(io, JSON.StandardSerialization(), value)
show_json(io::IO, ::DefaultSerialization, value::Bool) = show_json(io, JSON.StandardSerialization(), value)
show_json(io::IO, ::DefaultSerialization, value::AbstractVector) = show_json(io, JSON.StandardSerialization(), value)
show_json(io::IO, ::DefaultSerialization, value::AbstractDict) = show_json(io, JSON.StandardSerialization(), value)

# Multi-dimensional arrays, preference based serialization

function show_json(io::IO, serialization::DefaultSerialization, value::AbstractArray)
    preference = serialization.preferences.mdarray_transform
    if preference == MultiDimensionalArrayTransformPreference.ArrayOfArrays
        show_json(io, JSON.StandardSerialization(), value)
    else
        throw(UnsupportedPreferenceError(:mdarray_transform, MultiDimensionalArrayTransformPreference, preference))
    end
end

to_json(io::IO, preferences::SerializationPreferences, value) = show_json(io, DefaultSerialization(preferences), value)
to_json(io::IO, value) = to_json(io, SerializationPreferences(), value)

to_json(value) = sprint(to_json, value)
to_json(preferences::SerializationPreferences, value) = sprint(to_json, preferences, value)

from_json(string) = JSON.parse(string)

end