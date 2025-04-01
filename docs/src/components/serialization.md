# [Serialization](@id serialization)

The `Serialization` module provides functionality for serializing Julia objects to JSON format in RxInferServer.jl. It is specifically designed to handle multi-dimensional arrays and ensure compatibility with OpenAPI specifications and:

- Provides type-safe JSON serialization for OpenAPI data types
- Supports customizable multi-dimensional array serialization formats
- Ensures consistent handling of arrays across the server

```@docs
RxInferServer.Serialization.JSONSerialization
```

## Supported Types

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

### Multi-dimensional Array Representation Preferences

To account for the discrepancy between the conventions of different programming languages with regards to the representation of multi-dimensional arrays, `RxInferServer` implements preferences based serialization of multi-dimensional arrays. The serialization behavior can be customized through preferences in the [`RxInferServer.Serialization.JSONSerialization`](@ref) constructor. For example, a Python SDK might prefer row-major order while a Julia SDK might prefer column-major order for the multi-dimensional array serialization. 

The serialization behavior for multi-dimensional arrays can be customized through two settings:

- `mdarray_repr`: Specifies the representation of the multi-dimensional array.
- `mdarray_data`: Specifies the encoding of the multi-dimensional array data.

#### Multi-dimensional Array Representation Preferences

```@docs
RxInferServer.Serialization.MultiDimensionalArrayRepr
RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict
RxInferServer.Serialization.MultiDimensionalArrayRepr.DictTypeAndShape
RxInferServer.Serialization.MultiDimensionalArrayRepr.DictShape
RxInferServer.Serialization.MultiDimensionalArrayRepr.Data
```

#### Encoding of Multi-dimensional Array Data

```@docs
RxInferServer.Serialization.MultiDimensionalArrayData
RxInferServer.Serialization.MultiDimensionalArrayData.ArrayOfArrays
```

## API Reference

```@docs
RxInferServer.Serialization.to_json
RxInferServer.Serialization.from_json
RxInferServer.Serialization.UnsupportedPreferenceError
```
