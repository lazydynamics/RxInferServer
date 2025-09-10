using RxInfer

@model function linear_regression_unknown_noise(x, y)
    a ~ Normal(mean = 0.0, variance = 1.0)
    b ~ Normal(mean = 0.0, variance = 100.0)
    s ~ InverseGamma(1.0, 1.0)
    y .~ Normal(mean = a .* x .+ b, variance = s)
end

@model function linear_regression_predictive(x, y, priors)
    a ~ priors[:a]
    b ~ priors[:b]
    s ~ priors[:s]
    y .~ Normal(mean = a .* x .+ b, variance = s)
end

function initial_state(arguments)
    return Dict("number_of_iterations" => arguments["number_of_iterations"])
end

function initial_parameters(arguments)
    return Dict(
        "a_mean" => 0.0,
        "a_variance" => 100.0,
        "b_mean" => 0.0,
        "b_variance" => 100.0,
        "noise_shape" => 2.0,
        "noise_scale" => 1e6
    )
end

function run_inference(state, parameters, data)
    @debug "Running inference in LinearRegression-v1 model" state parameters data

    x = Float64.(data["x"])

    a_distribution = NormalMeanVariance(parameters["a_mean"], parameters["a_variance"])
    b_distribution = NormalMeanVariance(parameters["b_mean"], parameters["b_variance"])
    noise_distribution = InverseGamma(parameters["noise_shape"], parameters["noise_scale"])

    priors = Dict(:a => a_distribution, :b => b_distribution, :s => noise_distribution)

    # Create initialization for the inference
    init = @initialization begin
        μ(b) = NormalMeanVariance(parameters["b_mean"], parameters["b_variance"])
        q(s) = InverseGamma(parameters["noise_shape"], parameters["noise_scale"])
    end

    inference_results = infer(
        model = linear_regression_predictive(priors = priors),
        data = (x = x, y = [missing for _ in 1:length(x)]),
        predictvars = (y = KeepLast(),),
        initialization = init,
        iterations = state["number_of_iterations"],
        constraints = MeanField()
    )

    result = Dict(
        "y_mean" => mean.(inference_results.predictions[:y]), "y_variance" => var.(inference_results.predictions[:y])
    )

    return result, state
end

function run_learning(state, parameters, events)
    @debug "Running inference in LinearRegression-v1 model" state parameters events

    x = Float64.([event["data"]["x"] for event in events])
    y = Float64.([event["data"]["y"] for event in events])

    # Create initialization for the inference
    init = @initialization begin
        μ(b) = NormalMeanVariance(parameters["b_mean"], parameters["b_variance"])
        q(s) = InverseGamma(parameters["noise_shape"], parameters["noise_scale"])
    end

    inference_results = infer(
        model = linear_regression_unknown_noise(),
        data = (x = x, y = y),
        initialization = init,
        returnvars = (a = KeepLast(), b = KeepLast(), s = KeepLast()),
        iterations = state["number_of_iterations"],
        constraints = MeanField(),
        options = (limit_stack_depth = 300,)
    )

    parameters = Dict(
        "a_mean" => mean(inference_results.posteriors[:a]),
        "a_variance" => var(inference_results.posteriors[:a]),
        "b_mean" => mean(inference_results.posteriors[:b]),
        "b_variance" => var(inference_results.posteriors[:b]),
        "noise_shape" => shape(inference_results.posteriors[:s]),
        "noise_scale" => scale(inference_results.posteriors[:s])
    )

    result = Dict(
        "a_mean" => parameters["a_mean"],
        "a_variance" => parameters["a_variance"],
        "b_mean" => parameters["b_mean"],
        "b_variance" => parameters["b_variance"],
        "noise_shape" => parameters["noise_shape"],
        "noise_scale" => parameters["noise_scale"]
    )

    return result, state, parameters
end
