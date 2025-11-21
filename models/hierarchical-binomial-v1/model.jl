using RxInfer

@model function hierarchical_binomial(y, ntrials, latent_prior, precision_priors, n_components)
    latent ~ latent_prior
    local precision
    local component_latent
    for i in 1:n_components
        precision[i] ~ precision_priors[i]
        component_latent[i] ~ Normal(mean = latent, precision = precision[i])
    end
    for i in 1:(size(y, 1))
        for j in 1:n_components
            y[i, j] ~ BinomialPolya(
                1, ntrials[i, j], component_latent[j]
            ) where {dependencies = RequireMessageFunctionalDependencies(β = latent_prior)}
        end
    end
end

@constraints function hierarchical_binomial_constraints()
    q(latent, precision, component_latent) = q(latent, component_latent) * q(precision)
end

@initialization function hierarchical_binomial_initialization(priors)
    q(precision) = priors
end

function initial_state(arguments)
    return Dict(
        "number_of_iterations" => convert(Int, arguments["number_of_iterations"]),
        "n_components" => convert(Int, arguments["n_components"])
    )
end

function initial_parameters(arguments)
    return Dict(
        "latent_mean" => 0.0,
        "latent_precision" => 1e-6,
        "transformation_shapes" => [1.0 for _ in 1:arguments["n_components"]],
        "transformation_rates" => [1.0 for _ in 1:arguments["n_components"]]
    )
end

function run_learning(state, parameters, events)
    @debug "Running inference in HierarchicalBinomial-v1 model" state parameters data

    y = stack([event["data"]["y"] for event in events])'
    n_trials = stack([event["data"]["n_trials"] for event in events])'

    @show y, n_trials

    latent_prior = NormalMeanPrecision(parameters["latent_mean"], parameters["latent_precision"])
    precision_priors = [
        GammaShapeRate(parameters["transformation_shapes"][i], parameters["transformation_rates"][i]) for
        i in 1:state["n_components"]
    ]

    inference_results = infer(
        model = hierarchical_binomial(
            latent_prior = latent_prior, precision_priors = precision_priors, n_components = state["n_components"]
        ),
        data = (y = y, ntrials = n_trials),
        constraints = hierarchical_binomial_constraints(),
        initialization = hierarchical_binomial_initialization(precision_priors),
        iterations = state["number_of_iterations"],
        returnvars = (latent = KeepLast(), precision = KeepLast())
    )

    parameters = Dict(
        "latent_mean" => mean(inference_results.posteriors[:latent]),
        "latent_precision" => precision(inference_results.posteriors[:latent]),
        "transformation_shapes" =>
            [shape(inference_results.posteriors[:precision][i]) for i in 1:state["n_components"]],
        "transformation_rates" => [rate(inference_results.posteriors[:precision][i]) for i in 1:state["n_components"]]
    )
    result = copy(parameters)

    return result, state, parameters
end

function run_inference(state, parameters, data)
    @error "Running inference in HierarchicalBinomial-v1 model is not implemented"
    return Dict(), state, parameters
end