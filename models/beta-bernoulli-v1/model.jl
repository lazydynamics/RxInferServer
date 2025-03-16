using RxInfer

@model function beta_bernoulli(prior_a, prior_b, observations)
    p ~ Beta(prior_a, prior_b)
    for i in eachindex(observations)
        observations[i] ~ Bernoulli(p)
    end
end

function inference(state, data)
    prior_a = state["prior_a"]
    prior_b = state["prior_b"]
    observations = [data["observation"]]
    results = infer(model = beta_bernoulli(prior_a = prior_a, prior_b = prior_b), data = (observations = observations,))
    state["number_of_infer_calls"] += 1
    return Dict("mean_p" => mean(results.posteriors[:p]), "number_of_infer_calls" => state["number_of_infer_calls"]),
    state
end

function initial_state(arguments)
    # Number of infer calls is used to track the number of times the model has been inferred
    # This is used mostly for the testing purposes
    return Dict("prior_a" => arguments["prior_a"], "prior_b" => arguments["prior_b"], "number_of_infer_calls" => 0)
end
