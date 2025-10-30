using RxInfer

@model function dirichlet_categorical(prior_alpha, observations)
    alpha ~ prior_alpha
    for i in eachindex(observations)
        observations[i] ~ Categorical(alpha)
    end
end

function initial_state(arguments)
    return Dict("prior_alpha" => arguments["prior_alpha"], "number_of_infer_calls" => 0)
end

function initial_parameters(arguments)
    return Dict("posterior_alpha" => arguments["prior_alpha"])
end

function run_inference(state, parameters, data)
    @debug "Running inference in Dirichlet-Categorical-v1 model" state parameters data
    alpha_params = convert(Vector{Float64}, parameters["posterior_alpha"])
    inference_results = infer(model = dirichlet_categorical(prior_alpha = Dirichlet(alpha_params)), data = (observations = UnfactorizedData([missing]),))
    state["number_of_infer_calls"] += 1
    result = Dict(
        "predicted_probs" => probvec.(inference_results.predictions[:observations])[1], "number_of_infer_calls" => state["number_of_infer_calls"]
    )

    return result, state
end

function run_learning(state, parameters, events)
    @debug "Running learning in Dirichlet-Categorical-v1 model" state parameters events

    y = Vector{Vector{Float64}}()
    for event in events
        if haskey(event, "data") && haskey(event["data"], "observation")
            push!(y, convert(Vector{Float64}, event["data"]["observation"]))
        end
    end
    if !isempty(y)
        alpha_params = convert(Vector{Float64}, parameters["posterior_alpha"])
        inference_result = infer(model = dirichlet_categorical(prior_alpha = Dirichlet(alpha_params)), data = (observations = y,))
        parameters["posterior_alpha"] = params(inference_result.posteriors[:alpha])[1]
    end

    result = Dict("posterior_alpha" => parameters["posterior_alpha"])
    return result, state, parameters
end
