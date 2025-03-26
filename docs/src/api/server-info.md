# [Server details and version](@id server-info)

The server exposes a few endpoints for getting information about the server or checking if the server is running.

## Prerequisites

Before using the Models API, you need a valid authentication token. If you haven't obtained one yet, please refer to the [Authentication](@ref authentication-api) guide. The examples below assume you have already set up authentication:

```@setup server-info
import RxInferClientOpenAPI
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: AuthenticationApi, token_generate, basepath
using Test

api          = AuthenticationApi(Client(basepath(AuthenticationApi)))
response, _  = token_generate(api)
@test !isnothing(response)
token = response.token
```

```@example server-info
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: ServerApi

client = Client(basepath(ServerApi); headers = Dict(
    "Authorization" => "Bearer $token"
))

api = ServerApi(client)
nothing #hide
```

## Pinging the Server

You can ping the server to check if it's running. This should return `{ "status": "ok" }` if the server is running.

```@example server-info
import RxInferClientOpenAPI
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: ServerApi, ping_server, basepath

response, _ = ping_server(api)
@test response.status == "ok" #hide
response
```

!!! note
    The `ping` endpoint does not require authentication.

## Getting Server Information

You can also get information about the server properties, such as the server version, running Julia version and the RxInfer version:

```@example server-info
import RxInferClientOpenAPI: get_server_info

response, _ = get_server_info(api)
response
```