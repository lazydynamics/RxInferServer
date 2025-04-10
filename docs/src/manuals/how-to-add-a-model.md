# [How to Add a Model](@id manual-how-to-add-a-model)

!!! warning
    RxInferServer is a young package and the model configuration format as well as the requirements for the model implementation are subject to change to improve the developer and user experience.

Welcome to the guide on adding models to RxInferServer! This comprehensive guide will walk you through everything you need to know to create and integrate your own probabilistic models into the server. Whether you're building a simple prediction model or a complex inference system, this guide has you covered.

## Learning by Example

The best way to get started is by exploring existing models. In the RxInferServer repository, you'll find a `models` directory containing several example models. These examples serve as practical templates and demonstrate:

- Model configuration best practices
- Implementation patterns for different use cases
- Handling various input/output scenarios
- Effective model organization strategies

Feel free to use these examples as starting points for your own models, adapting them to your specific needs.

## Model Components

Every model in RxInferServer consists of two essential files:

1. `config.yaml` - Defines the model's metadata and parameters
2. `model.jl` - Contains the actual model implementation

Let's dive into each component in detail.

## Model Configuration

The configuration file (`config.yaml`) is your model's blueprint. It defines how your model will be presented to users and what parameters it accepts.

### Basic Configuration

Every model must specify these core fields:

| Field | Description | Type | Required |
|-------|-------------|------|----------|
| `name` | Model name with version identifier | String | Yes |
| `description` | Brief description of the model | String | Yes |
| `author` | Model author's name | String | Yes |
| `roles` | User roles that can access the model | Array of Strings | Yes |

Example:
```yaml
name: WeatherPredictor-v1
description: A probabilistic model for weather prediction
author: John Doe
roles:
  - user
  - admin
```

### Model Parameters

The `arguments` section defines what parameters your model accepts:

| Field | Description | Type | Required |
|-------|-------------|------|----------|
| `name` | Parameter name | String | Yes |
| `description` | Parameter description | String | No |
| `type` | Expected data type | String | No |
| `default` | Default value | Any | No |
| `required` | Whether parameter is mandatory | Boolean | No |

Example:
```yaml
arguments:
  - name: state_dimension
    description: The dimension of the state space
    type: int
    required: true
  - name: horizon
    description: The prediction horizon
    type: int
    default: 10
```

## Model Implementation

Now, let's explore how to implement your model's logic in `model.jl`. First, let's clarify some key concepts:

### Key Concepts

- **Model**: A probabilistic model description for inference and learning
- **Model Instance**: A specific instance of a model with its own arguments, state, and parameters
- **Model Arguments**: Constants passed during model creation
- **Model State**: Internal state that persists between inference calls
- **Model Parameters**: Learnable parameters exposed through the [Learning API](@ref learning-api)

### Model Lifecycle

When the server starts, it only loads model configurations. The actual model code executes only when a user creates a model instance through the [Model management API](@ref model-management-api). Each model instance maintains its own isolated state, allowing multiple instances of the same model to operate independently.

### Required Functions

Your model implementation must define these four essential functions. Each function plays a specific role in the model's lifecycle and has a distinct semantic meaning in the context of probabilistic inference.

#### `initial_state(arguments)`

This function represents the initial conditions of your model and is called when a new model instance is created. The state is a persistent memory that evolves over time as the model processes data. It can store any information that needs to be maintained between inference calls, such as running statistics, cached computations, or model-specific metadata.

The function takes a single argument:
- `arguments`: A dictionary containing the model arguments specified in `config.yaml`

It should return a dictionary representing the initial state of the model.

Here's an example implementation:
```julia
function initial_state(arguments)
    return Dict(
        "state_dimension" => arguments["state_dimension"],
        "horizon" => arguments["horizon"],
        "learning_rate" => arguments["horizon"] > 10 ? 0.01 : 0.001
    )
end
```

#### `initial_parameters(arguments)`

This function initializes the model's learnable parameters when a new model instance is created. Parameters represent the core components of your probabilistic model that can be learned from data. These are the variables that define your model's behavior and are updated during the learning process. In Bayesian terms, these often correspond to the parameters of your prior distributions or the structure of your probabilistic model.

The function takes a single argument:
- `arguments`: A dictionary containing the model arguments specified in `config.yaml`

It should return a dictionary containing the initial values of all learnable parameters.

Here's an example implementation:
```julia
function initial_parameters(arguments)
    return Dict(
        "A" => randn(arguments["state_dimension"], arguments["state_dimension"]),
        "B" => randn(arguments["state_dimension"], arguments["state_dimension"])
    )
end
```

#### `run_inference(state, parameters, event)`

This function implements the core inference algorithm of your model and is called to perform inference on a single data point. It takes a single observation (event) and computes the posterior distribution or point estimates based on the current state and parameters. The function should return both the inference results and an updated state that reflects any changes from processing the new data point.

The function takes three arguments:
- `state`: A dictionary containing the current model state
- `parameters`: A dictionary containing the current model parameters
- `event`: A dictionary containing the input data for inference

It should return a tuple containing:
- A dictionary with the inference results
- A dictionary with the updated model state

Here's an example implementation:
```julia
function run_inference(state, parameters, event)
    # Inference logic here
    result = ...
    new_state = ...
    return result, new_state
end
```

#### `run_learning(state, parameters, events)`

This function implements the learning algorithm for your model and is called to update model parameters based on a batch of data. It processes a batch of observations to update the model parameters, typically using some form of gradient-based optimization or Bayesian updating. The function should return updated parameters, an updated state, and any relevant learning metrics or diagnostics.

The function takes three arguments:
- `state`: A dictionary containing the current model state
- `parameters`: A dictionary containing the current model parameters
- `events`: An array of dictionaries containing the batch of input data for learning

It should return a tuple containing:
- A dictionary with the learning results (e.g., metrics, diagnostics)
- A dictionary with the updated model state
- A dictionary with the updated model parameters

Here's an example implementation:
```julia
function run_learning(state, parameters, events)
    # Learning logic here
    result = ...
    new_state = ...
    new_parameters = ...
    return result, new_state, new_parameters
end
```

## Important Considerations

### Dependencies

Currently, if your model requires additional Julia packages, you must add them to the main `Project.toml` file of the RxInferServer repository. This is because the server uses the same environment to run all models.

!!! note
    This limitation might be lifted in future versions with more flexible dependency management.

### Serialization

Remember that `state`, `parameters`, and `result` objects are serialized to JSON when communicating with the server. RxInferServer uses the `Serialization` module to handle complex objects like matrices and distributions. For more details, see the [Serialization](@ref serialization) manual and [Request preferences](@ref request-preferences-api) documentation.

## Next Steps

Now that you understand the basics of adding a model to RxInferServer, you might want to:

1. Explore the [Model management API](@ref model-management-api) to understand how to interact with your model
2. Check out the [Learning API](@ref learning-api) for details on model training
3. Review the [Serialization](@ref serialization) guide for handling complex data types
4. Look at existing models in the repository for practical examples
