# [Model management](@id model-management-api)

This guide covers the Models management API, which provides endpoints for managing RxInfer models in RxInferServer. You'll learn how to create, manage, and interact with models and their episodes.

For information about how to create and add new models to the server, please refer to the [How to Add a Model](@ref manual-how-to-add-a-model) manual.

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

## Terminology 

In RxInferServer, a **model** is a type of probabilistic program that you can create and interact with. We distinguish between _available models_ and _model instances_.

- **Available models** are the models that you can use to create an instance of. They contain all the code and configuration to create an actual model instance and are usually identified by their `model_name`.
- **Model instances** are the actual instances of a model that you have created. They contain the state of the model and manage episodes, each with their own learned parameters. You can have multiple model instances of the same model which are identified by a unique `instance_id`. Individual instances are isolated from each other, meaning that they do not share state.

## Discovering Available Models

Before creating a new model instance, you can explore which model types are available on the server with the [**get\_available\_models**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_available_models

available_models, _ = get_available_models(api)
@test !isnothing(available_models) #hide
@test length(available_models) > 0 #hide

# only show the model details as the full configuration is quite large
map(model -> model.details, available_models)
```

Note that the list of available models depends on the [roles](@ref authentication-api-roles) assigned to the token used to make the request as well as server settings.

## Inspecting Available Model Details and Configuration

Each model type comes with detailed configuration and specifications. For example:

```@example models-api
available_models[1].details
```

```@example models-api
available_models[1].config
```

Alternatively, you can inspect these using the [**get\_available\_model**](@ref) operation with the specific model name:

```@example models-api
import RxInferClientOpenAPI: get_available_model

some_model, _ = get_available_model(api, available_models[1].details.name)
@test some_model.details.name == available_models[1].details.name #hide
@test some_model.details.description == available_models[1].details.description #hide
@test !isnothing(some_model) #hide
@test hasproperty(some_model, :details) #hide
@test hasproperty(some_model, :config) #hide
nothing #hide
```

The response provides two key pieces of information:
1. `details`: Light-weight model information
2. `config`: Model-specific configuration

```@example models-api
some_model.details
```

```@example models-api
some_model.config
```

## [Creating a Model Instance](@id model-management-api-create-model-instance)

Once you have selected the model you want to use, you can create a new instance of it with the [**create\_model\_instance**](@ref) operation together with the [`CreateModelInstanceRequest`](@ref) type:

```@example models-api
import RxInferClientOpenAPI: create_model_instance, CreateModelInstanceRequest

request = CreateModelInstanceRequest(
    model_name = available_models[1].details.name,
    description = """
    An arbitrary instance description, 
    which can be used to identify the instance later on
    """,
    # Optional: Customize model behavior with arguments
    # arguments = Dict(...)
)

response, _ = create_model_instance(api, request)
@test !isnothing(response) #hide
instance_id = response.instance_id
```

If successful, the server returns a unique `instance_id` that you'll use to interact with this specific model instance. A server may return an error if the model is not found or if the instance already exists.

```@example models-api
response, _ = create_model_instance(api, CreateModelInstanceRequest(
    model_name = "non_existent_model"
))
@test response.error == "Not Found" #hide
response
```

## Listing Created Model Instances

View all instances of models you've created with the [**get\_model\_instances**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_model_instances

created_models, _ = get_model_instances(api)
@test !isnothing(created_models) #hide
@test created_models[1].instance_id == instance_id #hide
created_models
```

We can see indeed that the list contains the instance we created earlier.

```@example models-api
created_models[1].instance_id == instance_id
```

## Getting Details of a Specific Model Instance

Previously we retrieved a list of all model instances. Now we can retrieve details about a specific model instance with the [**get\_model\_instance**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: get_model_instance

response, _ = get_model_instance(api, instance_id)
@test !isnothing(response) #hide
response
```

## [Checking the State of a Specific Model Instance](@id model-management-api-get-model-instance-state)

Monitor the current state of your model with the **get\_model\_instance\_state** operation:

```@example models-api
import RxInferClientOpenAPI: get_model_instance_state    

response, _ = get_model_instance_state(api, instance_id)
@test !isnothing(response) #hide
response
```

## [Checking the Parameters of a Specific Model Instance](@id model-management-api-get-model-instance-parameters)

Monitor the current parameters of your model with the **get\_model\_instance\_parameters** operation:

```@example models-api
import RxInferClientOpenAPI: get_model_instance_parameters

response, _ = get_model_instance_parameters(api, instance_id)
@test !isnothing(response) #hide
response
```

!!! note "State of a Model Instance vs Parameters of a Model Instance"
    Note that the state of a model instance is not the same as the parameters of the model. You can consider the state as an internal implementation detail of the model and is not exposed to the user. The parameters are, however, directly exposed through the [Learning API](@ref learning-api) and are stored at the episode level. Each episode maintains its own parameters, and the model instance parameters reflect the current episode's parameters.

## Deleting a Model Instance

When you're done with a model instance, you can remove it completely with the [**delete\_model\_instance**](@ref) operation:

```@example models-api
import RxInferClientOpenAPI: delete_model_instance

response, _ = delete_model_instance(api, instance_id)
@test !isnothing(response) #hide
response
```

!!! note "Cascade Deletion"
    - Deleting an instance automatically removes all its episodes, read more about episodes in the [Learning parameters of a model](@ref learning-api) section
    - Deleting an instance does not delete other instances of the same model
    - This action cannot be undone
    - Make sure to save any important data before deletion

Verify the model has been removed:

```@example models-api
# Check model list
created_models, _ = get_model_instances(api)
@test !isnothing(created_models) #hide
@test length(created_models) == 0 #hide
created_models
```

```@example models-api
# Check model list
response, _ = get_model_instance(api, instance_id)
@test response.error == "Not Found" #hide
response
```











