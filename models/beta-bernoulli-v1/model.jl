using RxInfer

@model function beta_bernoulli(a, b, observations)
    p ~ Beta(a, b)
    for i in eachindex(observations)
        observations[i] ~ Bernoulli(p)
    end
end

function initial_state(arguments)
    # Number of infer calls is used to track the number of times the model has been inferred
    # This is used mostly for the testing purposes
    return Dict(
        "prior_a" => arguments["prior_a"],
        "prior_b" => arguments["prior_b"],
        "posterior_a" => arguments["prior_a"],
        "posterior_b" => arguments["prior_b"],
        "number_of_infer_calls" => 0
    )
end

function run_inference(state, data)
    a = state["posterior_a"]
    b = state["posterior_b"]
    observations = [data["observation"]]
    results = infer(model = beta_bernoulli(a = a, b = b), data = (observations = observations,))
    state["number_of_infer_calls"] += 1

    return_result = Dict(
        "mean_p" => mean(results.posteriors[:p]), "number_of_infer_calls" => state["number_of_infer_calls"]
    )
    return_state = state

    return return_result, return_state
end

function run_learning(state, parameters, events)
    @debug "Running learning" state parameters events

    observations = [event["data"]["observation"] for event in events]
    results = infer(
        model = beta_bernoulli(a = state["prior_a"], b = state["prior_b"]), data = (observations = observations,)
    )

    (a, b) = params(results.posteriors[:p])

    state["posterior_a"] = a
    state["posterior_b"] = b

    learning_result = Dict("posterior_a" => state["posterior_a"], "posterior_b" => state["posterior_b"])
    return_state = state

    return learning_result, return_state
end
