using RxInfer

function initial_state(arguments)
    return Dict("state_dimension" => arguments["state_dimension"], "horizon" => arguments["horizon"])
end

function initial_parameters(arguments)
    return Dict("A" => zeros(arguments["state_dimension"], arguments["state_dimension"]))
end

@model function state_space_model_prediction(dim, A, horizon, current_state, observation)
    state ~ MvNormal(μ = current_state, Σ = diageye(dim))
    observation ~ MvNormal(μ = state, Σ = diageye(dim))

    for t in 1:horizon
        s[t] ~ MvNormal(μ = A * state, Σ = diageye(dim))
        state = s[t]
    end

    # hacky wacky
    s[end] ~ MvNormal(μ = zeros(dim), Σ = 1e10 * diageye(dim))
end

### ---------------------------------------------- ###
### ------------------ LEARNING ------------------ ###
### ---------------------------------------------- ###

@meta function make_learning_meta(f)
    ContinuousTransition() -> CTMeta(f)
end

@initialization function make_learning_initialization(dim)
    q(H) = MvNormalMeanCovariance(zeros(dim * dim), 1e2 * diageye(dim * dim))
end

@constraints function make_learning_constraints()
    q(H, s) = q(H)q(s)
end

@model function state_space_model_learning(dim, y)
    s[1] ~ MvNormal(μ = ones(dim), Σ = diageye(dim))
    y[1] ~ MvNormal(μ = s[1], Σ = diageye(dim))

    H ~ MvNormal(μ = zeros(dim * dim), Σ = diageye(dim * dim))

    for t in 2:length(y)
        s[t] ~ ContinuousTransition(s[t - 1], H, diageye(dim))
        y[t] ~ MvNormal(μ = s[t], Σ = diageye(dim))
    end
end

function run_inference(state, parameters, data)
    observation = Float64.(data["observation"])
    current_state = Float64.(data["current_state"])
    results = infer(
        model = state_space_model_prediction(
            dim = state["state_dimension"], A = parameters["A"], horizon = state["horizon"]
        ),
        data = (observation = observation, current_state = current_state),
        options = (limit_stack_depth = 300,)
    )

    result = Dict("states" => mean.(results.posteriors[:s]))

    return result, state
end

function run_learning(state, parameters, events)
    f = let dim = state["state_dimension"]
        (H) -> reshape(H, dim, dim)
    end
    y = [convert(Vector{Float64}, event["data"]["observation"]) for event in events]
    results = infer(
        model = state_space_model_learning(dim = state["state_dimension"]),
        data = (y = y,),
        meta = make_learning_meta(f),
        initialization = make_learning_initialization(state["state_dimension"]),
        constraints = make_learning_constraints(),
        returnvars = (H = KeepLast(),),
        iterations = 50,
        options = (limit_stack_depth = 300,)
    )

    learnedA = reshape(mean(results.posteriors[:H]), state["state_dimension"], state["state_dimension"])

    parameters["A"] = learnedA

    result = Dict("A" => learnedA)

    return result, state, parameters
end
