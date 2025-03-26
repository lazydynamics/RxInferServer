# [Model management](@id model-management-api)

This guide covers the Models management API, which provides endpoints for managing RxInfer models in RxInferServer. You'll learn how to create, manage, and interact with models and their episodes.

## Prerequisites

Before using the Models API, you need a valid authentication token. If you haven't obtained one yet, please refer to the [Authentication](@ref authentication-api) guide. The examples below assume you have already set up authentication:

```@setup models-api
import RxInferClientOpenAPI
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: AuthenticationApi, token_generate, basepath
using Test

api          = AuthenticationApi(Client(basepath(AuthenticationApi)))
response, _  = token_generate(api)
@test !isnothing(response)
token = response.token
```

```@example models-api
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: ModelsApi

client = Client(basepath(ModelsApi); headers = Dict(
    "Authorization" => "Bearer $token"
))

api = ModelsApi(client)
nothing #hide
```

## Discovering Available Models

Before creating a model instance, you can explore which model types are available on the server with the [**get\_models**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_models

response, _ = get_models(api)
@test !isnothing(response) #hide
@test length(response.models) > 0 #hide

available_models = response.models
```

Note that the list of available models depends on the [roles](@ref authentication-api-roles) assigned to the token used to make the request as well as server settings.

## Inspecting Model Details

Each model type comes with detailed configuration and specifications. You can inspect these using the [**get\_model\_details**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_model_details

response, _ = get_model_details(api, available_models[1].name)
@test !isnothing(response) #hide
@test hasproperty(response, :details) #hide
@test hasproperty(response, :config) #hide
nothing #hide
```

The response provides two key pieces of information:
1. `details`: Light-weight model information
2. `config`: Model-specific configuration

```@example models-api
response.details
```

```@example models-api
response.config
```

### Creating a Model Instance

To create a new instance of a model you can use the [**create\_model**](@ref) operation together with the [`CreateModelRequest`](@ref) type:

```@example models-api
import RxInferClientOpenAPI: create_model, CreateModelRequest

request = CreateModelRequest(
    model = available_models[1].name,
    description = "Example model for demonstration",
    # Optional: Customize model behavior with arguments
    # arguments = Dict(...)
)

response, _ = create_model(api, request)
@test !isnothing(response) #hide
model_id = response.model_id
```

If successful, the server returns a unique `model_id` that you'll use to interact with this specific model instance.

## Listing Your Models

View all models you've created with the [**get\_created\_models\_info**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_created_models_info

created_models, _ = get_created_models_info(api)
@test !isnothing(created_models) #hide
created_models
```

## Getting Model Information

Retrieve details about a specific model instance with the [**get\_model\_info**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_model_info

response, _ = get_model_info(api, model_id)
@test !isnothing(response) #hide
response
```

## Checking Model State

Monitor the current state of your model with the [**get\_model\_state**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_model_state    

response, _ = get_model_state(api, model_id)
@test !isnothing(response) #hide
response
```

## Deleting a Model

When you're done with a model, you can remove it completely with the [**delete\_model**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: delete_model

response, _ = delete_model(api, model_id)
@test !isnothing(response) #hide
response
```

!!! note "Cascade Deletion"
    - Deleting a model automatically removes all its episodes, read more about episodes in the [Learning parameters of a model](@ref learning-api) section
    - This action cannot be undone
    - Make sure to save any important data before deletion

Verify the model has been removed:

```@example models-api
# Check model list
created_models, _ = get_created_models_info(api)
@test !isnothing(created_models) #hide
@test length(created_models) == 0 #hide
created_models
```











