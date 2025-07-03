using RxInfer, LinearAlgebra

function initial_state(arguments)
    return Dict(
        "order" => arguments["order"],
        "horizon" => arguments["horizon"],
        "x_μ" => get(arguments, "x_μ", zeros(arguments["order"])),
        "x_Λ" => get(arguments, "x_Λ", diageye(arguments["order"]))
    )
end

function initial_parameters(arguments)
    return Dict(
        "τ_α" => 1.0, "τ_β" => 1.0, "θ_μ" => zeros(arguments["order"]), "θ_Λ" => 1e-10 * diageye(arguments["order"])
    )
end

@model function AR_model(y, order, parameters, state)
    # `c` is a unit vector of size `order` with first element equal to 1
    c = ReactiveMP.ar_unit(Multivariate, order)

    τ ~ Gamma(α = parameters["τ_α"], β = parameters["τ_β"])
    θ ~ MvNormal(mean = parameters["θ_μ"], precision = parameters["θ_Λ"])
    x0 ~ MvNormal(mean = state["x_μ"], precision = state["x_Λ"])

    x_prev = x0

    for i in eachindex(y)
        x[i] ~ AR(x_prev, θ, τ)
        y[i] ~ Normal(mean = dot(c, x[i]), precision = 1e10)

        x_prev = x[i]
    end
end

@constraints function AR_constraints()
    q(x0, x, θ, τ, y) = q(x0, x)q(y)q(θ)q(τ)
end

@meta function AR_meta(order)
    AR() -> ARMeta(Multivariate, order, ARsafe())
end

@initialization function AR_init(parameters)
    q(τ) = GammaShapeRate(parameters["τ_α"], parameters["τ_β"])
    q(θ) = MvNormalMeanPrecision(parameters["θ_μ"], parameters["θ_Λ"])
end

### ---------------------------------------------- ###
### ----------------- INFERENCE ------------------ ###
### ---------------------------------------------- ###
function run_inference(state, parameters, data)

    # Add missing values to the observations to match the horizon
    converted_observations = convert.(Float64, data["observation"])
    observations = vcat(converted_observations, [missing for _ in 1:state["horizon"]])

    inference_results = infer(
        model = AR_model(order = state["order"], parameters = parameters, state = state),
        data = (y = UnfactorizedData(observations),),
        meta = AR_meta(state["order"]),
        constraints = AR_constraints(),
        initialization = AR_init(parameters),
        options = (limit_stack_depth = 300,),
        iterations = 20,
        returnvars = KeepLast()
    )

    result = Dict("states" => inference_results.posteriors[:x])
    state["x_μ"] = mean(inference_results.posteriors[:x][length(converted_observations)])
    state["x_Λ"] = precision(inference_results.posteriors[:x][length(converted_observations)])

    return result, state
end

function run_learning(state, parameters, events)
    observations = [convert(Float64, event["data"]["observation"]) for event in events]

    inference_results = infer(
        model = AR_model(order = state["order"], parameters = parameters, state = state),
        data = (y = observations,),
        meta = AR_meta(state["order"]),
        constraints = AR_constraints(),
        initialization = AR_init(parameters),
        options = (limit_stack_depth = 300,),
        returnvars = KeepLast(),
        iterations = 20
    )

    # update parameters
    parameters["τ_α"] = shape(inference_results.posteriors[:τ])
    parameters["τ_β"] = rate(inference_results.posteriors[:τ])
    parameters["θ_μ"] = mean(inference_results.posteriors[:θ])
    parameters["θ_Λ"] = precision(inference_results.posteriors[:θ])

    result = Dict("states" => state, "parameters" => parameters)

    return result, state, parameters
end
