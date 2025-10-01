# Continual Learning 

This guide demonstrates how to use continual learning with the Beta-Bernoulli model to track the probability of success in a series of Bernoulli trials. We'll follow a story of a data scientist monitoring the success rate of a new feature rollout, showing how the model's beliefs evolve as more data arrives.

## The Scenario: Feature Rollout Monitoring

Imagine you're a data scientist at a tech company monitoring the success rate of a new feature. Each user interaction with the feature is a Bernoulli trial - either successful (1) or unsuccessful (0). You want to track how the success probability evolves over time as more users interact with the feature.

## Prerequisites

Before using the Learning API, you need a valid authentication token. If you haven't obtained one yet, please refer to the [Authentication](@ref authentication-api) guide.

```@setup continual-learning-beta-bernoulli
import RxInferClientOpenAPI
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: AuthenticationApi, token_generate, basepath
using Test

api          = AuthenticationApi(Client(basepath(AuthenticationApi)))
response, _  = token_generate(api)
@test !isnothing(response)
token = response.token

using Plots
```

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI.OpenAPI.Clients: Client
import RxInferClientOpenAPI: ModelsApi

client = Client(basepath(ModelsApi); headers = Dict(
    "Authorization" => "Bearer $token"
))

api = ModelsApi(client)
nothing #hide
```

## Creating the Model Instance

We'll create a Beta-Bernoulli model with a uniform prior (α=1, β=1), representing no prior knowledge about the success probability.

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: create_model_instance, CreateModelInstanceRequest

request = CreateModelInstanceRequest(
    model_name = "BetaBernoulli-v1",
    description = "Monitoring feature success rate",
    arguments = Dict("prior_a" => 1, "prior_b" => 1)
)

response, _ = create_model_instance(api, request)
@test !isnothing(response) #hide
instance_id = response.instance_id
```

## Phase 1: Initial Data Collection

Let's simulate the first week of data collection. We observe 20 user interactions with our new feature, where 15 are successful and 5 are unsuccessful.

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: attach_events_to_episode, AttachEventsToEpisodeRequest

# Simulate first week data: 15 successes out of 20 trials
first_week_data = [1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0]

events = [Dict("data" => Dict("observation" => obs)) for obs in first_week_data]

request = AttachEventsToEpisodeRequest(events = events)
response, _ = attach_events_to_episode(api, instance_id, "default", request)
@test !isnothing(response) #hide
response
```

We can verify that the events are not processed yet:

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: get_episode_info

episode_info, _ = get_episode_info(api, instance_id, "default")
@test !isnothing(episode_info) #hide

unprocessed_events = filter(episode_info.events) do event
    return !get(event, "processed", false)
end
@test length(unprocessed_events) == length(first_week_data) #hide
unprocessed_events
```

Now let's learn from this initial data:

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: LearnRequest, run_learning

learn_request = LearnRequest(episodes = ["default"])
learn_response, _ = run_learning(api, instance_id, learn_request)
@test !isnothing(learn_response) #hide
learn_response
```

Let's check the learned parameters and make an inference:

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: get_model_instance_parameters, InferRequest, run_inference

# Get the learned parameters
params_response, _ = get_model_instance_parameters(api, instance_id)
@test !isnothing(params_response) #hide
params_response
```

```@example continual-learning-beta-bernoulli
# Make an inference about the success probability
inference_request = InferRequest(data = Dict("observation" => 1))
inference_response, _ = run_inference(api, instance_id, inference_request)
@test !isnothing(inference_response) #hide
inference_response
```

After the first week, our model estimates the success probability at approximately 75% (15 successes out of 20 trials), with the posterior parameters α=16, β=6.

!!! note
    The inference request adds an event to the episode, so we have one more event than the first week's data.
    ```@example continual-learning-beta-bernoulli
    episode_info, _ = get_episode_info(api, instance_id, "default")
    @test !isnothing(episode_info) #hide
    unprocessed_events = filter(episode_info.events) do event
        return !get(event, "processed", false)
    end
    @test length(unprocessed_events) == 1 #hide
    unprocessed_events
    ```

## Phase 2: Continual Learning with New Data

Now, let's simulate the second week of data. This time, we observe 30 more interactions, with 18 successes and 12 failures. The key insight is that we can add this new data and learn from it without reprocessing the first week's data.

```@example continual-learning-beta-bernoulli
# Simulate second week data: 18 successes out of 30 trials
second_week_data = [1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1]

new_events = [Dict("data" => Dict("observation" => obs)) for obs in second_week_data]

request = AttachEventsToEpisodeRequest(events = new_events)
response, _ = attach_events_to_episode(api, instance_id, "default", request)
@test !isnothing(response) #hide
response
```

We can verify that the events are not processed yet:

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: get_episode_info

episode_info, _ = get_episode_info(api, instance_id, "default")
@test !isnothing(episode_info) #hide

unprocessed_events = filter(episode_info.events) do event
    return !get(event, "processed", false)
