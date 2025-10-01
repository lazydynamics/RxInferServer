@testitem "it should be possible to create a model instance with correct arguments" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1",
        description = "Testing beta bernoulli model",
        arguments = Dict("prior_a" => 2, "prior_b" => 3)
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

    function generate_bernoulli_data(n, true_p; rng = StableRNG(1234))
        observations = rand(rng, Bernoulli(true_p), n)
        return observations
    end

    @testset for n in (500, 1000), true_p in (0.2, 0.5, 0.8), prior_a in (1, 2, 5), prior_b in (1, 2, 5)
        observations = generate_bernoulli_data(n, true_p)

        client = TestUtils.TestClient(roles = ["user"])
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BetaBernoulli-v1",
            description = "Testing beta bernoulli model",
            arguments = Dict("prior_a" => prior_a, "prior_b" => prior_b)
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

        # Check that learned parameters are reasonable
        posterior_a = learn_response.learned_parameters["posterior_a"]
        posterior_b = learn_response.learned_parameters["posterior_b"]

        # The posterior should be prior + observed successes/failures
        observed_successes = sum(observations)
        observed_failures = n - observed_successes
        expected_posterior_a = prior_a + observed_successes
        expected_posterior_b = prior_b + observed_failures

        @test posterior_a == expected_posterior_a
        @test posterior_b == expected_posterior_b

        # Test inference on new observations
        for test_obs in [0, 1]
            inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => test_obs))
            inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
                models_api, instance_id, inference_request
            )

            @test info.status == 200
            @test !isnothing(inference_response)

            @test haskey(inference_response.results, "mean_p")
            @test haskey(inference_response.results, "number_of_infer_calls")

            # The mean should be between 0 and 1
            mean_p = inference_response.results["mean_p"]
            @test 0 <= mean_p <= 1

            # The mean should be close to the true probability (with some tolerance)
            @test isapprox(mean_p, true_p, atol = 0.1)
        end

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

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1",
        description = "Testing continual learning",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    # First batch of data: 8 successes out of 10 trials
    first_batch = [1, 1, 0, 1, 1, 1, 0, 1, 1, 1]
    events1 = [Dict("data" => Dict("observation" => obs)) for obs in first_batch]

    attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events1)
    attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "default", attach_events_request
    )

    @test info.status == 200
    @test !isnothing(attach_response)

    # Learn from first batch
    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

    @test info.status == 200
    @test !isnothing(learn_response)

    # Check first learning results
    @test learn_response.learned_parameters["posterior_a"] == 9  # 1 + 8 successes
    @test learn_response.learned_parameters["posterior_b"] == 3  # 1 + 2 failures

    # Second batch of data: 3 successes out of 10 trials
    second_batch = [0, 1, 0, 0, 1, 0, 0, 1, 0, 0]
    events2 = [Dict("data" => Dict("observation" => obs)) for obs in second_batch]

    attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events2)
    attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "default", attach_events_request
    )

    @test info.status == 200
    @test !isnothing(attach_response)

    # Learn from second batch (continual learning)
    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

    @test info.status == 200
    @test !isnothing(learn_response)

    # Check second learning results (should accumulate)
    @test learn_response.learned_parameters["posterior_a"] == 12  # 9 + 3 successes
    @test learn_response.learned_parameters["posterior_b"] == 10  # 3 + 7 failures

    # Test inference
    inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))
    inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, instance_id, inference_request)

    @test info.status == 200
    @test !isnothing(inference_response)

    expected_mean = (12 + 1) / ((12 + 1) + 10)
    @test isapprox(inference_response.results["mean_p"], expected_mean, atol = 1e-6)

    # Test inference with the same observation (the result should be the same)
    inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))
    inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, instance_id, inference_request)
    @test info.status == 200
    @test !isnothing(inference_response)
    @test isapprox(inference_response.results["mean_p"], expected_mean, atol = 1e-6)

    # Now if we learn, we have added two observations [1, 1], we can learn and update the posterior 
    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)
    @test info.status == 200
    @test !isnothing(learn_response)
    @test learn_response.learned_parameters["posterior_a"] == 14
    @test learn_response.learned_parameters["posterior_b"] == 10

    # Run inference yet again, we should get an updated mean
    inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))
    inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, instance_id, inference_request)
    @test info.status == 200
    @test !isnothing(inference_response)

    new_expected_mean = (14 + 1) / ((14 + 1) + 10)
    @test isapprox(inference_response.results["mean_p"], new_expected_mean, atol = 1e-6)

    # Delete model instance
    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testitem "model should handle different prior parameters" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    @testset for prior_a in (1, 5, 10), prior_b in (1, 3, 8)
        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BetaBernoulli-v1",
            description = "Testing different priors",
            arguments = Dict("prior_a" => prior_a, "prior_b" => prior_b)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        # Test inference with a simple observation
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))
        inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, instance_id, inference_request
        )

        @test info.status == 200
        @test !isnothing(inference_response)
        @test haskey(inference_response.results, "mean_p")
        @test haskey(inference_response.results, "number_of_infer_calls")

        # The mean should be between 0 and 1
        mean_p = inference_response.results["mean_p"]
        @test 0 <= mean_p <= 1

        # The mean should be close to the prior mean ((prior_a + 1) / ((prior_a + 1) + (prior_b)))
        # +1 because the new observation is 1
        expected_prior_mean = (prior_a + 1) / ((prior_a + 1) + (prior_b))
        @test isapprox(mean_p, expected_prior_mean, atol = 1e-6)

        # Clean up
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
    end
end
