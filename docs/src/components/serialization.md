# [Serialization](@id serialization)

The `Serialization` module provides functionality for serializing Julia objects to JSON format in RxInferServer.jl. It is specifically designed to handle multi-dimensional arrays and ensure compatibility with OpenAPI specifications and:

- Provides type-safe JSON serialization for OpenAPI data types
- Supports customizable multi-dimensional array serialization formats
- Ensures consistent handling of arrays across the server

```@docs
RxInferServer.Serialization.DefaultSerialization
```

By default only OpenAPI-compatible types are serialized, which are described in the [OpenAPI specification](https://swagger.io/docs/specification/v3_0/data-models/data-types/). For other types, the default serialization behavior is to throw an error. The allowed types include:

- `string` (including dates and files)
- `number`
- `integer`
- `boolean`
- `array` (corresponds to `AbstractVector` for Julia)
- `object` (corresponds to `AbstractDict` for Julia)

This poses a problem for serializing multi-dimensional arrays, which are represented as `AbstractArray` types in Julia. The `array` type in OpenAPI is not compatible with multi-dimensional arrays and only explicitly supports one-dimensional arrays (a.k.a. vectors).
This is inconvenient, as the inference procedures may return multi-dimensional arrays for covariance matrices for example and those are not natively supported by OpenAPI specification.

## Serialization of Multi-dimensional Arrays

We could for example try to solve this problem by flattening the multi-dimensional array into a one-dimensional array and adding a shape attribute to the serialized object, for example the following 2x2 matrix:

```@example serialization-problem
A = [1 2; 3 4]
```

would be converted to a dictionary (`object` in the OpenAPI specification) with the following keys:

```@example serialization-problem
encoded_A = Dict(
    "shape" => size(A),
    "data" => collect(Iterators.flatten(A))
)
```

On the receiver side, we could then decode the array using the `reshape` function:

```@example serialization-problem
decoded_A = reshape(encoded_A["data"], encoded_A["shape"]...)
```

It worked! Or did it? This, unfortunately, would not work in other languages. Different programming languages use different conventions for the order of the elements in multi-dimensional arrays. For example, Python's `numpy` reshapes assumes row-major order, while Julia's `reshape` assumes column-major order of the underlying data. If we would attempt to decode the array in Python with the `numpy.reshape` function, we would get an incorrect result with elements `2` and `3` swapped. Notice, for example, that the `data` attribute contains an array of `[ 1, 3, 2, 4 ]` which is not what we intuitively would expect. Intuitively, some might expect the `data` attribute to contain an array of `[ 1, 2, 3, 4 ]`. This discrepancy is the result of the column-major order of the underlying data in Julia. This problem is even more severe non-squared matrices and multi-dimensional tensors.

## Serialization Preferences

To account for the discrepancy between the conventions of different programming languages, `RxInferServer` implements preferences based serialization of complex types, such as multi-dimensional arrays. The serialization behavior can be customized through preferences. Different clients can have different preferences, e.g. a client in Python might prefer row-major order while a client in Julia might prefer column-major order for the multi-dimensional array serialization.

```@docs
RxInferServer.Serialization.to_json
RxInferServer.Serialization.SerializationPreferences
RxInferServer.Serialization.UnsupportedPreferenceError
```

### Multi-dimensional Array Transformation Preferences

```@docs
RxInferServer.Serialization.MultiDimensionalArrayTransform
RxInferServer.Serialization.MultiDimensionalArrayTransform.ArrayOfArrays
```

### Multi-dimensional Array Metadata Preferences

The default serialization strategy for the multidimensional arrays is to convert them to a dictionary with the following keys:

- `type` set to `"mdarray"`
- `encoding` set to chosen transformation of the array, e.g. `"array_of_arrays"`
- `shape` set to the size of the array
- `data` set to the encoded array itself as defined by the transformation

This behavior can be customized through the `MultiDimensionalArrayMetadata` preference. This might be useful to save network bandwidth and/or storage.
For example, if we are sure that the shape of the array is known in advance, we can set the `MultiDimensionalArrayMetadata` to `Compact` to save time needed to encode the shape as well as network bandwidth to transmit it.

```@docs
RxInferServer.Serialization.MultiDimensionalArrayMetadata
RxInferServer.Serialization.MultiDimensionalArrayMetadata.All
RxInferServer.Serialization.MultiDimensionalArrayMetadata.TypeAndShape
RxInferServer.Serialization.MultiDimensionalArrayMetadata.Shape
RxInferServer.Serialization.MultiDimensionalArrayMetadata.Compact
```
