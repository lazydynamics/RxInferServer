@testitem "A model can be created" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "MultinomialRegression-v1",
        description = "Testing multinomial regression model",
        arguments = Dict("N" => 3, "k" => 2, "transformation" => "identity")
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testmodule MultinomialRegressionUtils begin
    using StableRNGs, Distributions, LinearAlgebra

    function logistic_stick_breaking(ψ::Vector{Float64})
        K = length(ψ) + 1
        π = zeros(K)
        for k in 1:(K - 1)
            π[k] = inv(1 + exp(-ψ[k])) * (1 - sum(π[1:(k - 1)]))
        end
        π[K] = 1 - sum(π[1:(K - 1)])
        return π
    end

    function create_transformation(transformation_name::String)
        transformation_table = Dict(
            "identity" => identity,
            "tanh" => tanh,
            "sigmoid" => (x) -> inv(one(x) + exp(-x)),
            "sin" => sin,
            "cos" => cos
        )
        return transformation_table[transformation_name]
    end

    function generate_multinomial_regression_data(;
        N = 3, K = 3, k = K - 1, n_samples = 100, transformation = "identity", rng = StableRNG(123)
    )
        β_true = randn(rng, k)

        X = [randn(rng, k, k) for _ in 1:n_samples]

        ϕ = create_transformation(transformation)

        observations = Vector{Vector{Int}}(undef, n_samples)
        probabilities = Vector{Vector{Float64}}(undef, n_samples)

        for i in 1:n_samples
            Ψ = ϕ(X[i]) * β_true

            π = logistic_stick_breaking(Ψ)
            probabilities[i] = π

            observations[i] = rand(rng, Multinomial(N, π))
        end

        return X, observations, β_true, probabilities, k
    end

    export generate_multinomial_regression_data
end

@testitem "model should be able to learn from observations and make predictions" setup = [
    TestUtils, MultinomialRegressionUtils
] begin
    using RxInfer, StableRNGs, LinearAlgebra, Distributions

    @testset for N in (3, 5), K in (3, 4), n_samples in (50, 100), transformation in ("identity", "tanh")
        k = K - 1
        X_data, obs_data, β_true, π_data, k_actual = MultinomialRegressionUtils.generate_multinomial_regression_data(
            N = N, K = K, n_samples = n_samples, transformation = transformation
        )

        client = TestUtils.TestClient(
            roles = ["user"],
            headers = Dict(
                "Prefer" => "distributions_repr=data,distributions_data=mean_cov,mdarray_data=array_of_arrays,mdarray_repr=data"
            )
        )
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "MultinomialRegression-v1",
            description = "Testing multinomial regression model",
            arguments = Dict("N" => N, "k" => k, "transformation" => transformation, "number_of_iterations" => 1000)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        events = [Dict("data" => Dict("X" => vec(X_data[i]), "obs" => obs_data[i])) for i in 1:n_samples]

        attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events)
        attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
            models_api, instance_id, "default", attach_events_request
        )

        @test info.status == 200
        @test !isnothing(attach_response)

        episode, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, instance_id, "default")
        @test info.status == 200
        @test !isnothing(episode)
        @test length(episode.events) == n_samples

        learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
        learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

        @test info.status == 200
        @test !isnothing(learn_response)
        @test haskey(learn_response.learned_parameters, "beta_mean")
        @test haskey(learn_response.learned_parameters, "beta_precision")

        @test learn_response.learned_parameters["beta_mean"] isa Vector
        @test length(learn_response.learned_parameters["beta_mean"]) == k

        X_test = randn(k, k)
        infer_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("X" => vec(X_test)))
        infer_response, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, instance_id, infer_request)

        @test info.status == 200
        @test !isnothing(infer_response)
        @test haskey(infer_response.results, "probabilities")

        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
    end
end

@testitem "model should handle different transformations" setup = [TestUtils, MultinomialRegressionUtils] begin
    using RxInfer, StableRNGs, LinearAlgebra

    @testset for transformation in ("identity", "sin", "cos", "tanh", "sigmoid")
        N = 3
        K = 3
        k = K - 1
        n_samples = 50

        X_data, obs_data, _, _, _ = MultinomialRegressionUtils.generate_multinomial_regression_data(
            N = N, K = K, n_samples = n_samples, transformation = transformation
        )

        client = TestUtils.TestClient(roles = ["user"])
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "MultinomialRegression-v1",
            description = "Testing multinomial regression with transformation: $transformation",
            arguments = Dict("N" => N, "k" => k, "transformation" => transformation)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        events = [Dict("data" => Dict("X" => vec(X_data[i]), "obs" => obs_data[i])) for i in 1:n_samples]

        attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events)
        attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
            models_api, instance_id, "default", attach_events_request
        )

        @test info.status == 200

        learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
        learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

        @test info.status == 200
        @test !isnothing(learn_response)

        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
    end
end

@testitem "model should validate input dimensions" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    k = 2
    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "MultinomialRegression-v1",
        description = "Testing input validation",
        arguments = Dict("N" => 3, "k" => k, "transformation" => "identity")
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    instance_id = response.instance_id

    wrong_X = collect(1:5)
    events = [Dict("data" => Dict("X" => wrong_X, "obs" => [1, 1, 1]))]

    attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events)
    attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "default", attach_events_request
    )

    @test info.status == 200

    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

    @test info.status >= 400

    TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
end
