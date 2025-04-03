# [Request preferences](@id request-preferences-api)

```@setup preferences
using Test

import RxInferServer
import RxInferClientOpenAPI.OpenAPI.Clients: Client, set_header
import RxInferClientOpenAPI: ModelsApi, basepath, CreateModelInstanceRequest, create_model_instance, get_model_instance_state

client = Client(basepath(ModelsApi); headers = Dict(
    "Authorization" => "Bearer $(RxInferServer.DEFAULT_DEV_TOKEN):test-only"
))

api = ModelsApi(client)

create_model_instance_request = CreateModelInstanceRequest(
    model_name = "TestModelComplexState",
    description = "Testing complex state",
    arguments = Dict("size" => 2)
)

created, info = create_model_instance(api, create_model_instance_request)
@test info.status == 200
instance_id = created.instance_id

function hidden_get_matrix()
    local r, info = get_model_instance_state(api, instance_id)
    @test info.status == 200
    return r.state["matrix"], info
end
```

This guide explores how to customize server responses using the `Prefer` header, a powerful HTTP mechanism that lets you control how the server processes and formats your requests.

## Prefer header

The `Prefer` header is a standardized HTTP header that enables clients to express their preferences for request handling. It follows a simple key-value format and can include multiple preferences separated by commas. For more details, refer to the [HTTP specification](https://datatracker.ietf.org/doc/html/rfc7240) and [MDN documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Prefer).

Basic syntax:
```
Prefer: key=value
```

Multiple preferences:
```
Prefer: key1=value1,key2=value2
```

!!! warning
    Spaces in the `Prefer` header are not supported. Including spaces will prevent the server from correctly parsing your preferences.
    
RxInferServer acknowledges applied preferences by setting the [`PreferenceApplied`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Preference-Applied) headers. Any unrecognized preferences are safely ignored.

## Serialization Preferences 

RxInferServer offers flexible JSON serialization options through the `Prefer` header. These options allow you to control how your data is formatted in responses. For a comprehensive overview of serialization capabilities, see the [Serialization](@ref serialization) guide.

### Multi-dimensional Array Representation Format

The `mdarray_repr` preference controls how multi-dimensional arrays are structured in the response. This is particularly useful when working with matrices and tensors. For detailed information about available formats, see the [Multi-dimensional Array Representation Format](@ref serialization-multi-dimensional-array-representation-format) section.

Available options for `mdarray_repr`:

| Value | Corresponds to |
| --- | --- |
| `dict` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref) |
| `dict_type_and_shape` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.DictTypeAndShape`](@ref) |
| `dict_shape` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.DictShape`](@ref) |
| `data` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Data`](@ref) |

#### Examples 

Here, how, as an example, a simple 2x2 matrix would change its representation depending on different preferences:

```@example preferences
A = [1 2; 3 4]
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=dict")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=dict_type_and_shape")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=dict_shape")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=data")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

### Multi-dimensional Array Data Encoding

The `mdarray_data` preference determines how array data is encoded in the response. This is crucial for optimizing data transfer and ensuring compatibility with different client implementations. For more details, see the [Multi-dimensional Array Data Encoding](@ref serialization-multi-dimensional-array-data-encoding) section.

Available options for `mdarray_data`:

| Value | Description |
|-------|-------------|
| `array_of_arrays` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.ArrayOfArrays`](@ref). |
| `reshape_column_major` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.ReshapeColumnMajor`](@ref). |
| `reshape_row_major` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.ReshapeRowMajor`](@ref). |
| `diagonal` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.Diagonal`](@ref). |
| `none` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.None`](@ref). |

#### Examples 

Here, how, as an example, a simple 2x2 matrix would change its representation depending on different preferences:

```@example preferences
A = [1 2; 3 4]
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=array_of_arrays")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences 
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=reshape_column_major")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=reshape_row_major")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=diagonal")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=none")
A, info = hidden_get_matrix() #hide
nothing #hide
```

It is possible to remove the matrices from the request entirely by setting the `mdarray_data` preference to `none` together with the `mdarray_repr` preference to `data`.

```@example preferences
set_header(client, "Prefer", "mdarray_repr=data,mdarray_data=none")
A, info = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

## API Reference

```@docs
RxInferServer.RequestPreferences
```
