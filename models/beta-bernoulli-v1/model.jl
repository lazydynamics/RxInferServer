using RxInfer

@model function beta_bernoulli(prior_a, prior_b, observations)
    p ~ Beta(prior_a, prior_b)
    for i in eachindex(observations)
        observations[i] ~ Bernoulli(p)
    end
end

function inference(arguments, data)
    prior_a = arguments["prior_a"]
    prior_b = arguments["prior_b"]
    observations = data["observations"]
    results = infer(model = beta_bernoulli(prior_a, prior_b), data = (observations = observations,))
    return Dict("p" => results.posteriors[:p])
end

function initial_state(arguments)
    # This model does not require any initial state
    return nothing
end
