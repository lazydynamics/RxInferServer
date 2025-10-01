# Inference vs Learning: Understanding the Difference

This guide explains the fundamental difference between inference and learning calls in RxInferServer, using the Beta-Bernoulli model as a practical example. Understanding this distinction is crucial for building effective continual learning systems.

## The Core Concept

In RxInferServer, **inference** and **learning** serve different purposes:

- **Inference**: Provides immediate predictions using current model parameters, but doesn't update them
- **Learning**: Processes accumulated data and permanently updates the model's parameters

## Prerequisites

Before using the Learning API, you need a valid authentication token. If you haven't obtained one yet, please refer to the [Authentication](@ref authentication-api) guide.

```@setup inference-vs-learning
import RxInferClientOpenAPI
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: AuthenticationApi, token_generate, basepath
using Test

api          = AuthenticationApi(Client(basepath(AuthenticationApi)))
response, _  = token_generate(api)
@test !isnothing(response)
token = response.token
```

```@example inference-vs-learning
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: ModelsApi

client = Client(basepath(ModelsApi); headers = Dict(
    "Authorization" => "Bearer $token"
))

api = ModelsApi(client)
nothing #hide
```

## Setting Up the Example

Let's create a Beta-Bernoulli model to track the success rate of a feature. We'll start with a uniform prior (α=1, β=1) and observe how inference and learning interact.

```@example inference-vs-learning
import RxInferClientOpenAPI: create_model_instance, CreateModelInstanceRequest

request = CreateModelInstanceRequest(
    model_name = "BetaBernoulli-v1",
    description = "Understanding inference vs learning",
    arguments = Dict("prior_a" => 1, "prior_b" => 1)
)

response, _ = create_model_instance(api, request)
@test !isnothing(response) #hide
instance_id = response.instance_id
```

## Initial Learning Phase

First, let's load some data and learn from it:

```@example inference-vs-learning
import RxInferClientOpenAPI: attach_events_to_episode, AttachEventsToEpisodeRequest, LearnRequest, run_learning

# Load initial data: 8 successes out of 10 trials
initial_data = [1, 1, 0, 1, 1, 1, 0, 1, 1, 1]
events = [Dict("data" => Dict("observation" => obs)) for obs in initial_data]

attach_request = AttachEventsToEpisodeRequest(events = events)
attach_response, _ = attach_events_to_episode(api, instance_id, "default", attach_request)
@test !isnothing(attach_response) #hide
attach_response
```

```@example inference-vs-learning
# Learn from the initial data
learn_request = LearnRequest(episodes = ["default"])
learn_response, _ = run_learning(api, instance_id, learn_request)
@test !isnothing(learn_response) #hide
@test learn_response.learned_parameters["posterior_a"] == 9 #hide
@test learn_response.learned_parameters["posterior_b"] == 3 #hide
learn_response
```

After learning, our model has updated parameters: α=9, β=3 (1+8 successes, 1+2 failures).

## The Inference vs Learning Distinction

Now let's demonstrate the key difference. We'll make multiple inference calls and observe that the model parameters don't change until we explicitly call learning.

### Making Inference Calls

```@example inference-vs-learning
import RxInferClientOpenAPI: InferRequest, run_inference

# First inference call
inference_request = InferRequest(data = Dict("observation" => 1))
inference_response, _ = run_inference(api, instance_id, inference_request)
@test !isnothing(inference_response) #hide
inference_response
```

```@example inference-vs-learning
# Second inference call with the same observation
inference_response, _ = run_inference(api, instance_id, inference_request)
@test !isnothing(inference_response) #hide
inference_response
```

Notice that both inference calls return the same result: mean_p ≈ 0.565. This is because **inference doesn't update the model parameters** - it uses the current parameters (α=9, β=3) to make predictions.

### Unprocessed Events

We can verify that certain events are not processed yet:

```@example inference-vs-learning
import RxInferClientOpenAPI: get_episode_info

episode_info, _ = get_episode_info(api, instance_id, "default")
@test !isnothing(episode_info) #hide
episode_info.events
```

```@example inference-vs-learning
unprocessed_events = filter(episode_info.events) do event
    return !get(event, "processed", false)
end
@test length(unprocessed_events) == 2 #hide
unprocessed_events
```

### The Learning Step

If we call learning now, it will use only the unprocessed events and the previously learned parameters to learn the new parameters. Now let's call learning to process to demonstrate this:

```@example inference-vs-learning
# Learn from the accumulated inference events
learn_request = LearnRequest(episodes = ["default"])
learn_response, _ = run_learning(api, instance_id, learn_request)
@test !isnothing(learn_response) #hide
learn_response
```

After learning, the parameters have updated to α=11, β=3 (9+2 successes, 3+0 failures). The two inference calls with observation=1 have been processed now. 

```@example inference-vs-learning
episode_info, _ = get_episode_info(api, instance_id, "default")
@test !isnothing(episode_info) #hide
episode_info.events
```

```@example inference-vs-learning
unprocessed_events = filter(episode_info.events) do event
    return !get(event, "processed", false)
end
@test length(unprocessed_events) == 0 #hide
unprocessed_events
```

### Inference After Learning

```@example inference-vs-learning
# Inference after learning - now uses updated parameters
inference_response, _ = run_inference(api, instance_id, inference_request)
@test !isnothing(inference_response) #hide
inference_response
```

Now the inference uses the updated parameters (α=11, β=3), resulting in mean_p ≈ 0.571.

## Key Insights

### 1. **Inference is Non-Persistent**
- Inference calls don't update the model's learned parameters
- Each inference call uses the current parameters as the prior

### 2. **Learning is Persistent**
- Learning processes all unprocessed events and updates parameters
- Changes are permanent and affect future inference calls
- Enables efficient batch processing of accumulated data

### 3. **The Workflow**
```
Data → Inference (immediate feedback) → Learning (persistent update) → Inference (updated feedback)
```

## Practical Applications

This design pattern is particularly useful for:

- **Real-time Systems**: Get immediate predictions while batching updates
- **Streaming Data**: Process data as it arrives, update models periodically
- **Resource Management**: Control when computationally expensive learning occurs
- **Continual Learning**: Efficiently update models with new information

## Cleaning Up

```@example inference-vs-learning
import RxInferClientOpenAPI: delete_model_instance

response, _ = delete_model_instance(api, instance_id)
@test !isnothing(response) #hide
response
```

## Summary

Understanding the difference between inference and learning is crucial for building effective continual learning systems. Inference provides immediate feedback using current parameters, while learning processes accumulated data and permanently updates the model. This separation allows for both real-time predictions and efficient batch learning, making it ideal for streaming data scenarios.
