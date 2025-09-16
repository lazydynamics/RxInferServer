using RxInfer, LinearAlgebra

function create_feature_functions_1(x_dim)
    linear = [(x) -> getindex(x, i) for i in 1:x_dim]
    quadratic = [(x) -> getindex(x, i)^2 for i in 1:x_dim]
    pairwise = [(x) -> getindex(x, i - 1) * getindex(x, i) for i in 2:x_dim]
    tripplewise = [(x) -> getindex(x, i - 2) * getindex(x, i - 1) * getindex(x, i) for i in 3:x_dim]
    return vcat(linear, quadratic, pairwise, tripplewise)
end

@model function feature_regression_unknown_noise(ϕs, x, y)
    # Prior distribution over parameters ω
    ω ~ Uninformative()

    # Prior distribution over noise precision s
    s ~ Uninformative()

    if length(x) != length(y)
        throw(DimensionMismatch("x and y must have the same length"))
    end

    M = length(x)

    for i in 1:M
        ϕx = [ϕ(x[i]) for ϕ in ϕs]
        y[i] ~ Normal(mean = dot(ϕx, ω), precision = s)
    end
end

@model function feature_regression_predictive(ϕs, x, y, priors)
    ω ~ priors[:ω]
    s ~ priors[:s]
    ϕx = [ϕ(x) for ϕ in ϕs]
    y ~ Normal(mean = dot(ϕx, ω), precision = s)
end

function initial_state(arguments)
    return Dict{String, Any}("number_of_iterations" => arguments["number_of_iterations"])
end

function initial_parameters(arguments)
    return Dict{String, Any}(
        "omega_mean" => nothing, "omega_covariance" => nothing, "noise_shape" => nothing, "noise_scale" => nothing
    )
end

function run_inference(state, parameters, data)
    @debug "Running inference in FeatureDiscovery-v1 model" state parameters data

    x = Float64.(data["x"])
    phi_s = create_feature_functions_1(length(x))

    omega_distribution = MvNormalMeanCovariance(parameters["omega_mean"], parameters["omega_covariance"])
    noise_distribution = GammaShapeScale(parameters["noise_shape"], parameters["noise_scale"])

    priors = Dict(:ω => omega_distribution, :s => noise_distribution)

    # Create initialization for the inference
    init = @initialization begin
        μ(ω) = MvNormalMeanCovariance(parameters["omega_mean"], parameters["omega_covariance"])
        q(s) = GammaShapeScale(parameters["noise_shape"], parameters["noise_scale"])
    end

    inference_results = infer(
        model = feature_regression_predictive(ϕs = phi_s, priors = priors),
        data = (x = x, y = missing),
        predictvars = (y = KeepLast(),),
        initialization = init,
        iterations = state["number_of_iterations"],
        constraints = MeanField()
    )

    result = Dict(
        "y_mean" => mean(inference_results.predictions[:y]), "y_variance" => var(inference_results.predictions[:y])
    )

    return result, state
end

function run_learning(state, parameters, events)
    @debug "Running inference in FeatureDiscovery-v1 model" state parameters events

    x = convert(Vector{Vector{Float64}}, [convert(Vector{Float64}, event["data"]["x"]) for event in events])
    y = convert(Vector{Float64}, [convert(Float64, event["data"]["y"]) for event in events])

    x_dim = length(x[1])
    phi_s = create_feature_functions_1(x_dim)
    phi_dim = length(phi_s)

    parameters["omega_mean"] = zeros(phi_dim)
    parameters["omega_covariance"] = 1e6 * Diagonal(ones(phi_dim))
    parameters["noise_shape"] = 1e-12
    parameters["noise_scale"] = 1e8

    # Create initialization for the inference
    init = @initialization begin
        μ(ω) = MvNormalMeanCovariance(parameters["omega_mean"], parameters["omega_covariance"])
        q(s) = GammaShapeScale(parameters["noise_shape"], parameters["noise_scale"])
    end

    inference_results = infer(
        model = feature_regression_unknown_noise(ϕs = phi_s),
        data = (x = x, y = y),
        initialization = init,
        returnvars = (ω = KeepLast(), s = KeepLast()),
        iterations = state["number_of_iterations"],
        constraints = MeanField(),
        options = (limit_stack_depth = 300,)
    )

    parameters = Dict(
        "omega_mean" => mean(inference_results.posteriors[:ω]),
        "omega_covariance" => cov(inference_results.posteriors[:ω]),
        "noise_shape" => shape(inference_results.posteriors[:s]),
        "noise_scale" => scale(inference_results.posteriors[:s])
    )

    result = Dict(
        "omega_mean" => parameters["omega_mean"],
        "omega_covariance" => parameters["omega_covariance"],
        "noise_shape" => parameters["noise_shape"],
        "noise_scale" => parameters["noise_scale"]
    )

    return result, state, parameters
end
