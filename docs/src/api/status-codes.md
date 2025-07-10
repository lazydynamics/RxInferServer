# [Status codes and error handling](@id status-codes)

RxInferServer uses standard HTTP status codes to indicate the success or failure of API requests. This section describes the responses you can expect from the server.

## 200 OK

The 200 OK status code indicates that the request was successful.

```@example status-codes-success
import RxInferServer.RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferServer.RxInferClientOpenAPI: ServerApi, ping_server, basepath
using Test #hide

client = Client(basepath(ServerApi))

response, info = ping_server(ServerApi(client))
@test info.status == 200 #hide

info.status
```

```@example status-codes-success
response
```

## 401 Unauthorized

If you try to access a resource that requires authentication, the server will return a 401 Unauthorized error. This typically happens when you try to access a resource that requires a token, but you haven't provided a valid token.

```@example error-handling
import RxInferServer.RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferServer.RxInferClientOpenAPI: ServerApi, get_server_info, basepath
using Test #hide

client = Client(basepath(ServerApi))

response, info = get_server_info(ServerApi(client))
@test !isnothing(response) #hide
@test response.error == "Unauthorized" #hide
@test info.status == 401 #hide

info.status
```

```@example error-handling
response
```

For accessing protected resources, you need to provide a valid token. See the [Authentication](@ref authentication-api) section for more information.

```@example error-handling
using RxInferServer #hide
token = RxInferServer.DEFAULT_DEV_TOKEN #hide
client = Client(basepath(ServerApi); headers = Dict(
    "Authorization" => "Bearer $token"
))
nothing #hide
```

## 404 Not Found

The 404 Not Found error indicates that the resource you're trying to access does not exist.

```@example error-handling
import RxInferServer.RxInferClientOpenAPI: ModelsApi, get_model_instance

response, info = get_model_instance(ModelsApi(client), "non-existent-model")
@test !isnothing(response) #hide
@test response.error == "Not Found" #hide
@test info.status == 404 #hide

info.status
```

```@example error-handling
response
```

## 400 Bad Request

The 400 Bad Request error indicates that the request is invalid. This can happen for various reasons, such as invalid JSON payloads, missing required fields, or incorrect parameter values.

```@example error-handling
import RxInferServer.RxInferClientOpenAPI: ModelsApi, CreateModelInstanceRequest, create_model_instance, delete_episode

response, info = create_model_instance(ModelsApi(client), CreateModelInstanceRequest(
    model_name = "BetaBernoulli-v1",
    description = "Example model for demonstration"
))
@test !isnothing(response) #hide

# Get the model id from the response
instance_id = response.instance_id

# Attempt to delete the default episode, 
# which should result in a 400 Bad Request error
response, info = delete_episode(ModelsApi(client), instance_id, "default")
@test !isnothing(response) #hide
@test response.error == "Bad Request" #hide
@test info.status == 400 #hide

info.status
```

```@example error-handling
response
```


