# Preference based serialization of multidimensional arrays, such as matrices and tensors.
# The major problem and potential solution is described here:
# https://github.com/lazydynamics/RxInferServer/issues/59

"""
A module that specifies the encoding format for multi-dimensional array data.
Is supposed to be used as a namespace for the `MultiDimensionalArrayData` enum.

See also: [`RxInferServer.Serialization.MultiDimensionalArrayRepr`](@ref)
"""
module MultiDimensionalArrayData
"""
Unknown encoding format. Used to indicate that the encoding format is not known or cannot be parsed from the request.
"""
const Unknown::UInt8 = 0x00

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
const ArrayOfArrays::UInt8 = 0x01

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
const ReshapeColumnMajor::UInt8 = 0x02

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
const ReshapeRowMajor::UInt8 = 0x03

"""
Encodes the data of multi-dimensional arrays as a single array containing only the diagonal elements of the parent array.

```jldoctest
julia> import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization, to_json

julia> s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.Diagonal);

julia> to_json(s, [1 2; 3 4])
"{\\"type\\":\\"mdarray\\",\\"encoding\\":\\"diagonal\\",\\"shape\\":[2,2],\\"data\\":[1,4]}"
```
"""
const Diagonal::UInt8 = 0x04

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
const None::UInt8 = 0x05

const OptionName = "mdarray_data"
const AvailableOptions = (ArrayOfArrays, ReshapeColumnMajor, ReshapeRowMajor, Diagonal, None)

function to_string(preference::UInt8)
    if preference == MultiDimensionalArrayData.ArrayOfArrays
        return "array_of_arrays"
    elseif preference == MultiDimensionalArrayData.ReshapeColumnMajor
        return "reshape_column_major"
    elseif preference == MultiDimensionalArrayData.ReshapeRowMajor
        return "reshape_row_major"
    elseif preference == MultiDimensionalArrayData.Diagonal
        return "diagonal"
    elseif preference == MultiDimensionalArrayData.None
        return "none"
    else
        return "unknown"
    end
end

function from_string(preference::AbstractString)
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
        return MultiDimensionalArrayData.Unknown
    end
end
end

"""
Specifies the JSON representation format for multi-dimensional arrays.
Is supposed to be used as a namespace for the `MultiDimensionalArrayRepr` enum.

See also: [`RxInferServer.Serialization.MultiDimensionalArrayData`](@ref)
"""
module MultiDimensionalArrayRepr
"""
Unknown representation format. Used to indicate that the representation format is not known or cannot be parsed from the request.
"""
const Unknown::UInt8 = 0x00

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
const Dict::UInt8 = 0x01

"""
Same as [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref), but excludes the `encoding` key, leaving only the `type`, `shape` and `data` keys.

```jldoctest
julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictTypeAndShape, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

julia> to_json(s, [1 2; 3 4])
"{\\"type\\":\\"mdarray\\",\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"
```
"""
const DictTypeAndShape::UInt8 = 0x02

"""
Same as [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref), but excludes the `encoding` and `type` keys, leaving only the `shape` and `data` keys.

```jldoctest
julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.DictShape, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

julia> to_json(s, [1 2; 3 4])
"{\\"shape\\":[2,2],\\"data\\":[[1,2],[3,4]]}"
```
"""
const DictShape::UInt8 = 0x03

"""
Compact representation of the multi-dimensional array as returned from the transformation.

```jldoctest
julia> import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization, to_json

julia> s = JSONSerialization(mdarray_repr = MultiDimensionalArrayRepr.Data, mdarray_data = MultiDimensionalArrayData.ArrayOfArrays);

julia> to_json(s, [1 2; 3 4])
"[[1,2],[3,4]]"
```
"""
const Data::UInt8 = 0x04

const OptionName = "mdarray_repr"
const AvailableOptions = (Dict, DictTypeAndShape, DictShape, Data)

function to_string(preference::UInt8)
    if preference == MultiDimensionalArrayRepr.Dict
        return "dict"
    elseif preference == MultiDimensionalArrayRepr.DictTypeAndShape
        return "dict_type_and_shape"
    elseif preference == MultiDimensionalArrayRepr.DictShape
        return "dict_shape"
    elseif preference == MultiDimensionalArrayRepr.Data
        return "data"
    else
        return "unknown"
    end
end

function from_string(preference::AbstractString)
    if preference == "dict"
        return MultiDimensionalArrayRepr.Dict
    elseif preference == "dict_type_and_shape"
        return MultiDimensionalArrayRepr.DictTypeAndShape
    elseif preference == "dict_shape"
        return MultiDimensionalArrayRepr.DictShape
    elseif preference == "data"
        return MultiDimensionalArrayRepr.Data
    else
        return MultiDimensionalArrayRepr.Unknown
    end
end
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
        show_pair(io, JSON.StandardSerialization(), :encoding => MultiDimensionalArrayData.to_string(mdarray_data))
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
        throw(UnsupportedPreferenceError(mdarray_repr, MultiDimensionalArrayRepr))
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
        throw(UnsupportedPreferenceError(mdarray_data, MultiDimensionalArrayData))
    end

    if mdarray_repr != MultiDimensionalArrayRepr.Data
        end_object(io)
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
function __show_mdarray_data_diagonal(io::StructuralContext, serialization::JSONSerialization, array::AbstractArray)
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
function __show_mdarray_data_none(io::StructuralContext, serialization::JSONSerialization, array::AbstractArray)
    show_json(io, serialization, nothing)
end
