# Design proposal

This is a new design proposal for the API of the model server. The current API is different and we can discuss how to integrate both of them.

## Creation of the model instance

The central to the API would be to create an endpoint for a single model _instance_.
An _instance_ would be defined as an isolated run-time environment for a specific model. It would be identified by a unique id.
Two instances of the same model can be run in parallel and do not interfere with each other (unless they are explicitly designed to communicate with each other).

The API endpoint would looks something like this:
```
POST /api/create-model
```

### Request structure 

```json
{
  "model": "drone-v1",                    // (required)
  "description": "Drone model (testing)", // (optional)
  "arguments": { // (optional)
    "dt": 0.1,
    "horizon": 10,
  }
}
```

Request arguments:
- `model`: (required) The name of the model to create.
- `description`: (optional) A description of the model. Can be used to identify/find the model later.
- `arguments`: (optional) A dictionary of arguments that will be passed to the model.

In the beginning we will be required to craft these models manually. This proposal does not allow users to define their own models. Thus, the `model` requires to be a valid model name, e.g. `drone-v1`, `ar`, `rslds`, `hmm`. A model also specifies the layout of the data that can be sent to the model as well as the parameters of the model that can be learned and actions that can be taken. The model also defines the set of fixed arguments that might be modified, e.g. `dt` or `horizon`. Those arguments are not learned by the model, but might be overwritten for a specific `infer` call. All of this information must be explicitly documented by a model designer (us in the beginning).

!!! note
    Do not confuse the `arguments` with the `parameters`. The `arguments` are the arguments that are passed to the model and are fixed for a single `infer` call. The `parameters` are the parameters that are learned by the model and are updated by the `/api/learn` endpoint.

### Response structure

#### Success

Upon success, the response will be a JSON object with the following structure:

```json
{
  "model_id": "123e4567-e89b-12d3-a456-426614174000",
}
```

A user will now be able to use this `model_id` to send data to the model, plan actions or execute the learning.

#### Error

Upon error, the response will be a JSON object with the following structure:

```json
{
  "error_code": "MODEL_NOT_FOUND",
  "error_description": "The model does not exist."
}
```

Possible error codes:
```
MODEL_NOT_FOUND - The model does not exist
```

## Running inference in the model instance

```
POST /api/infer
```

### Request structure

```json
{
    "model_id": "123e4567-e89b-12d3-a456-426614174000",
    "observation": {
        "y": [4, 5, 6]
    }, 
    "goal": {
        "y[end]": [ 5, 6, 7 ] // to discuss
    },
    "timestamp": 1234567890, // required
    "episode_id": "default",  // (optional)
    "arguments": { // (optional)
        "horizon": 100,
    }
}
```

Notes:
- The `observation` is a dictionary of the data to be sent to the model as defined in the model schema.
- The `timestamp` field is the timestamp of the data, not the time when the data was received by the server. Certain models assume a certain frequency of the data, e.g. every `dt` seconds. In that case the server will use the `timestamp` to determine the time of the data to order them in time and to determine if any of the data is missing.
- The `episode_id` is the id of the episode to which the data belongs. Can be omitted, `default` is used if not provided.
- The idea of the episode is to group data into chunks, from which the model can learn independently. An agent can also decide to learn from a particular episode only once for efficiency or discard certain episodes if they are too old for example. More on the episodes is below.
- The syntax for the `goal` is to be discussed. E.g. we might want to set multiple goals for the same `observation`. Currently, we usually set a single goal at the end of the episode. Yes, it results in MPC, not real AIF. Real AIF requires more priors on states, actions and states. Bert is currently working on this together with Wouter and other BIASlab members.
- The `arguments` are the arguments that are passed to the model. They are not learned by the model, but might be overwritten for a specific `infer` call.

### Response structure

#### Success

Upon success, the response will be a JSON object with the following structure:

```json
{
    "status": "success",
    "posterior": {
        "u": [0.1, 0.2, 0.3], // or `missing` or a distribution
    }
}
```

The purpose of the `posterior` is to provide the user with a distribution over the actions that can be taken. The user can then use this distribution to take an action or to sample an action.

#### Error

Upon error, the response will be a JSON object with the following structure:

```json
{
  "error_code": "MODEL_NOT_FOUND",
  "error_description": "The model does not exist."
}
```

Possible error codes:
```
MODEL_NOT_FOUND             - The model does not exist.
DATA_NOT_FOUND              - The data is missing in the request.
DATA_INCOMPLETE             - The data is incomplete (missing required fields).
DATA_LAYOUT_NOT_COMPATIBLE  - The data layout is not compatible with the model schema (wrong keys, wrong types, etc.).
DATA_NOT_VALID              - The data is not valid (e.g. `NaN`, `Inf` or negative values where positive values are expected).
```


## Learning model's parameters

