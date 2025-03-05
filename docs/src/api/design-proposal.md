# Design Proposal for RxInfer Model Server API

This proposal outlines a clean, RESTful API for the RxInfer model server, focusing on simplicity and ease of implementation while maintaining powerful probabilistic modeling capabilities. The current API is different and we can discuss how to integrate both of them.

## Core Concepts

- **Model Instance**: An isolated runtime environment for a specific model, identified by a unique ID
- **Arguments**: Fixed values passed to the model that don't change during inference (e.g., time step)
- **Parameters**: Values that can be learned by the model (e.g., transition matrices)
- **Episode**: A sequence of observations and actions, used for learning parameters

!!! note
    Do not confuse the `arguments` with the `parameters`. The `arguments` are the arguments that are passed to the model and are fixed for a single `infer` call. The `parameters` are the parameters that are learned by the model and are updated by the `/api/models/{model_id}/learn` endpoint.

## API Endpoints

### Create a Model Instance

The central to the API would be to create an endpoint for a single model _instance_. An _instance_ would be defined as an isolated run-time environment for a specific model. It would be identified by a unique id. Two instances of the same model can be run in parallel and do not interfere with each other (unless they are explicitly designed to communicate with each other).

```
POST /api/models
```

#### Request

```json
{
  "model": "drone-v1",                    // (required) Model type name
  "description": "Drone model (testing)", // (optional) Description
  "arguments": {                          // (optional) Model configuration
    "dt": 0.1,
    "horizon": 10
  }
}
```

In the beginning we will be required to craft these models manually. This proposal does not allow users to define their own models. Thus, the `model` requires to be a valid model name, e.g. `drone-v1`, `ar`, `rslds`, `hmm`. A model also specifies the layout of the data that can be sent to the model as well as the parameters of the model that can be learned and actions that can be taken. The model also defines the set of fixed arguments that might be modified, e.g. `dt` or `horizon`. Those arguments are not learned by the model, but might be overwritten for a specific `infer` call. All of this information must be explicitly documented by a model designer (us in the beginning).

#### Response

