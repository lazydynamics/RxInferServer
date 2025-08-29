using RxInfer, LinearAlgebra

@model function conditional_regression(n_arms, priors, past_rewards, past_choices, past_contexts)
    local θ
    local γ
    local τ

    # Prior for each arm's parameters
    for k in 1:n_arms
        θ[k] ~ priors[:θ][k]
        γ[k] ~ priors[:γ][k]
    end

    # Prior for the noise precision
    τ ~ priors[:τ]

    # Model for past observations
    for n in eachindex(past_rewards)
        arm_vals[n] ~ NormalMixture(switch = past_choices[n], m = θ, p = γ)
        latent_context[n] ~ past_contexts[n]
        past_rewards[n] ~ softdot(arm_vals[n], latent_context[n], τ)
    end
end

function initial_state(arguments)
    # Number of infer calls is used to track the number of times the model has been inferred
    # This is used mostly for the testing purposes
    return Dict(
        "context_dim" => arguments["context_dim"],
        "n_arms" => arguments["n_arms"],
        "iterations" => arguments["iterations"]
    )
end

function initial_parameters(arguments)
    context_dim = arguments["context_dim"]
    n_arms = arguments["n_arms"]

    return Dict(
        "θ" => [MvNormalMeanPrecision(randn(context_dim), diagm(ones(context_dim))) for _ in 1:n_arms],
        "γ" => [Wishart(context_dim + 1, diagm(ones(context_dim))) for _ in 1:n_arms],
        "τ" => GammaShapeRate(1.0, 1.0)
    )
end

function context_to_mvnormal(context_vec; tiny_precision = 1e-6, huge_precision = 1e6)
    context_mean = Vector{Float64}(undef, length(context_vec))
    context_precision = Vector{Float64}(undef, length(context_vec))

    for j in 1:length(context_vec)
        if ismissing(context_vec[j])
            context_mean[j] = 0.0
            context_precision[j] = tiny_precision
        else
            context_mean[j] = context_vec[j]
            context_precision[j] = huge_precision
        end
    end

    return MvNormalMeanPrecision(context_mean, Diagonal(context_precision))
end

function arm_index_to_one_hot(arm_index, n_arms)
    one_hot = zeros(n_arms)
    one_hot[arm_index] = 1
    return one_hot
end

function run_inference(state, parameters, data)
    n_arms = state["n_arms"]
    current_context = data["context"]

    # Thompson Sampling: Sample parameter vectors and choose best arm
    expected_rewards = zeros(n_arms)
    for k in 1:n_arms
        # Sample parameters from posterior
        theta_sample = rand(parameters["θ"][k])
        # context might have missing values, so we use the mean of the context
        augmented_context = mean(context_to_mvnormal(current_context))
        expected_rewards[k] = dot(theta_sample, augmented_context)
    end

    # Choose best arm based on sampled parameters
    chosen_arm = argmax(expected_rewards)

    result = Dict("chosen_arm" => chosen_arm)

    return result, state
end

function run_learning(state, parameters, events)
    @debug "Running learning in ContextualBandits-v1 model" state parameters events

    context_dim = state["context_dim"]
    n_arms = state["n_arms"]

    priors = Dict(:θ => parameters["θ"], :γ => parameters["γ"], :τ => parameters["τ"])

    init = @initialization begin
        q(θ) = priors[:θ]
        q(γ) = priors[:γ]
        q(τ) = priors[:τ]
        q(latent_context) = MvNormalMeanPrecision(zeros(context_dim), Diagonal(ones(context_dim)))
    end

    past_contexts = context_to_mvnormal.(map(e -> e["data"]["context"], events))
    past_rewards = convert(Vector{Float64}, map(e -> e["data"]["reward"], events))
    past_choices = arm_index_to_one_hot.(map(e -> e["data"]["choice"], events), n_arms)

    result = infer(
        model = conditional_regression(n_arms = n_arms, priors = priors, past_contexts = past_contexts),
        data = (past_rewards = past_rewards, past_choices = past_choices),
        constraints = MeanField(),
        initialization = init,
        iterations = state["iterations"],
        returnvars = KeepLast()
    )

    parameters["θ"] = result.posteriors[:θ]
    parameters["γ"] = result.posteriors[:γ]
    parameters["τ"] = result.posteriors[:τ]

    result_from_inference = Dict(
        "θ" => result.posteriors[:θ], "γ" => result.posteriors[:γ], "τ" => result.posteriors[:τ]
    )

    return result_from_inference, state, parameters
end