A model can have parameters that can be learned from data. For example state transition matrices can be learned. Or observational noise can be learned. Those are specified in the model's schema. During the `infer` call most of the model's parameters are fixed and not updated. The `/api/learn` endpoint is used specifically to update the parameters of the model based on the data saved in the episodes.

!!! note
    Do not confuse the `arguments` with the `parameters`. The `arguments` are the arguments that are passed to the model and are fixed for a single `infer` call. The `parameters` are the parameters that are learned by the model and are updated by the `/api/learn` endpoint.

```
POST /api/learn
```

### Request structure

```json
{ 
    "model_id": "123e4567-e89b-12d3-a456-426614174000",
    "episode_ids": ["default", "episode2", "episode3"], // (optional)
    "relearn_episodes": false, // (optional),
    "parameters": [ "A", "B", "C" ] // (optional)
}
```

The idea of the `episode_ids` is to specify the episodes to learn from. If not provided, all episodes will be used. By default, if a model learned from a particular episode, it will not be used again unless the `relearn_episodes` flag is set to `true`. Or if the episode has new data it will be used again, but only the portion of the episode that has not been learned yet. Basically each episode should track whenever it has been used for learning or not. Which data has been used for learning or not. And what was the outcome of the learning.

An example of how it might work:

- Suppose we have episode with id "episode1" and it has 1000 data points and it hasn't been used for learning yet.
- The server receives the `/api/learn` request with `episode_ids` set to `["episode1"]`.
- The server uses the data saved in the episode "episode1" to learn new posteriors over the parameters of the model and saves it. It also saves the fact that it has been used for learning and it saves that exactly `1000` data points have been used for learning.
- The server progress forward in time and receives new data into the episode "episode1".
- The server receives the `/api/learn` request with `episode_ids` set to `["episode1"]`.
- The server has already learned from the first 1000 data points, so it will only learn from the new data.
- To do that it uses previously learned posteriors as a prior and learns the new posteriors using the new data only.
- The server progresses forward in time and receives new data into the episode "episode1".
- The server receives the `/api/learn` request with `episode_ids` set to `["episode1"]` and `relearn_episodes` set to `true`.
- The server will discard previously learned posteriors and will learn from all the data saved in the episode "episode1" again.

What to do with multiple episodes?

- The server learns from episode with id "episode1" and gets "posterior1".
- The server learns from episode with id "episode2" and gets "posterior2".
- The server learns from episode with id "episode3" and gets "posterior3".
- The server can now compute the product of all the posteriors and get the final posterior.

### Response structure

#### Success

Upon success, the response will be a JSON object with the following structure:

```json
{
    "status": "success"
}
```

After that all next invocations of the `/api/infer` endpoint will use the new posteriors for the learned parameters.

#### Error

Upon error, the response will be a JSON object with the following structure:

```json
{
    "error": "Model not found"
}
```

Possible errors:
```
MODEL_NOT_FOUND - The model does not exist.
```

## Additional API Endpoints

The following additional endpoints would complete the CRUD (Create, Read, Update, Delete) operations for models:

### List Models

```
GET /api/models
```

#### Request Parameters (Query String)
- `limit`: (optional) Maximum number of models to return
- `status`: (optional) Filter by model status (e.g., "active", "learning", "error")

#### Response Structure

```json
{
  "models": [
    {
      "model_id": "123e4567-e89b-12d3-a456-426614174000",
      "model": "drone-v1",
      "description": "Drone model (testing)",
      "created_at": "2023-04-01T12:00:00Z",
      "status": "active",
      "episode_count": 2
    },
    {
      "model_id": "456e4567-e89b-12d3-a456-426614174001",
      "model": "ar",
      "description": "Autoregressive model",
      "created_at": "2023-04-02T14:30:00Z",
      "status": "active",
      "episode_count": 5
    }
  ],
  "total": 2,
}
```

### Get Model Details

```
GET /api/models/{model_id}
```

#### Response Structure

```json
{
  "model_id": "123e4567-e89b-12d3-a456-426614174000",
  "model": "drone-v1",
  "description": "Drone model (testing)",
  "created_at": "2023-04-01T12:00:00Z",
  "status": "active",
  "arguments": {
    "dt": 0.1,
    "horizon": 10
  },
  "parameters": {
    "A": {"learned": true, "last_updated": "2023-04-01T14:20:00Z"},
    "B": {"learned": true, "last_updated": "2023-04-01T14:20:00Z"},
    "C": {"learned": false}
  },
  "episodes": [
    {
      "episode_id": "default",
      "data_points": 120,
      "learned_points": 100,
      "last_updated": "2023-04-01T13:45:00Z"
    },
    {
      "episode_id": "episode2",
      "data_points": 85,
      "learned_points": 0,
      "last_updated": "2023-04-01T14:10:00Z"
    }
  ]
}
```