```json
{
  "model_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

A user will now be able to use this `model_id` to send data to the model, plan actions or execute the learning.

### Run Inference

```
POST /api/models/{model_id}/infer
```

#### Request

```json
{
  "observation": {
    "y": [4, 5, 6]
  },
  "goal": {
    "y[end]": [5, 6, 7]
  },
  "timestamp": 1234567890,         // (required) Observation timestamp
  "episode_id": "default",          // (optional) Episode identifier
  "arguments": {                    // (optional) Override model arguments
    "horizon": 100
  }
}
```

Notes:
- The `observation` is a dictionary of the data to be sent to the model as defined in the model schema.
- The `timestamp` field is the timestamp of the data, not the time when the data was received by the server. Certain models assume a certain frequency of the data, e.g. every `dt` seconds. In that case the server will use the `timestamp` to determine the time of the data to order them in time and to determine if any of the data is missing.
- The `episode_id` is the id of the episode to which the data belongs. Can be omitted, `default` is used if not provided.
- The idea of the episode is to group data into chunks, from which the model can learn independently. An agent can also decide to learn from a particular episode only once for efficiency or discard certain episodes if they are too old for example.
- The syntax for the `goal` is currently structured for MPC-like behavior, setting a single goal at the end of the horizon. In future versions, we may expand this to support more complex goal specifications for true AIF.
- The `arguments` are the arguments that are passed to the model. They are not learned by the model, but might be overwritten for a specific `infer` call.

#### Response

```json
{
  "status": "success",
  "posterior": {
    "u": {
      "distribution_type": "NormalMeanVariance",
      "mean": [0.1, 0.2, 0.3],
      "variance": [0.01, 0.02, 0.03]
    }
  }
}
```

The purpose of the `posterior` is to provide the user with a distribution over the actions that can be taken. The user can then use this distribution to take an action or to sample an action.

### Store Action

As noted in the original question, both observations and actions need to be stored to properly learn model parameters. The following endpoint allows storing the actions that were actually taken:

```
POST /api/models/{model_id}/actions
```

#### Request

```json
{
  "timestamp": 1234567890,
  "episode_id": "default",
  "action": {
    "u": [0.1, 0.2, 0.3]
  }
}
```

#### Response

```json
{
  "status": "success"
}
```

### Learn Parameters

A model can have parameters that can be learned from data. For example state transition matrices can be learned, or observational noise can be learned. Those are specified in the model's schema. During the `infer` call most of the model's parameters are fixed and not updated. This endpoint is used specifically to update the parameters of the model based on the data saved in the episodes.

```
POST /api/models/{model_id}/learn
```

#### Request

```json
{
  "episode_ids": ["default", "episode2"], // (optional) Episodes to learn from
  "relearn_episodes": false,              // (optional) Relearn from all data points
  "parameters": ["A", "B", "C"]           // (optional) Parameters to learn
}
```

The idea of the `episode_ids` is to specify the episodes to learn from. If not provided, all episodes will be used. By default, if a model learned from a particular episode, it will not be used again unless the `relearn_episodes` flag is set to `true`. Or if the episode has new data it will be used again, but only the portion of the episode that has not been learned yet. Basically each episode should track whenever it has been used for learning or not. Which data has been used for learning or not. And what was the outcome of the learning.

An example of how it might work:

- Suppose we have episode with id "episode1" and it has 1000 data points and it hasn't been used for learning yet.
- The server receives the `/api/models/{model_id}/learn` request with `episode_ids` set to `["episode1"]`.
- The server uses the data saved in the episode "episode1" to learn new posteriors over the parameters of the model and saves it. It also saves the fact that it has been used for learning and it saves that exactly `1000` data points have been used for learning.
- The server progress forward in time and receives new data into the episode "episode1".
- The server receives the `/api/models/{model_id}/learn` request with `episode_ids` set to `["episode1"]`.
- The server has already learned from the first 1000 data points, so it will only learn from the new data.
- To do that it uses previously learned posteriors as a prior and learns the new posteriors using the new data only.
- The server progresses forward in time and receives new data into the episode "episode1".
- The server receives the `/api/models/{model_id}/learn` request with `episode_ids` set to `["episode1"]` and `relearn_episodes` set to `true`.
- The server will discard previously learned posteriors and will learn from all the data saved in the episode "episode1" again.

What to do with multiple episodes?

- The server learns from episode with id "episode1" and gets "posterior1".
- The server learns from episode with id "episode2" and gets "posterior2".
- The server learns from episode with id "episode3" and gets "posterior3".
- The server can now compute the product of all the posteriors and get the final posterior.

#### Response

```json
{
  "status": "success"
}
```

After that all next invocations of the `/api/models/{model_id}/infer` endpoint will use the new posteriors for the learned parameters.

### List Models

```
GET /api/models
```

#### Response

```json
{
  "models": [
    {
      "model_id": "123e4567-e89b-12d3-a456-426614174000",
      "model": "drone-v1",
      "description": "Drone model (testing)",
      "created_at": "2023-04-01T12:00:00Z",
      "episode_count": 2
    }
  ],
  "total": 1
}
```

### Get Model Details

```
GET /api/models/{model_id}
```

#### Response

```json
{
  "model_id": "123e4567-e89b-12d3-a456-426614174000",
  "model": "drone-v1",
  "description": "Drone model (testing)",
  "created_at": "2023-04-01T12:00:00Z",
  "arguments": {
    "dt": 0.1,
    "horizon": 10
  },
  "parameters": {
    "A": {"learned": true, "last_updated": "2023-04-01T14:20:00Z"},
    "B": {"learned": true, "last_updated": "2023-04-01T14:20:00Z"},
    "C": {"learned": false}
  }
}
```

### Delete Model

```
DELETE /api/models/{model_id}
```

#### Response

```json
{
  "status": "success",
  "message": "Model deleted successfully"
}
```

### List Episodes

```
GET /api/models/{model_id}/episodes
```

#### Response

```json
{
  "episodes": [
    {
      "episode_id": "default",
      "data_points": 120,
      "learned_points": 100,
      "start_timestamp": 1234567800,
      "end_timestamp": 1234568800,
      "last_updated": "2023-04-01T13:45:00Z"
    }
  ],
  "total": 1
}
```

### Get Available Model Types

```
GET /api/model-types
```

#### Response

```json
{
  "model_types": [
    {
      "name": "drone-v1",
      "description": "Dynamical model of a drone",
      "schema_url": "/api/model-types/drone-v1/schema",
      "category": "robotics"
    }
  ]
}
```

### Get Model Type Schema

```
GET /api/model-types/{model_name}/schema
```

#### Response

```json
{
  "name": "drone-v1",
  "description": "Dynamical model of a drone",
  "version": "1.0.0",
  "arguments": {
    "dt": {
      "type": "float",
      "description": "Time step duration",
      "default": 0.1,
      "min": 0.01,
      "max": 1.0
    },
    "horizon": {
      "type": "integer",
      "description": "Planning horizon length",
      "default": 10,
      "min": 1,
      "max": 100
    }
  },
  "parameters": {
    "A": {
      "type": "matrix",
      "description": "State transition matrix",
      "dimensions": [6, 6],
      "learnable": true
    },
    "B": {
      "type": "matrix",
      "description": "Control input matrix",
      "dimensions": [6, 3],
      "learnable": true
    },
    "C": {
      "type": "matrix",
      "description": "Observation matrix",
      "dimensions": [3, 6],
      "learnable": true
    }
  },
  "observation_schema": {
    "y": {
      "type": "array",
      "description": "Position measurements",
      "dimensions": [3],
      "example": [0.0, 0.0, 1.0]
    }
  },
  "action_schema": {
    "u": {
      "type": "array",
      "description": "Control inputs",
      "dimensions": [3],
      "example": [0.1, 0.0, 0.2]
    }
  },
  "goal_schema": {
    "y[end]": {
      "type": "array",
      "description": "Target position at end of horizon",
      "dimensions": [3],
      "example": [1.0, 1.0, 2.0]
    }
  }
}
```

## Error Handling

All API endpoints return consistent error responses:

```json
{
  "error_code": "ERROR_CODE",
  "error_description": "Human-readable error description"
}
```

### Common Error Codes

```
MODEL_NOT_FOUND             - The model does not exist
DATA_NOT_FOUND              - The data is missing in the request
DATA_INCOMPLETE             - The data is incomplete (missing required fields)
DATA_LAYOUT_NOT_COMPATIBLE  - The data layout is not compatible with the model schema
DATA_NOT_VALID              - The data is not valid (e.g. `NaN`, `Inf` or negative values where positive values are expected)
INVALID_REQUEST             - The request is malformed
```

## Authentication

Simple API key authentication:

```
Authorization: Bearer <api_key>
```

In the beginning we simply provide an API endpoint to generate a new API key:

```
POST /api/generate-api-key
```

Response:

```json
{
  "api_key": "your-new-api-key"
}
```

## Distribution Representation

Since RxInfer works with probabilistic models, it's essential to represent distributions and uncertainty properly in the API responses. The API supports multiple formats for representing distributions:

### Normal Distribution

```json
{
  "distribution_type": "NormalMeanVariance",
  "mean": [1.5, 2.3, 0.7],
  "variance": [0.1, 0.2, 0.15]
}
```

### Multivariate Normal Distribution

```json
{
  "distribution_type": "MvNormalMeanCovariance",
  "mean": [1.5, 2.3, 0.7],
  "covariance": [
    [0.1, 0.01, 0.0],
    [0.01, 0.2, 0.02],
    [0.0, 0.02, 0.15]
  ]
}
```

### Samples from Posterior

```json
{
  "distribution_type": "SampleList",
  "samples": [
    [1.42, 2.31, 0.68],
    [1.51, 2.33, 0.71],
    [1.49, 2.28, 0.72]
  ],
  "weights": [0.33, 0.33, 0.34]  // Optional, uniform if not provided
}
```

### Categorical Distribution

```json
{
  "distribution_type": "Categorical",
  "probabilities": [0.2, 0.5, 0.3]
}
```

## Data Validation and Handling

More comprehensive data validation should be implemented:

1. **Type Validation**: Ensure all data matches the expected types
2. **Range Validation**: Verify that values fall within acceptable ranges
3. **Dimension Validation**: Check that arrays/matrices have the correct dimensions
4. **Missing Data Handling**: Define behavior for missing data points

### Time Series Interpolation

!!! note
    This is to discuss! I propose to do simple interpolation for now to what the model needs. Less relevant for discrete models & environments.

For handling irregularly-sampled time series data:

1. **Gap Detection**: Identify gaps in timestamp sequences
2. **Interpolation**: Optionally interpolate missing data points
3. **Configurable Policies**: Allow configuration of how missing data is handled

## Client Example

```python
from rxinfer.client import RxInferClient

