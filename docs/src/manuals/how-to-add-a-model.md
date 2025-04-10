# [How to Add a Model](@id manual-how-to-add-a-model)

!!! warning
    RxInferServer is a young package and the model configuration format as well as the requirements for the model implementation are subject to change to improve the developer and user experience.

This guide will walk you through the process of adding a new model to RxInferServer. We'll cover everything from model configuration to implementation and testing.

## Learning by Example

The easiest way to understand how to add a model is to look at existing examples. The `models` folder in the RxInferServer repository contains several example models that you can use as templates for your own models. Each model has its own directory with a `config.yaml` file and a `model.jl` implementation file.

Examining these examples will give you practical insights into:
- How to structure your model configuration
- How to implement the model logic
- How to handle different types of inputs and outputs
- Best practices for model organization

Feel free to use these examples as starting points for your own models, adapting them to your specific needs.

## Introduction

RxInferServer provides a flexible framework for adding and managing probabilistic models. Each model consists of:
- A configuration file (`config.yaml`) that defines the model's metadata and parameters
- A Julia file containing the model implementation

Let's start by understanding how to configure your model.

## Model Configuration

The first step in adding a model is creating its configuration file. This file defines the model's metadata and parameters in YAML format.

### Model configuration header 

The model configuration header consists of the following fields:

| Field | Description | Type | Required |
|-------|-------------|------|----------|
| `name` | The name of the model, potentially including the version identifier. | String | Yes |
| `description` | A short description of the model. | String | Yes |
| `author` | The author of the model | String | Yes |
| `roles` | The roles that can use the model. | Array of Strings | Yes |

A simple example of a model configuration header is shown below:

```yaml
name: MyModel-v1
description: A model for predicting the weather
author: John Doe
roles:
  - user
  - admin
```

### Model arguments

The `arguments` section defines the parameters that can be passed to the model. Each argument can have the following properties:

| Field | Description | Type | Required |
|-------|-------------|------|----------|
| `name` | The name of the argument | String | Yes |
| `description` | A description of what the argument does | String | No |
| `type` | The expected type of the argument | String | No |
| `default` | The default value if not provided | Any | No |
| `required` | Whether the argument is required | Boolean | No |

Example of arguments configuration:

```yaml
arguments:
  - name: state_dimension
    description: The dimension of the state space
    type: int
    required: true
  - name: horizon
    description: The horizon of the model for prediction
    type: int
    default: 10
```

## Model Implementation

The model implementation file contains the actual logic for the model. It is called `model.jl` and should be in the same directory as the configuration file.

### Glocary

Here are some definitions that are useful forfuther discussion:

- **Model**: A model description is a probabilistic model that can be used for inference and learning.
- **Model Instance**: A model instance is a specific instance of a model with arguments, state and parameters.
- **Model Arguments**: The arguments of a model are the parameters that are passed to the model when it is created and treated as constants.
- **Model State**: The state of a model instance that can change between different inference calls, but usually remains as an implementation detail for each model instance.
- **Model Parameters**: The parameters of a model instance, which can be learned from data and are directly exposed to the user through the [Learning API](@ref learning-api).

### Models lifecycle

When server parses the models directory, it does not immediatelly execute the code for the models. Instead, it only parses the configuration and loads the model metadata. The actual model code is not executed until a user request to create a model _instance_. See for example the [Model management](@ref model-management-api) guide on how to create a model instance via the API calls. A user may have multiple model instances of the same model, each with its own state. The server will properly maintain the state of each model instance and ensure that the states of different model instances are isolated from each other.

### Models executing interface 

The model implementation file should define the following functions:

- `initial_state`, the function that initializes the model state
- `initial_parameters`, the function that initializes the model parameters
- `run_inference`, the function that runs inference on the model
- `run_learning`, the function that runs learning on the model

We will now discuss each of these functions in more detail.

### `initial_state` function

