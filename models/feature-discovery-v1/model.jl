using RxInfer, LinearAlgebra

function create_feature_functions_1(x_dim)
    linear = [(x) -> getindex(x, i) for i in 1:x_dim]
    quadratic = [(x) -> getindex(x, i)^2 for i in 1:x_dim]
    pairwise = [(x) -> getindex(x, i - 1) * getindex(x, i) for i in 2:x_dim]
    tripplewise = [(x) -> getindex(x, i - 2) * getindex(x, i - 1) * getindex(x, i) for i in 3:x_dim]
    return vcat(linear, quadratic, pairwise, tripplewise)
end

@model function feature_regression_unknown_noise(ϕs, x, y, priors)
    ω ~ priors[:ω]
    s ~ priors[:s]
    f   = x -> [ϕ(x) for ϕ in ϕs]
    if length(x) != length(y)
        throw(DimensionMismatch("x and y must have the same length"))
    end

    M = length(x)
    k = 1
    for i in 1:M
        if !ismissing(x[i])
            ϕx = [ϕ(x[i]) for ϕ in ϕs]
            y[i] ~ Normal(mean = dot(ϕx, ω), precision = s)
        else
            x[k] ~ priors[:x]["$(i)"]
            ϕx[k] := f(x[i]) where {meta = Linearization()}
            y[i] ~ softdot(ϕx[k], ω, s)
            k += 1
        end
        
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
    return Dict{String, Any}("number_of_iterations" => arguments["number_of_iterations"])
end

function initial_parameters(arguments)
    return Dict{String, Any}(
        "omega_mean" => nothing, 
        "omega_covariance" => nothing, 
        "noise_shape" => nothing, 
        "noise_scale" => nothing,
        "feature_priors" => Dict{String, Dict{String, Any}}()
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

    x = Vector{Union{Vector{Float64}, Missing}}()
    y = Vector{Float64}()

    for event in events
        if haskey(event, "data") && haskey(event["data"], "x") && haskey(event["data"], "y")
            push!(x, convert(Vector{Float64}, event["data"]["x"]))
            push!(y, convert(Float64, event["data"]["y"]))
        end
    end

    if !isempty(x) && !isempty(y)
        missing_indices = findall(ismissing, x)
        has_missing_features = !isempty(missing_indices)
        
        x_dim = length(x[1])
        phi_s = create_feature_functions_1(x_dim)
        phi_dim = length(phi_s)

        omega_mean = @something(parameters["omega_mean"], zeros(phi_dim))
        omega_covariance = @something(parameters["omega_covariance"], 1e6 * Diagonal(ones(phi_dim)))
        noise_shape = @something(parameters["noise_shape"], 1e-12)
        noise_scale = @something(parameters["noise_scale"], 1e8)

        feature_priors_storage = get(parameters, "feature_priors", Dict{String, Dict{String, Any}}())

     

        priors = if !has_missing_features
            Dict(
                :ω => MvNormalMeanCovariance(omega_mean, omega_covariance),
                :s => GammaShapeScale(noise_shape, noise_scale)
            )
        else
            feature_priors = Dict{String, Any}()
            
            for idx in missing_indices
                idx_str = "$(idx)"
                
                if haskey(feature_priors_storage, idx_str)
                    prior_mean = feature_priors_storage[idx_str]["mean"]
                    prior_cov = feature_priors_storage[idx_str]["covariance"]
                else
                    prior_mean = zeros(x_dim)
                    prior_cov = Diagonal(ones(x_dim))
                end
                
                feature_priors[idx_str] = MvNormalMeanCovariance(prior_mean, prior_cov)
            end
            
            Dict(
                :ω => MvNormalMeanCovariance(omega_mean, omega_covariance),
                :s => GammaShapeScale(noise_shape, noise_scale),
                :x => feature_priors
            )
        end

        init = if !has_missing_features
            @initialization begin
                μ(ω) = MvNormalMeanCovariance(omega_mean, omega_covariance)
                q(s) = GammaShapeScale(noise_shape, noise_scale)
            end
        else
            x_init_list = [priors[:x][string(idx)] for idx in missing_indices]
            
            @initialization begin
                μ(ω) = MvNormalMeanCovariance(omega_mean, omega_covariance)
                q(s) = GammaShapeScale(noise_shape, noise_scale)
                q(x) = x_init_list
            end
        end
        

        inference_results = infer(
            model = feature_regression_unknown_noise(ϕs = phi_s, priors = priors, x = x),
            data = (y = y,),
            initialization = init,
            returnvars = if !has_missing_features
                (ω = KeepLast(), s = KeepLast())
            else
                (ω = KeepLast(), s = KeepLast(), x = KeepLast())
            end,
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

        if has_missing_features
            x_posteriors = inference_results.posteriors[:x]
            
            for (k, idx) in enumerate(missing_indices)
                idx_str = "$(idx)"
                posterior_for_x = x_posteriors[k]
                
                feature_priors_storage[idx_str] = Dict(
                    "mean" => mean(posterior_for_x),
                    "covariance" => cov(posterior_for_x)
                )
            end
            
            parameters["feature_priors"] = feature_priors_storage
        else
            parameters["feature_priors"] = feature_priors_storage
        end
    end

    result = Dict(
        "omega_mean" => parameters["omega_mean"],
        "omega_covariance" => parameters["omega_covariance"],
        "noise_shape" => parameters["noise_shape"],
        "noise_scale" => parameters["noise_scale"],
        "feature_priors" => parameters["feature_priors"]
    )

    return result, state, parameters
end