### Delete Model

```
DELETE /api/models/{model_id}
```

#### Response Structure

```json
{
  "status": "success",
  "message": "Model deleted successfully"
}
```

### List Episodes for a Model

```
GET /api/models/{model_id}/episodes
```

#### Response Structure

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
    },
    {
      "episode_id": "episode2",
      "data_points": 85,
      "learned_points": 0,
      "start_timestamp": 1234569800,
      "end_timestamp": 1234570800,
      "last_updated": "2023-04-01T14:10:00Z"
    }
  ],
  "total": 2
}
```

## API Versioning

To ensure backward compatibility as the API evolves, all endpoints should be versioned. This can be implemented in two ways:

1. **URL Path Versioning**: Prefix all endpoints with a version identifier:
   ```
   /v1/api/create-model
   /v1/api/infer
   /v1/api/learn
   ```

2. **Header-Based Versioning**: Use an HTTP header to specify the API version:
   ```
   API-Version: 1.0
   ```

The recommended approach is URL path versioning as it's more explicit and easier to debug.

## Implementational details 

To support this I think we need to be able to define models in the way such that it accepts an argument `N` that specifies the number of time steps that the model will be created with. In the `infer` call the `N` will be set to `horizon+1`, the very first state will be the current state with the attached observation and the rest will be pure imagination based on the currently learned parameters into the future where we set goals at the end and create MPC control-like behavior. In the `learn` call the `N` will be set to the number of data points in a particular episode and all data will be used in a smoothing regime to learn the parameters.

TLDR:
- `infer`: parameters are point masses -> infer actions with horizon `N`
- `learn`: observations and actions are point masses from `N` data points -> learn parameters

Both of this requires a model _at least_ in the form of:

```julia
@model function some_model(N, arguments, ...)
  # ...
  # arguments[:dt]
end
```

!!! question 
    To learn the parameter we need to have both data and the action taken! We then need to also save the action taked in the database.

## Error Handling

All API endpoints should return consistent error responses with the following structure:

```json
{
  "error_code": "ERROR_CODE",
  "error_description": "Human-readable error description",
  "request_id": "unique-request-identifier",
  "additional_info": {
    // Optional additional information about the error
  }
}
```

Standard HTTP status codes should be used appropriately:
- 200: Success
- 400: Bad Request (client error)
- 404: Not Found
- 409: Conflict
- 500: Internal Server Error

### Common Error Codes
In addition to the endpoint-specific error codes mentioned earlier, these common error codes should be used across all endpoints:

```
INVALID_REQUEST         - The request is malformed
UNAUTHORIZED            - The request lacks proper authentication
RATE_LIMIT_EXCEEDED     - Too many requests in a given time period
SERVER_ERROR            - Unexpected server error
UNSUPPORTED_API_VERSION - The requested API version is not supported
```

## Security and Robustness

### Authentication and Authorization

The API should implement proper authentication and authorization mechanisms:

#### API Keys

```
Authorization: Bearer <api_key>
```

All API endpoints should require an API key for authentication. Different access levels can be implemented:
- **Read-only**: Can only access `/api/infer` endpoints
- **Standard**: Can access both `/api/infer` and `/api/learn` endpoints
- **Admin**: Can access all endpoints including create and delete operations

#### (For future) Rate Limiting 

To prevent abuse and ensure fair usage, rate limiting should be implemented:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1617192000
```

When rate limits are exceeded, return a 429 Too Many Requests status code:

```json
{
  "error_code": "RATE_LIMIT_EXCEEDED",
  "error_description": "Rate limit exceeded. Try again in 60 seconds.",
  "request_id": "req-123",
  "additional_info": {
    "reset_at": 1617192000
  }
}
```

### Asynchronous Operations

For long-running operations like learning from large datasets, asynchronous processing should be supported:

#### Asynchronous Learning

```
POST /api/async/learn
```

##### Request Structure
Identical to the synchronous `/api/learn` endpoint.

##### Response Structure

```json
{
  "job_id": "job-567890",
  "status": "processing",
  "estimated_completion": "2023-04-01T13:30:00Z"
}
```

#### Check Job Status

```
GET /api/jobs/{job_id}
```

##### Response Structure

```json
{
  "job_id": "job-567890",
  "status": "completed", // or "processing", "failed"
  "progress": 100,
  "result": {
    // Job-specific result data, if completed
  },
  "error": {
    // Error information if status is "failed"
  }
}
```

### Logging and Monitoring

All API operations should be logged for monitoring and debugging:

1. **Request Logging**: Log all incoming requests and their parameters
2. **Performance Metrics**: Track execution time for all operations
3. **Error Tracking**: Record all errors with stack traces
4. **Resource Usage**: Monitor memory and CPU usage per model instance

A separate monitoring endpoint should expose these metrics:

