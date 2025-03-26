# [Authentication](@id authentication-api)

The RxInferServer uses token-based authentication to secure access to its endpoints. This guide explains how to obtain and use authentication tokens, understand token roles, and manage model access.

## Overview

Most endpoints in RxInferServer require authentication, with a few exceptions. The authentication system is based on tokens and follows the Bearer token scheme. All authentication-related endpoints are grouped under the `Authentication` tag in [the OpenAPI specification](@ref openapi).

## Getting Started with Authentication

### Obtaining a Token

To authenticate with the server, you first need to obtain a token using the `token_generate` operation. This endpoint supports both user authentication and API key authentication.

```@example auth-generate-token
import RxInferClientOpenAPI
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: AuthenticationApi, token_generate, basepath
using Test #hide

url          = basepath(AuthenticationApi)
client       = Client(url)
api          = AuthenticationApi(client)
response, _  = token_generate(api)
@test !isnothing(response) #hide

response.token
```

!!! tip "Development Mode"
    During development, you can use the predefined token from [`RXINFER_SERVER_DEV_TOKEN`](@ref RxInferServer.RXINFER_SERVER_DEV_TOKEN) environment variable for authentication. This simplifies the development workflow, but should not be used in production.

### Using the Token

Once you have obtained a token, you need to include it in the `Authorization` header of your requests. The token should be prefixed with `Bearer` as shown below:

```@example auth-generate-token
import RxInferClientOpenAPI.OpenAPI.Clients: set_header

set_header(client, "Authorization", "Bearer $(response.token)")
```

!!! warning "Token Security"
    - Keep your tokens secure and private
    - Store tokens in a secure location
    - Never expose tokens in client-side code or version control
    - Implement proper token rotation and management in production
    - Remember that models are associated with the token used to create them

## Understanding Token Roles

### Viewing Token Roles

Each token comes with a set of assigned roles that determine its access permissions. You can retrieve the roles associated with your token using the `token_roles` operation:

```@example auth-generate-token
import RxInferClientOpenAPI: token_roles

response, _ = token_roles(api)
@test !isnothing(response) #hide

response.roles
```

### Model Access and Roles

Roles control which models a token can access. Here's how to list accessible models:

```@example auth-generate-token
import RxInferClientOpenAPI: ModelsApi, get_models

models_api = ModelsApi(client)
response, _ = get_models(models_api)
@test !isnothing(response) #hide
@test length(response.models) > 0 #hide

response.models
```

To inspect the roles required for a specific model, you can use the `get_model_details` operation:

```@example auth-generate-token
import RxInferClientOpenAPI: ModelsApi, get_model_details

models_api = ModelsApi(client)
response, _ = get_model_details(models_api, response.models[1].name)
@test !isnothing(response) #hide

response.config["roles"]
```

Read more about the Models API in the [Models](@ref models-api) section.



