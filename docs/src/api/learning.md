# [Learning](@id learning-api)

This guide covers the Learning API, which provides endpoints for training and inference with RxInfer models. You'll learn how to create, manage, and interact episodes as well as perform a simple learning task.

## Prerequisites

Before using the Models API, you need a valid authentication token. If you haven't obtained one yet, please refer to the [Authentication](@ref authentication-api) guide. The examples below assume you have already set up authentication:

```@setup learning-api
import RxInferClientOpenAPI
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: AuthenticationApi, token_generate, basepath
using Test

api          = AuthenticationApi(Client(basepath(AuthenticationApi)))
response, _  = token_generate(api)
@test !isnothing(response)
token = response.token
```

```@example learning-api
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: ModelsApi

client = Client(basepath(ModelsApi); headers = Dict(
    "Authorization" => "Bearer $token"
))

api = ModelsApi(client)
nothing #hide
```

## Creating a model instance 

Read more about how to create a model instance in the [Model management](@ref model-management-api) section. Here we assume that you have already created a model instance and have its `instance_id`.

```@example learning-api
import RxInferClientOpenAPI: create_model_instance, CreateModelInstanceRequest

request = CreateModelInstanceRequest(
    model_name = "BetaBernoulli-v1",
    description = "Example model for demonstration",
    # Optional: Customize model behavior with arguments
    # arguments = Dict(...)
)

response, _ = create_model_instance(api, request)
@test !isnothing(response) #hide
instance_id = response.instance_id
```

## Working with Episodes

Episodes are containers for training data and metadata. They help organize different training sessions or data collection periods for your model.

### Episode Basics

- Each model starts with a `default` episode
- Episodes help organize training data and experiments

### Managing Episodes

#### Listing Episodes

View all episodes for a model:

```@example learning-api
import RxInferClientOpenAPI: get_episodes

response, _ = get_episodes(api, instance_id)
@test !isnothing(response) #hide
response
```

#### Episode Details

Get information about a specific episode:

```@example learning-api
import RxInferClientOpenAPI: get_episode_info

response, _ = get_episode_info(api, instance_id, "default")
@test !isnothing(response) #hide
response
```

#### Creating New Episodes

Create a new episode for different experiments or training sessions:

```@example learning-api
import RxInferClientOpenAPI: create_episode, CreateEpisodeRequest

create_episode_request = CreateEpisodeRequest(name = "experiment-1")

response, _ = create_episode(api, instance_id, create_episode_request)
@test !isnothing(response) #hide
response
```

!!! note "Current Episode"
    Creating a new episode automatically makes it the current episode:
    ```@example learning-api
    import RxInferClientOpenAPI: get_model_instance
    response, _ = get_model_instance(api, instance_id)
    @test !isnothing(response) #hide
    @test response.current_episode == "experiment-1" #hide
    response.current_episode
    ```

Verify the new episode appears in the list:

```@example learning-api
import RxInferClientOpenAPI: get_episodes

response, _ = get_episodes(api, instance_id)
@test !isnothing(response) #hide
@test length(response) == 2 #hide
@test "default" in map(episode -> episode.episode_name, response) #hide
@test "experiment-1" in map(episode -> episode.episode_name, response) #hide
response
```

#### Deleting Episodes

Remove an episode when it's no longer needed:

```@example learning-api
import RxInferClientOpenAPI: delete_episode

response, _ = delete_episode(api, instance_id, "experiment-1")
@test !isnothing(response) #hide
response
```

!!! warning "Default Episode"
    - The `default` episode cannot be deleted
    - When the current episode is deleted, the system automatically switches to the `default` episode
    - You can clear data from the `default` episode, but cannot remove it entirely

```@example learning-api
# Attempting to delete the default episode
response, _ = delete_episode(api, instance_id, "default")
@test !isnothing(response) #hide
@test response.error == "Bad Request" #hide
response
```