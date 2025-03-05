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


## How can we use this API?

```python
model = RxInferServer.create_model("drone-v1")
# or model = RxInferServer.create_model("mountain-car-v1")

for i in range(100):
    observation = get_observation()
    goal        = get_goal()
    timestamp   = get_timestamp()
    posterior   = model.infer(observation, goal, timestamp)
    action      = posterior.sample()
    execute(action)

    if i % 10 == 0:
        model.learn()
```

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