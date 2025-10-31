using RxInfer, LinearAlgebra, Distributions

const TRANSFORMATION_DISPATCH_TABLE = Dict(
    "identity" => identity, "sin" => sin, "cos" => cos, "tanh" => tanh, "sigmoid" => (x) -> inv(one(x) + exp(-x))
)

function create_transformation(transformation_name::String)
    if !haskey(TRANSFORMATION_DISPATCH_TABLE, transformation_name)
        throw(
            ArgumentError(
                "Invalid transformation name: $transformation_name. Available options: $(keys(TRANSFORMATION_DISPATCH_TABLE))"
            )
        )
    end
    return TRANSFORMATION_DISPATCH_TABLE[transformation_name]
end

@model function multinomial_regression(obs, N, X, ϕ, ξβ, Wβ, k)
    β ~ MvNormalWeightedMeanPrecision(ξβ, Wβ)
    for i in eachindex(obs)
        Ψ[i] := ϕ(X[i]) * β
        obs[i] ~ MultinomialPolya(
            N, Ψ[i]
        ) where {
            dependencies = RequireMessageFunctionalDependencies(ψ = MvNormalWeightedMeanPrecision(zeros(k), diageye(k)))
        }
    end
end

@model function multinomial_regression_predictive(obs, N, X, ϕ, ξβ, Wβ, k)
    β ~ MvNormalWeightedMeanPrecision(ξβ, Wβ)
    Ψ := ϕ(X) * β
    obs ~ MultinomialPolya(
        N, Ψ
    ) where {
        dependencies = RequireMessageFunctionalDependencies(ψ = MvNormalWeightedMeanPrecision(zeros(k), diageye(k)))
    }
end

function initial_state(arguments)
    return Dict{String, Any}(
        "N" => arguments["N"],
        "k" => arguments["k"],
        "transformation" => arguments["transformation"],
        "number_of_iterations" => arguments["number_of_iterations"]
    )
end

function initial_parameters(arguments)
    k = arguments["k"]
    return Dict{String, Any}("beta_mean" => nothing, "beta_precision" => nothing)
end

function parse_feature_matrix(X_data, k::Int)
    if X_data isa AbstractMatrix && size(X_data) == (k, k)
        return Float64.(X_data)
    elseif X_data isa AbstractVector
        if length(X_data) == k * k
            return reshape(Float64.(X_data), k, k)
        else
            throw(DimensionMismatch("Expected array of length $(k*k) for k=$k, got $(length(X_data))"))
        end
    else
        throw(ArgumentError("X must be a $k×$k matrix or array of $(k*k) numbers"))
    end
end

function run_inference(state, parameters, data)
    @debug "Running inference in MultinomialRegression-v1 model" state parameters data

    N = state["N"]
    k = state["k"]
    transformation = state["transformation"]
    ϕ = create_transformation(transformation)

    X = parse_feature_matrix(data["X"], k)

    ξβ = parameters["beta_mean"]
    Wβ = parameters["beta_precision"]

    inference_results = infer(
        model = multinomial_regression_predictive(X = X, N = N, ϕ = ϕ, ξβ = ξβ, Wβ = Wβ, k = k),
        data = (obs = missing,),
        predictvars = (obs = KeepLast(),)
    )

    obs_pred = inference_results.predictions[:obs]

    result = Dict("N" => N, "probabilities" => obs_pred.p)

    return result, state
end

function run_learning(state, parameters, events)
    @debug "Running learning in MultinomialRegression-v1 model" state parameters events

    N = state["N"]
    k = state["k"]
    transformation = state["transformation"]
    ϕ = create_transformation(transformation)

    X = Vector{Matrix{Float64}}()
    obs = Vector{Vector{Int}}()

    for event in events
        if haskey(event, "data") && haskey(event["data"], "X") && haskey(event["data"], "obs")
            X_matrix = parse_feature_matrix(event["data"]["X"], k)
            push!(X, X_matrix)
            push!(obs, convert(Vector{Int}, event["data"]["obs"]))
        end
    end

    if !isempty(X) && !isempty(obs)
        K = length(obs[1])

        if k != (K - 1)
            throw(DimensionMismatch("Parameter k=$k should equal K-1=$(K-1) for K=$K categories"))
        end

        for (i, o) in enumerate(obs)
            if length(o) != K
                throw(
                    DimensionMismatch(
                        "All observations must have the same number of categories. Expected $K, got $(length(o)) at index $i"
                    )
                )
            end
            if sum(o) != N
                throw(ArgumentError("Observation at index $i has sum $(sum(o)), expected $N"))
            end
        end

        beta_mean = @something(parameters["beta_mean"], zeros(k))
        beta_precision = @something(parameters["beta_precision"], 1e-3 * diagm(ones(k)))

        inference_results = infer(
            model = multinomial_regression(X = X, N = N, ϕ = ϕ, ξβ = beta_mean, Wβ = beta_precision, k = k),
            data = (obs = obs,),
            returnvars = (β = KeepLast(),),
            iterations = state["number_of_iterations"],
            options = (limit_stack_depth = 100,)
        )

        β_posterior = inference_results.posteriors[:β]
        parameters = Dict("beta_mean" => mean(β_posterior), "beta_precision" => precision(β_posterior))
    end

    result = Dict("beta_mean" => parameters["beta_mean"], "beta_precision" => parameters["beta_precision"])

    return result, state, parameters
end
