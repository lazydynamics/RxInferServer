# [Request preferences](@id request-preferences-api)

```@setup preferences
using Test, HTTP, JSON
using RxInfer

import RxInferServer
import RxInferClientOpenAPI.OpenAPI.Clients: Client, set_header
import RxInferClientOpenAPI: ModelsApi, basepath, CreateModelInstanceRequest, create_model_instance, get_model_instance_state

client = Client(basepath(ModelsApi); headers = Dict(
    "Authorization" => "Bearer $(RxInferServer.DEFAULT_DEV_TOKEN):test-only"
))

function hidden_get_matrix()
    m = Dict("matrix" => [1 2; 3 4])
    req = HTTP.Request("POST", "test", HTTP.Headers(["Prefer" => client.headers["Prefer"]]))
    response = RxInferServer.postprocess_response(req, m["matrix"])
    return JSON.parse(String(response.body))
end

function hidden_get_univariate_distribution()
    d = Dict("distribution" => NormalMeanVariance(1.0, 2.0))
    req = HTTP.Request("POST", "test", HTTP.Headers(["Prefer" => client.headers["Prefer"]]))
    response = RxInferServer.postprocess_response(req, d["distribution"])
    return JSON.parse(String(response.body))
end

function hidden_get_multivariate_distribution()
    d = Dict("distribution" => MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0]))
    req = HTTP.Request("POST", "test", HTTP.Headers(["Prefer" => client.headers["Prefer"]]))
    response = RxInferServer.postprocess_response(req, d["distribution"])
    return JSON.parse(String(response.body))
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

## Multi-dimensional Array Representation Format

The `mdarray_repr` preference controls how multi-dimensional arrays are structured in the response. This is particularly useful when working with matrices and tensors. For detailed information about available formats, see the [Multi-dimensional Array Representation Format](@ref serialization-multi-dimensional-array-representation-format) section.

Available options for `mdarray_repr`:

| Value | Corresponds to |
| --- | --- |
| `dict` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Dict`](@ref) |
| `dict_type_and_shape` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.DictTypeAndShape`](@ref) |
| `dict_shape` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.DictShape`](@ref) |
| `data` | [`RxInferServer.Serialization.MultiDimensionalArrayRepr.Data`](@ref) |

### Examples 

Here, how, as an example, a simple 2x2 matrix would change its representation depending on different preferences:

```@example preferences
A = [1 2; 3 4]
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=dict")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=dict_type_and_shape")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=dict_shape")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_repr=data")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

## Multi-dimensional Array Data Encoding

The `mdarray_data` preference determines how array data is encoded in the response. This is crucial for optimizing data transfer and ensuring compatibility with different client implementations. For more details, see the [Multi-dimensional Array Data Encoding](@ref serialization-multi-dimensional-array-data-encoding) section.

Available options for `mdarray_data`:

| Value | Description |
|-------|-------------|
| `array_of_arrays` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.ArrayOfArrays`](@ref). |
| `reshape_column_major` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.ReshapeColumnMajor`](@ref). |
| `reshape_row_major` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.ReshapeRowMajor`](@ref). |
| `diagonal` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.Diagonal`](@ref). |
| `none` | Corresponds to [`RxInferServer.Serialization.MultiDimensionalArrayData.None`](@ref). |

### Examples 

Here, how, as an example, a simple 2x2 matrix would change its representation depending on different preferences:

```@example preferences
A = [1 2; 3 4]
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=array_of_arrays")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences 
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=reshape_column_major")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=reshape_row_major")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=diagonal")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

```@example preferences
set_header(client, "Prefer", "mdarray_data=none")
A = hidden_get_matrix() #hide
nothing #hide
```

It is possible to remove the matrices from the request entirely by setting the `mdarray_data` preference to `none` together with the `mdarray_repr` preference to `data`.

```@example preferences
set_header(client, "Prefer", "mdarray_repr=data,mdarray_data=none")
A = hidden_get_matrix() #hide
nothing #hide
```