end
@test length(unprocessed_events) == length(second_week_data) + 1 #hide
unprocessed_events
```

!!! note 
    Notice that we have one more event than the second week's data because we also have one data point coming from the inference request.

Now let's learn from the new data using continual learning (the default behavior):

```@example continual-learning-beta-bernoulli
learn_request = LearnRequest(episodes = ["default"])  # relearn=false by default
learn_response, _ = run_learning(api, instance_id, learn_request)
@test !isnothing(learn_response) #hide
learn_response
```

Let's check how the parameters have evolved:

```@example continual-learning-beta-bernoulli
params_response, _ = get_model_instance_parameters(api, instance_id)
@test !isnothing(params_response) #hide
params_response
```

```@example continual-learning-beta-bernoulli
# Make another inference
inference_response, _ = run_inference(api, instance_id, inference_request)
@test !isnothing(inference_response) #hide
inference_response
```

After the second week, our model now estimates the success probability at approximately 66% (33 successes out of 50 total trials), with posterior parameters α=34, β=18. Notice how the model efficiently updated its beliefs without reprocessing the first week's data.

## Phase 3: Comparing Learning Modes

Let's demonstrate the difference between incremental learning and relearning by creating a new episode and comparing the results.

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: create_episode, CreateEpisodeRequest

# Create a new episode for comparison
create_episode_request = CreateEpisodeRequest(name = "relearning-experiment")
response, _ = create_episode(api, instance_id, create_episode_request)
@test !isnothing(response) #hide
response
```

```@example continual-learning-beta-bernoulli
# Add all data to the new episode
all_data = [first_week_data; second_week_data]
all_events = [Dict("data" => Dict("observation" => obs)) for obs in all_data]

request = AttachEventsToEpisodeRequest(events = all_events)
response, _ = attach_events_to_episode(api, instance_id, "relearning-experiment", request)
@test !isnothing(response) #hide
response
```

Now let's use relearning mode to process all data from scratch:

```@example continual-learning-beta-bernoulli
learn_request = LearnRequest(episodes = ["relearning-experiment"], relearn = true)
learn_response, _ = run_learning(api, instance_id, learn_request)
@test !isnothing(learn_response) #hide
learn_response
```

```@example continual-learning-beta-bernoulli
# Check the parameters from relearning
import RxInferClientOpenAPI: get_episode_info

episode_info, _ = get_episode_info(api, instance_id, "relearning-experiment")
@test !isnothing(episode_info) #hide
episode_info.parameters
```

Both approaches yield the same final parameters (α=34, β=18), but continual learning is more efficient as it only processes new data.

## Visualizing the Learning Process

Let's create a visualization showing how the posterior distribution evolves:

```@example continual-learning-beta-bernoulli
using Distributions

# Plot the evolution of the posterior distribution
p = plot(title="Evolution of Success Probability Belief", xlabel="Success Probability", ylabel="Density", legend=:topright)

# Initial prior (uniform)
prior = Beta(1, 1)
plot!(p, 0:0.01:1, pdf.(prior, 0:0.01:1), label="Initial Prior (α=1, β=1)", lw=2)

# After first week
posterior1 = Beta(16, 6)
plot!(p, 0:0.01:1, pdf.(posterior1, 0:0.01:1), label="After Week 1 (α=16, β=6)", lw=2)

# After second week (continual learning)
posterior2 = Beta(34, 18)
plot!(p, 0:0.01:1, pdf.(posterior2, 0:0.01:1), label="After Week 2 (α=34, β=18)", lw=2)

# Add vertical lines for the means
vline!(p, [mean(posterior1)], label="Week 1 Mean: $(round(mean(posterior1), digits=3))", linestyle=:dash, color=:blue)
vline!(p, [mean(posterior2)], label="Week 2 Mean: $(round(mean(posterior2), digits=3))", linestyle=:dash, color=:red)

p
```

The plot shows how our belief about the success probability becomes more concentrated as we gather more data, and how the mean shifts from the initial 50% to approximately 66% after observing the actual data.

## Key Benefits of Continual Learning

1. **Efficiency**: Only new data is processed, saving computational resources
2. **Real-time Updates**: Models can be updated as new data arrives
3. **Memory Efficiency**: No need to store and reprocess historical data
4. **Scalability**: Enables learning from streaming data sources

## Cleaning Up

```@example continual-learning-beta-bernoulli
import RxInferClientOpenAPI: delete_episode, delete_model_instance

# Delete the experimental episode
response, _ = delete_episode(api, instance_id, "relearning-experiment")
@test !isnothing(response) #hide
response
```

```@example continual-learning-beta-bernoulli
# Delete the model instance
response, _ = delete_model_instance(api, instance_id)
@test !isnothing(response) #hide
response
```

## Summary

This example demonstrated how continual learning with the Beta-Bernoulli model allows you to:

- Start with a uniform prior and update beliefs as data arrives
- Efficiently process new data without reprocessing historical data
- Track the evolution of posterior distributions over time
- Compare incremental learning with relearning approaches

The Beta-Bernoulli model is particularly well-suited for continual learning because the Beta distribution is a conjugate prior for the Bernoulli likelihood, making updates computationally efficient and mathematically elegant.
