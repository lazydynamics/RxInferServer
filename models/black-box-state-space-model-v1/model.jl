using RxInfer


function initial_state(arguments)
    return Dict(
        "A" => zeros(arguments["state_dimension"], arguments["state_dimension"]),
    )
end

@model function state_space_model_inference(A, horizon, current_state, observation, arguments)

    dim = arguments["state_dimension"]::Int

    s[0] ~ MvNormalMeanCovariance(μ = current_state, Σ = diageye(dim))
    y[0] ~ MvNormalMeanCovariance(μ = s[0], Σ = diageye(dim))

    for t in 1:horizon
        s[t] ~ MvNormalMeanCovariance(μ = A * s[t - 1], Σ = diageye(dim))
        y[t] ~ MvNormalMeanCovariance(μ = s[t], Σ = diageye(dim))
    end

    return y
end