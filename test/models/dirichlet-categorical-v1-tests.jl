@testitem "it should be possible to create a Dirichlet-Categorical model instance with correct arguments" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "DirichletCategorical-v1",
        description = "Testing Dirichlet-Categorical model",
        arguments = Dict("prior_alpha" => [2.0, 3.0, 4.0])
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testitem "model should be able to learn from observations and make predictions" setup = [TestUtils] begin
    using RxInfer, StableRNGs, Distributions

    function generate_categorical_data(n, true_probs; rng = StableRNG(1234))
        x = rand(rng, Categorical(true_probs), n)
        n_categories = length(true_probs)
        # Create proper one-hot encodings based on category indices
        return [Float64.(x[i] .== 1:n_categories) for i in 1:length(x)]
    end

    @testset for n in (500, 1000), 
                  true_probs in ([0.5, 0.3, 0.2], [0.2, 0.2, 0.6], [0.33, 0.34, 0.33]),
                  prior_alpha in ([1.0, 1.0, 1.0], [2.0, 2.0, 2.0], [5.0, 3.0, 2.0])
        
        observations = generate_categorical_data(n, true_probs)
        n_categories = length(true_probs)

        client = TestUtils.TestClient(roles = ["user"])
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "DirichletCategorical-v1",
            description = "Testing Dirichlet-Categorical model",
            arguments = Dict("prior_alpha" => prior_alpha)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        # Create events for all observations
        events = [Dict("data" => Dict("observation" => obs)) for obs in observations]

        # Attach all events at once
        attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events)
        attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
            models_api, instance_id, "default", attach_events_request
        )

        @test info.status == 200
        @test !isnothing(attach_response)

        # Double check that the episode has the correct number of events
        episode, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, instance_id, "default")
        @test info.status == 200
        @test !isnothing(episode)
        @test length(episode.events) == n

        # Learn from the data
        learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
        learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

        @test info.status == 200
        @test !isnothing(learn_response)

        posterior_alpha = learn_response.learned_parameters["posterior_alpha"]

        # Count occurrences of each category from one-hot encoded observations
        observed_counts = sum(observations)
        expected_posterior_alpha = prior_alpha .+ observed_counts

        @test posterior_alpha ≈ expected_posterior_alpha

        # Test inference on new observations for each category
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => missing))
        inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, instance_id, inference_request
        )

        @test info.status == 200
        @test !isnothing(inference_response)

        @test haskey(inference_response.results, "predicted_probs")
        @test haskey(inference_response.results, "number_of_infer_calls")
        @test length(inference_response.results["predicted_probs"]) == n_categories
        @test isapprox(sum(mean.(inference_response.results["predicted_probs"])), 1.0, atol = 1e-6)

        expected_mean_probs = posterior_alpha ./ sum(posterior_alpha)
        @test inference_response.results["predicted_probs"] ≈ expected_mean_probs

        # Delete model instance
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"
    end
end

@testitem "model should support continual learning" setup = [TestUtils] begin
    using RxInfer, StableRNGs, Distributions

    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Using uniform prior for 4 categories
    n_categories = 4
    prior_alphas = ones(n_categories)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "DirichletCategorical-v1",
        description = "Testing continual learning",
        arguments = Dict("prior_alpha" => prior_alphas)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    first_batch = [1, 1, 2, 1, 3, 1, 2, 1, 4, 1]
    events1 = [Dict("data" => Dict("observation" => Float64.(obs .== 1:n_categories))) for obs in first_batch]

    attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events1)
    attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "default", attach_events_request
    )

    @test info.status == 200
    @test !isnothing(attach_response)

    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

    @test info.status == 200
    @test !isnothing(learn_response)

    expected_alphas_1 = [7.0, 3.0, 2.0, 2.0] 
    @test learn_response.learned_parameters["posterior_alpha"] ≈ expected_alphas_1

    second_batch = [2, 2, 3, 2, 3, 3, 4, 4, 3, 2]
    events2 = [Dict("data" => Dict("observation" => Float64.(obs .== 1:n_categories))) for obs in second_batch]

    attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events2)
    attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "default", attach_events_request
    )

    @test info.status == 200
    @test !isnothing(attach_response)

    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

    @test info.status == 200
    @test !isnothing(learn_response)

    expected_alphas_2 = [7.0, 7.0, 6.0, 4.0]
    @test learn_response.learned_parameters["posterior_alpha"] ≈ expected_alphas_2

    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testitem "inference should produce correct probabilities for different prior parameters" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    @testset for (prior_alphas, description) in [
        ([2.0, 2.0], "Two categories"),
        ([1.0, 1.0, 1.0], "Uniform prior"),
        ([5.0, 3.0, 2.0, 10.0], "Non-uniform prior")
    ]
        n_categories = length(prior_alphas)
        
        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "DirichletCategorical-v1",
            description = description,
            arguments = Dict("prior_alpha" => prior_alphas)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
        @test info.status == 200
        instance_id = response.instance_id

        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(
            data = Dict("observation" => missing)
        )
        inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, instance_id, inference_request
        )

        @test info.status == 200
        mean_probs = inference_response.results["predicted_probs"]
        @test length(mean_probs) == n_categories
        @test all(0 .<= mean_probs .<= 1)
        @test isapprox(sum(mean_probs), 1.0, atol = 1e-6)

        expected_mean_probs = prior_alphas ./ sum(prior_alphas)
        @test mean_probs ≈ expected_mean_probs

        # Clean up
        TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    end
end