# Create client
client = RxInferClient(api_key="your-api-key")

# Create model
model = client.create_model("drone-v1", 
                           description="Drone control model",
                           arguments={"dt": 0.1, "horizon": 10})

# Run inference
posterior = model.infer(observation={"y": [4, 5, 6]}, 
                       goal={"y[end]": [5, 6, 7]},
                       timestamp=1234567890)

# Get action
action = posterior.sample()

# Store action
model.store_action(action={"u": action}, timestamp=1234567890)

# Learn parameters
model.learn()
```

## Implementation Notes

To support this I think we need to be able to define models in the way such that it accepts an argument `N` that specifies the number of time steps that the model will be created with. In the `infer` call the `N` will be set to `horizon+1`, the very first state will be the current state with the attached observation and the rest will be pure imagination based on the currently learned parameters into the future where we set goals at the end and create MPC control-like behavior. In the `learn` call the `N` will be set to the number of data points in a particular episode and all data will be used in a smoothing regime to learn the parameters.

TLDR:
- During `infer`: parameters are point masses -> infer actions with horizon `N` = `horizon+1`, with the first state as current state
- During `learn`: observations and actions are point masses from `N` data points -> learn parameters (where `N` = number of data points in the episode)

This requires a model _at least_ in the form of:

```julia
@model function some_model(N, arguments, ...)
  # ...
  # arguments[:dt]
end
```

!!! question 
    To learn the parameter we need to have both data and the action taken! We then need to also save the action taken in the database.

## Future Considerations

1. **API Versioning**: As the API evolves, we may need to implement versioning through URL paths (e.g., `/v1/api/models`).

2. **Asynchronous Operations**: For complex models, learning might take a long time. We may need to implement asynchronous endpoints for long-running operations.

3. **Improved Security**: More robust authentication and authorization with different access levels may be needed as the service grows.