```@example preferences
A
```

## Distribution Representation Format

The `distributions_repr` preference controls how probability distributions are structured in the response. This is particularly useful when working with statistical models. For detailed information about available formats, see the [Distribution Representation Format](@ref serialization-distribution-representation-format) section.

Available options for `distributions_repr`:

| Value | Corresponds to |
| --- | --- |
| `dict` | [`RxInferServer.Serialization.DistributionsRepr.Dict`](@ref) |
| `dict_type_and_tag` | [`RxInferServer.Serialization.DistributionsRepr.DictTypeAndTag`](@ref) |
| `dict_tag` | [`RxInferServer.Serialization.DistributionsRepr.DictTag`](@ref) |
| `data` | [`RxInferServer.Serialization.DistributionsRepr.Data`](@ref) |

### Examples 

Here's how a normal distribution would change its representation depending on different preferences. We will show both the univariate and multivariate cases.

```@example preferences
univariate_distribution = NormalMeanVariance(1.0, 2.0)
```

```@example preferences
multivariate_distribution = MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0])
```

```@example preferences
set_header(client, "Prefer", "distributions_repr=dict")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

```@example preferences
set_header(client, "Prefer", "distributions_repr=dict_type_and_tag")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

```@example preferences
set_header(client, "Prefer", "distributions_repr=dict_tag")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

```@example preferences
set_header(client, "Prefer", "distributions_repr=data")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

## Distribution Data Encoding

The `distributions_data` preference determines how distribution parameters are encoded in the response. This is crucial for ensuring compatibility with different client implementations and providing consistent parameterization. For more details, see the [Distribution Data Encoding](@ref serialization-distribution-data-encoding) section.

Available options for `distributions_data`:

| Value | Description |
|-------|-------------|
| `named_params` | Corresponds to [`RxInferServer.Serialization.DistributionsData.NamedParams`](@ref). |
| `params` | Corresponds to [`RxInferServer.Serialization.DistributionsData.Params`](@ref). |
| `mean_cov` | Corresponds to [`RxInferServer.Serialization.DistributionsData.MeanCov`](@ref). |
| `none` | Corresponds to [`RxInferServer.Serialization.DistributionsData.None`](@ref). |

### Examples 

Here's how different distributions would change their representation depending on different preferences:

```@example preferences
set_header(client, "Prefer", "distributions_data=named_params")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

```@example preferences
set_header(client, "Prefer", "distributions_data=params")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

```@example preferences
set_header(client, "Prefer", "distributions_data=mean_cov")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

```@example preferences
set_header(client, "Prefer", "distributions_data=none")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

It is possible to combine multiple preferences to achieve the desired output format. For example, to get just the mean and covariance parameters in a compact format:

```@example preferences
set_header(client, "Prefer", "distributions_repr=data,distributions_data=mean_cov")
univariate_distribution = hidden_get_univariate_distribution() #hide
multivariate_distribution = hidden_get_multivariate_distribution() #hide
nothing #hide
```

```@example preferences
univariate_distribution
```

```@example preferences
multivariate_distribution
```

## Combination of preferences

It is possible to combine multiple preferences to achieve the desired output format. 
For example, we could request server to return a diagonal part of the covariance matrix of a multivariate distribution without extra metadata in the following way:

```@example preferences
set_header(client, "Prefer", "distributions_repr=data,distributions_data=mean_cov,mdarray_repr=data,mdarray_data=diagonal")
multivariate_distribution = hidden_get_multivariate_distribution() #hide
@test multivariate_distribution["mean"] isa Vector && multivariate_distribution["mean"] == [1.0, 2.0] #hide
@test multivariate_distribution["cov"] isa Vector && multivariate_distribution["cov"] == [3.0, 4.0] #hide
nothing #hide
```

```@example preferences
multivariate_distribution
```

## API Reference

```@docs
RxInferServer.RequestPreferences
```
