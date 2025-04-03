# [Serialization](@id serialization)

The `Serialization` module provides type-safe JSON serialization for OpenAPI data types in RxInferServer.jl, with special focus on handling multi-dimensional arrays.

```@docs
RxInferServer.Serialization.JSONSerialization
```

## Supported Types

The serialization supports standard OpenAPI data types as defined in the [OpenAPI specification](https://swagger.io/docs/specification/v3_0/data-models/data-types/):

- `string` (including dates and files)
- `number`
- `integer`
- `boolean`
- `array` (corresponds to `AbstractVector` for Julia)
- `object` (corresponds to `AbstractDict` for Julia)

## Multi-dimensional Array Serialization

OpenAPI specification does not natively support multi-dimensional arrays. To handle this limitation while ensuring compatibility across different programming languages (which may use different array layouts), RxInferServer implements a customizable serialization strategy through two key preferences:

1. Array representation format ([`RxInferServer.Serialization.MultiDimensionalArrayRepr`](@ref))
2. Array data encoding ([`RxInferServer.Serialization.MultiDimensionalArrayData`](@ref))

### Example: Matrix Serialization Challenge

Consider serializing a 2x2 matrix:

```@example serialization-problem
A = [1 2; 3 4]
```

A naive approach might serialize this as:

```@example serialization-problem
encoded_A = Dict(
    "shape" => size(A),
    "data" => collect(Iterators.flatten(A))
)
```

While this works fine in Julia:

```@example serialization-problem
decoded_A = reshape(encoded_A["data"], encoded_A["shape"]...)
```

It, however, does not work in python:

```python
>>> import numpy as np

>>> np.reshape([ 1, 3, 2, 4 ], shape = (2, 2))
array([[1, 3],
       [2, 4]])
```

You can see that the data is not correctly reshaped in python. Elements `2` and `3` are swapped. If we would send this data to a python SDK client, the data would be incorrect. This is due to the different array layout conventions (row-major in Python/NumPy vs column-major in Julia). RxInferServer does not assume a particular layout for multi-dimensional arrays, so it leaves it to the user to configure the serialization preferences. 

### Serialization Preferences

RxInferServer provides two key preferences to control how multi-dimensional arrays are serialized:

1. **Array Data Encoding** ([`RxInferServer.Serialization.MultiDimensionalArrayData`](@ref)): Determines how the array data itself is transformed for serialization. For example, the `ArrayOfArrays` option encodes multi-dimensional arrays as nested arrays with row-major ordering to ensure cross-language compatibility.

2. **Array Representation Format** ([`RxInferServer.Serialization.MultiDimensionalArrayRepr`](@ref)): Controls the structure of the serialized output, offering several options ranging from a fully-specified dictionary with type, encoding, shape, and data fields to a minimal representation with just the data itself.

These preferences can be configured when creating a [`RxInferServer.Serialization.JSONSerialization`](@ref) instance, allowing you to balance between explicit metadata and compact representation based on your specific needs.

#### [Multi-dimensional Array Representation Format](@id serialization-multi-dimensional-array-representation-format)

```@docs
RxInferServer.Serialization.MultiDimensionalArrayRepr
RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict
RxInferServer.Serialization.MultiDimensionalArrayRepr.DictTypeAndShape
RxInferServer.Serialization.MultiDimensionalArrayRepr.DictShape
RxInferServer.Serialization.MultiDimensionalArrayRepr.Data
```

#### [Multi-dimensional Array Data Encoding](@id serialization-multi-dimensional-array-data-encoding)

```@docs 
RxInferServer.Serialization.MultiDimensionalArrayData
RxInferServer.Serialization.MultiDimensionalArrayData.ArrayOfArrays
RxInferServer.Serialization.MultiDimensionalArrayData.ReshapeColumnMajor
RxInferServer.Serialization.MultiDimensionalArrayData.ReshapeRowMajor
```

## API Reference

```@docs
RxInferServer.Serialization.to_json
RxInferServer.Serialization.from_json
RxInferServer.Serialization.UnsupportedPreferenceError
```