The `initial_state` function is called when the model instance is initialized for the first time, see [Creating a Model Instance](@ref model-management-api-create-model-instance). It accepts a dictionary of arguments (as defined in the `arguments` section of the configuration file) and may return any arbitrary Julia object representing the state of the model.

```julia
function initial_state(arguments)
    return Dict("state_dimension" => arguments["state_dimension"], "horizon" => arguments["horizon"])
end
```

In this simple example, the model state is a dictionary with two fields: `state_dimension` and `horizon` directly extracted from the `arguments` dictionary.
We could add more fields to state if necessary, for example:

```julia
function initial_state(arguments)
    return Dict("state_dimension" => arguments["state_dimension"], "horizon" => arguments["horizon"], "learning_rate" => arguments["horizon"] > 10 ? 0.01 : 0.001)
end
```

Each model is unique and may require different initialization logic for the initial state.

!!! tip
    Treat the `state` as an internal implementation detail of the model. Normally a user does not need to know about the state of the model, however, it is possible to access it through the [Get Model Instance State](@ref model-management-api-get-model-instance-state) endpoint for debugging purposes.

### `initial_parameters` function

The `initial_parameters` function is called when the model instance is initialized for the first time, see [Creating a Model Instance](@ref model-management-api-create-model-instance). It accepts a dictionary of arguments (as defined in the `arguments` section of the configuration file) and may return any arbitrary Julia object representing the parameters of the model.

```julia
function initial_parameters(arguments)
    return Dict("A" => randn(arguments["state_dimension"], arguments["state_dimension"]), "B" => randn(arguments["state_dimension"], arguments["state_dimension"]))
end
```

The difference between `parameters` and `state` is purely semantic. `state` is something that is hidden from the user and is mostly internal implementation detail. `parameters`s on the other hand are directly exposed to the user through the [Learning API](@ref learning-api). The parameters might be updated and learned from data using different [episodes](@ref learning-api-episodes).

### `run_inference` function

The `run_inference` function is called when the model instance is used for inference. It has the following signature:

```julia
function run_inference(state, parameters, event)
    # ...
    result = ...
    new_state = ...
    return result, new_state
end
```

It accepts:

- `state`: The current state of the model instance
- `parameters`: The current parameters of the model instance
- `event`: The event that triggered the inference, which containes the observed data and other metadata

It should return:

- `result`: The result of the inference, can be an arbitrary object that will be returned to the user as a part of the inference response
- `new_state`: The new state of the model instance, which will be used in the next inference calls and/or learning calls

### `run_learning` function

The `run_learning` function is called when the model instance is used for learning. It has the following signature:

```julia
function run_learning(state, parameters, events)
    result = ... 
    new_state = ...
    new_parameters = ...
    return result, new_state, new_parameters
end
```

It accepts:

- `state`: The current state of the model instance
- `parameters`: The current parameters of the model instance
- `events`: The collection of events that triggered the learning, which are directly linked to a single episode

It should return:

- `result`: The result of the learning, can be an arbitrary object that will be returned to the user as a part of the learning response
- `new_state`: The new state of the model instance, which will be used in the next learning calls
- `new_parameters`: The new parameters of the model instance, which will be used in the next learning calls

## Useful notes

This section contains some notes that are important to know when implementing a new model.

### Extra model dependencies 

In the current implementation, if the model's code requires additional dependencies, the model author should manually add them the main `Project.toml` file of the RxInferServer repository. This is necessary because the server uses the same `Project.toml` file to run the model code. So if for example, the model's logic requires another package, e.g. `Optim.jl`, the model author should add it to the `Project.toml` file of the RxInferServer repository.

!!! note
    This limitation might be lifted in the future, when the server will support a more flexible dependency management.

### Model state and parameters object 

It is important to remember that `state`, `parameters` and `result` objects are serialized and deserialized to JSON when sent to the server and back. Therefore, the objects should be serializable to JSON. RxInferServer uses the `Serialization` module to serialize and deserialize the complex objects, such as matrices and distributions. See the [Serialization](@ref serialization) manual as well as [Request preferences](@ref request-preferences-api) for more details.











