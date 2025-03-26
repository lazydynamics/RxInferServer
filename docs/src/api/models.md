# [Models](@id models-api)

This guide covers the Models API, which provides endpoints for managing machine learning models in RxInferServer. You'll learn how to create, manage, and interact with models and their episodes.

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

Let's initialize our Models API client with the authentication token:

```@example models-api
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: ModelsApi

client = Client(basepath(ModelsApi); headers = Dict(
    "Authorization" => "Bearer $token"
))

api = ModelsApi(client)
nothing #hide
```

## Model Management

### Discovering Available Models

Before creating a model instance, you can explore which model types are available on the server:

```@example models-api
import RxInferClientOpenAPI: get_models

response, _ = get_models(api)
@test !isnothing(response) #hide
@test length(response.models) > 0 #hide

available_models = response.models
```

### Inspecting Model Details

Each model type comes with detailed configuration and specifications. You can inspect these using:

```@example models-api
import RxInferClientOpenAPI: get_model_details

response, _ = get_model_details(api, available_models[1].name)
@test !isnothing(response) #hide
@test hasproperty(response, :details) #hide
@test hasproperty(response, :config) #hide
nothing #hide
```

The response provides two key pieces of information:
1. `details`: Essential model information and capabilities
2. `config`: Model-specific configuration options

```@example models-api
response.details
```

```@example models-api
response.config
```

### Creating a Model Instance

To create a new instance of a model:

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

The server returns a unique `model_id` that you'll use to interact with this specific model instance.

### Managing Model Instances

#### Listing Your Models

View all models you've created:

```@example models-api
import RxInferClientOpenAPI: get_created_models_info

created_models, _ = get_created_models_info(api)
@test !isnothing(created_models) #hide
created_models
```

#### Getting Model Information

Retrieve details about a specific model instance:

```@example models-api
import RxInferClientOpenAPI: get_model_info

response, _ = get_model_info(api, model_id)
@test !isnothing(response) #hide
response
```

#### Checking Model State

Monitor the current state of your model:

```@example models-api
import RxInferClientOpenAPI: get_model_state    

response, _ = get_model_state(api, model_id)
@test !isnothing(response) #hide
response
```

## Working with Episodes

Episodes are containers for training data and metadata. They help organize different training sessions or data collection periods for your model.

### Episode Basics

- Each model starts with a `default` episode
- Episodes help organize training data and experiments

### Managing Episodes

#### Listing Episodes

View all episodes for a model:

```@example models-api
import RxInferClientOpenAPI: get_episodes

response, _ = get_episodes(api, model_id)
@test !isnothing(response) #hide
response
```

#### Episode Details

Get information about a specific episode:

```@example models-api
import RxInferClientOpenAPI: get_episode_info

response, _ = get_episode_info(api, model_id, "default")
@test !isnothing(response) #hide
response
```

#### Creating New Episodes

Create a new episode for different experiments or training sessions:

```@example models-api
import RxInferClientOpenAPI: create_episode

response, _ = create_episode(api, model_id, "experiment-1")
@test !isnothing(response) #hide
response
```

!!! note "Current Episode"
    Creating a new episode automatically makes it the current episode:
    ```@example models-api
    response, _ = get_model_info(api, model_id)
    @test !isnothing(response) #hide
    @test response.current_episode == "experiment-1" #hide
    response.current_episode
    ```

Verify the new episode appears in the list:

```@example models-api
response, _ = get_episodes(api, model_id)
@test !isnothing(response) #hide
@test length(response) == 2 #hide
@test "default" in map(episode -> episode.name, response) #hide
@test "experiment-1" in map(episode -> episode.name, response) #hide
response
```

#### Deleting Episodes

Remove an episode when it's no longer needed:

```@example models-api
import RxInferClientOpenAPI: delete_episode

response, _ = delete_episode(api, model_id, "experiment-1")
@test !isnothing(response) #hide
response
```

!!! warning "Default Episode"
    - The `default` episode cannot be deleted
    - When the current episode is deleted, the system automatically switches to the `default` episode
    - You can clear data from the `default` episode, but cannot remove it entirely

```@example models-api
# Attempting to delete the default episode
response, _ = delete_episode(api, model_id, "default")
@test !isnothing(response) #hide
@test response.error == "Bad Request" #hide
response
```

## Cleanup

### Deleting a Model

When you're done with a model, you can remove it completely:

```@example models-api
import RxInferClientOpenAPI: delete_model

response, _ = delete_model(api, model_id)
@test !isnothing(response) #hide
response
```

!!! note "Cascade Deletion"
    - Deleting a model automatically removes all its episodes
    - This action cannot be undone
    - Make sure to save any important data before deletion

Verify the model has been removed:

```@example models-api
# Check model list
created_models, _ = get_created_models_info(api)
@test !isnothing(created_models) #hide
@test length(created_models) == 0 #hide
created_models

# Verify episodes are also removed
response, _ = get_episodes(api, model_id)
@test !isnothing(response) #hide
@test response.error == "Not Found" #hide
response
```