```
GET /api/metrics
```

## Model Schema Documentation and Discovery

To make the API self-documenting and easier to use, endpoints should be provided to discover available models and their schemas:

### List Available Model Types

```
GET /api/model-types
```

#### Response Structure

```json
{
  "model_types": [
    {
      "name": "drone-v1",
      "description": "Dynamical model of a drone",
      "schema_url": "/api/model-types/drone-v1/schema",
      "created_at": "2023-01-15T00:00:00Z",
      "category": "robotics"
    },
    {
      "name": "ar",
      "description": "Autoregressive model",
      "schema_url": "/api/model-types/ar/schema",
      "created_at": "2023-01-10T00:00:00Z",
      "category": "time-series"
    }
  ]
}
```

### Get Model Type Schema

```
GET /api/model-types/{model_name}/schema
```

#### Response Structure

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

## Improved Data Handling

### Action Storage

!!! note
    This is to discuss!

As noted in the original question, both observations and actions need to be stored to properly learn model parameters. The `/api/infer` endpoint should be enhanced to allow storing the actions that were actually taken:

```
POST /api/store-action
```

#### Request Structure

```json
{
  "model_id": "123e4567-e89b-12d3-a456-426614174000",
  "timestamp": 1234567890,
  "episode_id": "default",
  "action": {
    "u": [0.1, 0.2, 0.3]
  }
}
```

#### Response Structure

```json
{
  "status": "success"
}
```

### Data Validation

More comprehensive data validation should be implemented:

1. **Type Validation**: Ensure all data matches the expected types
2. **Range Validation**: Verify that values fall within acceptable ranges
3. **Dimension Validation**: Check that arrays/matrices have the correct dimensions
4. **Missing Data Handling**: Define behavior for missing data points
5. **Outlier Detection**: Flag potential outliers for review

Data validation errors should return detailed information:

```json
{
  "error_code": "DATA_NOT_VALID",
  "error_description": "Data validation failed",
  "request_id": "req-123",
  "additional_info": {
    "validation_errors": [
      {
        "field": "observation.y[2]",
        "error": "Value out of range",
        "details": "Expected range: [-10, 10], Got: 15"
      }
    ]
  }
}
```

### Time Series Interpolation

!!! note
    This is to discuss! I propose to do simple interpolation for now to what the model needs. Less relevant for discrete models & environments.

For handling irregularly-sampled time series data:

1. **Gap Detection**: Identify gaps in timestamp sequences
2. **Interpolation**: Optionally interpolate missing data points
3. **Configurable Policies**: Allow configuration of how missing data is handled

#### Authentication

In the beginning we simply provide an API endpoint to generate a new API key.

```
POST /api/generate-api-key
```

Returns a new API key.

```json
{
  "api_key": "your-new-api-key"
}
```

## Client Libraries

To simplify integration with the model server, client libraries should be provided for common programming languages:

```python
# Python example
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

```julia
# Julia example
using RxInferServer

# Create client
client = RxInferServer.create_client(api_key="your-api-key")

# Create model
model = create_model(client, "drone-v1", 
                   description="Drone control model",
                   arguments=Dict("dt" => 0.1, "horizon" => 10))

# Run inference
posterior = infer(model, 
                observation=Dict("y" => [4, 5, 6]), 
                goal=Dict("y[end]" => [5, 6, 7]),
                timestamp=1234567890)

# Get action
action = sample(posterior)

# Store action
store_action(model, action=Dict("u" => action), timestamp=1234567890)

# Learn parameters
learn(model)
```

## Representation of Distributions and Uncertainty

Since RxInfer works with probabilistic models, it's essential to represent distributions and uncertainty properly in the API responses.

### Distribution Formats

The API should support multiple formats for representing distributions:

#### Format 1: Normal Distribution

```json
{
  "distribution_type": "NormalMeanVariance",
  "mean": [1.5, 2.3, 0.7],
  "variance": [0.1, 0.2, 0.15]
}
```

#### Format 2: Multivariate Normal Distribution

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

#### Format 3: Samples from Posterior

```json
{
  "distribution_type": "SampleList",
  "samples": [
    [1.42, 2.31, 0.68],
    [1.51, 2.33, 0.71],
    [1.49, 2.28, 0.72],
    [1.53, 2.35, 0.69],
    [1.48, 2.29, 0.73]
  ],
  "weights": [0.2, 0.2, 0.2, 0.2, 0.2]  // Optional, uniform if not provided
}
```

#### Format 4: Discrete Distribution

```json
{
  "distribution_type": "Categorical",
  "probabilities": [0.2, 0.5, 0.3]
}
```

#### Format 5: Custom Distribution Parameters

```json
{
  "distribution_type": "Beta",
  "parameters": {
    "alpha": 2.1,
    "beta": 3.5
  }
}
```