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

This guide covers the `Prefer` header, which is used to indicate the client's preferences for how the server should handle the request.

## Prefer header

The `Prefer` header is a request header that allows clients to specify their preferences for how the server should handle the request. It is a comma-separated list of preference directives. Read more information about the `Prefer` header in the [HTTP specification](https://datatracker.ietf.org/doc/html/rfc7240) and [MDN documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Prefer).

A simple example of the `Prefer` header is:

```
Prefer: key=value
```

You can use several preferences together by separating them with a comma. For example:

```
Prefer: key1=value1,key2=value2
```

!!! warning
    Spaces in the `Prefer` header are not supported. By including a space in the `Prefer` header, the server will not be able to parse the preferences correctly.
    
RxInferServer sets the [`PreferenceApplied`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Preference-Applied) headers for each properly parsed and identified preference to indicate that the preferences have been applied. Unknown preferences are ignored.

## Serialization Preferences 

`RxInferServer` supports preferences for the JSON serialization format. Read more about the `Serialization` module in the [Serialization](@ref serialization) guide. This guide covers which serialization preferences are available through the `Prefer` header and how to set them.

### Multi-dimensional Array Representation Format

Read about the different multi-dimensional array representation formats in the [Multi-dimensional Array Representation Format](@ref serialization-multi-dimensional-array-representation-format) section of the serialization guide.

The `key` for the multi-dimensional array representation format is `mdarray_repr`. The `value` can be one of the following:

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

Read about the different multi-dimensional array data encodings in the [Multi-dimensional Array Data Encoding](@ref serialization-multi-dimensional-array-data-encoding) section of the serialization guide.

The `key` for the multi-dimensional array data encoding is `mdarray_data`. The `value` can be one of the following:

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
