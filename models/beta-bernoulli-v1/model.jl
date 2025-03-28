using RxInfer

@model function beta_bernoulli(prior_p, observations)
    p ~ prior_p
    for i in eachindex(observations)
        observations[i] ~ Bernoulli(p)
    end
end

function initial_state(arguments)
    # Number of infer calls is used to track the number of times the model has been inferred
    # This is used mostly for the testing purposes
    return Dict("prior_a" => arguments["prior_a"], "prior_b" => arguments["prior_b"], "number_of_infer_calls" => 0)
end

function initial_parameters(arguments)
    return Dict("posterior_a" => arguments["prior_a"], "posterior_b" => arguments["prior_b"])
end

function run_inference(state, parameters, data)
    @debug "Running inference in Beta-Bernoulli-v1 model" state parameters data

    prior_p = Beta(parameters["posterior_a"], parameters["posterior_b"])
    inference_results = infer(model = beta_bernoulli(prior_p = prior_p), data = (observations = [data["observation"]],))

    state["number_of_infer_calls"] += 1
    result = Dict(
        "mean_p" => mean(inference_results.posteriors[:p]), "number_of_infer_calls" => state["number_of_infer_calls"]
    )

    return result, state
end

function run_learning(state, parameters, events)
    @debug "Running learning in Beta-Bernoulli-v1 model" state parameters events

    # Reset the prior parameters to learn the new posterior from the entire events
    prior_p = Beta(state["prior_a"], state["prior_b"])
    observations = [event["data"]["observation"] for event in events]
    results = infer(model = beta_bernoulli(prior_p = prior_p), data = (observations = observations,))

    parameters["posterior_a"], parameters["posterior_b"] = params(results.posteriors[:p])

    result = Dict("posterior_a" => parameters["posterior_a"], "posterior_b" => parameters["posterior_b"])

    return result, state, parameters
end
