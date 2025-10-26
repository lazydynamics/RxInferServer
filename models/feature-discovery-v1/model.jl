using RxInfer, LinearAlgebra

function linear_functions(x_dim)
    return [(x) -> getindex(x, i) for i in 1:x_dim]
end
function quadratic_functions(x_dim)
    return [(x) -> getindex(x, i)^2 for i in 1:x_dim]
end
function pairwise_functions(x_dim)
    return [(x) -> getindex(x, i - 1) * getindex(x, i) for i in 2:x_dim]
end
function tripplewise_functions(x_dim)
    return [(x) -> getindex(x, i - 2) * getindex(x, i - 1) * getindex(x, i) for i in 3:x_dim]
end

const FUNCTIONS_DISPATCH_TABLE = Dict(
    "linear" => linear_functions,
    "quadratic" => quadratic_functions,
    "pairwise" => pairwise_functions,
    "tripplewise" => tripplewise_functions
)

const MODIFIERS_DISPATCH_TABLE = Dict("tanh" => tanh, "abs" => abs, "sigmoid" => (x) -> inv(one(x) + exp(-x)))

function create_feature_functions(functions, x_dim)
    feature_functions = []
    for fn_specification in functions
        fns = split(fn_specification, ":")

        if isempty(fns)
            throw(ArgumentError("Invalid function specification: $fn_specification"))
        end

        function_name = fns[1]

        if !haskey(FUNCTIONS_DISPATCH_TABLE, function_name)
            throw(ArgumentError("Invalid function name: $function_name"))``
        end

        fn = FUNCTIONS_DISPATCH_TABLE[fns[1]](x_dim)

        if length(fns) >= 2
            # If we have a modifier, we compose it with the original function
            # First apply the original function, then the modifier
            if !haskey(MODIFIERS_DISPATCH_TABLE, fns[2])
                throw(ArgumentError("Invalid modifier name: $fns[2]"))
            end
            # We have an array of functions, so we need to compose the modifier with each function
            fn = map(f -> ComposedFunction(MODIFIERS_DISPATCH_TABLE[fns[2]], f), fn)
        end

        append!(feature_functions, fn)
    end

    return feature_functions
end

@model function feature_regression_unknown_noise(ϕs, x, y, priors)
    ω ~ priors[:ω]
    s ~ priors[:s]

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
    μ := dot(ϕx, ω)
    y ~ Normal(mean = μ, precision = s)
end

@constraints function feature_regressions_predictive_constraints()
    q(μ, s, y) = q(μ, y)q(s)
end

function initial_state(arguments)
    return Dict{String, Any}(
        "functions" => arguments["functions"], "number_of_iterations" => arguments["number_of_iterations"]
    )
end

function initial_parameters(arguments)
    return Dict{String, Any}(
        "omega_mean" => nothing, "omega_covariance" => nothing, "noise_shape" => nothing, "noise_scale" => nothing
    )
end

function run_inference(state, parameters, data)
    @debug "Running inference in FeatureDiscovery-v1 model" state parameters data

    x = Float64.(data["x"])
    phi_s = create_feature_functions(state["functions"], length(x))

    omega_distribution = MvNormalMeanCovariance(parameters["omega_mean"], parameters["omega_covariance"])
    noise_distribution = GammaShapeScale(parameters["noise_shape"], parameters["noise_scale"])

    priors = Dict(:ω => omega_distribution, :s => noise_distribution)

    # Create initialization for the inference
    init = @initialization begin
        μ(ω) = MvNormalMeanCovariance(parameters["omega_mean"], parameters["omega_covariance"])
        q(s) = GammaShapeScale(parameters["noise_shape"], parameters["noise_scale"])
    end

    inference_results = infer(
        model = feature_regression_predictive(ϕs = phi_s, priors = priors, x = x),
        data = (y = UnfactorizedData(missing),),
        predictvars = (y = KeepLast(),),
        initialization = init,
        iterations = state["number_of_iterations"],
        constraints = feature_regressions_predictive_constraints()
    )

    result = Dict(
        "y_mean" => mean(inference_results.predictions[:y]), "y_variance" => var(inference_results.predictions[:y])
    )

    return result, state
end

function run_learning(state, parameters, events)
    @debug "Running inference in FeatureDiscovery-v1 model" state parameters events

    x = Vector{Vector{Float64}}()
    y = Vector{Float64}()

    for event in events
        if haskey(event, "data") && haskey(event["data"], "x") && haskey(event["data"], "y")
            push!(x, convert(Vector{Float64}, event["data"]["x"]))
            push!(y, convert(Float64, event["data"]["y"]))
        end
    end

    if !isempty(x) && !isempty(y)
        x_dim = length(x[1])
        phi_s = create_feature_functions(state["functions"], x_dim)
        phi_dim = length(phi_s)

        omega_mean = @something(parameters["omega_mean"], zeros(phi_dim))
        omega_covariance = @something(parameters["omega_covariance"], 1e6 * Diagonal(ones(phi_dim)))
        noise_shape = @something(parameters["noise_shape"], 1e-12)
        noise_scale = @something(parameters["noise_scale"], 1e8)

        # Create initialization for the inference
        init = @initialization begin
            μ(ω) = MvNormalMeanCovariance(omega_mean, omega_covariance)
            q(s) = GammaShapeScale(noise_shape, noise_scale)
        end

        priors = Dict(
            :ω => MvNormalMeanCovariance(omega_mean, omega_covariance), :s => GammaShapeScale(noise_shape, noise_scale)
        )

        inference_results = infer(
            model = feature_regression_unknown_noise(ϕs = phi_s, priors = priors, x = x),
            data = (y = y,),
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
    end

    result = Dict(
        "omega_mean" => parameters["omega_mean"],
        "omega_covariance" => parameters["omega_covariance"],
        "noise_shape" => parameters["noise_shape"],
        "noise_scale" => parameters["noise_scale"]
    )

    return result, state, parameters
end
