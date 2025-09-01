@testitem "missing required arguments should lead to an error" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "ContextualBandits-v1", description = "Testing contextual bandits model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 400
    @test !isnothing(response)
    @test response.error == "Bad Request"
    @test occursin("model configuration argument context_dim is required", response.message)
end

@testitem "it should be possible to create a model with the correct arguments" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "ContextualBandits-v1",
        description = "Testing contextual bandits model",
        arguments = Dict("context_dim" => 3, "n_arms" => 4, "iterations" => 5)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testitem "model should be able to learn from observations and select optimal arms" setup = [TestUtils] begin
    using RxInfer, StableRNGs, LinearAlgebra

    function generate_contextual_bandits_data(n_rounds, context_dim, n_arms; rng = StableRNG(1234))
        # True parameters for each arm
        θ_true = [randn(rng, context_dim) for _ in 1:n_arms]

        # Generate contexts and rewards
        contexts = [randn(rng, context_dim) for _ in 1:n_rounds]
        choices = Int[]
        rewards = Float64[]

        for round in 1:n_rounds
            context = contexts[round]

            # Calculate true expected rewards for each arm
            expected_rewards = [dot(θ_true[k], context) for k in 1:n_arms]

            # Choose arm (for testing, we'll use epsilon-greedy with small epsilon)
            if rand(rng) < 0.1  # 10% random exploration
                choice = rand(rng, 1:n_arms)
            else
                choice = argmax(expected_rewards)
            end

            # Generate reward with noise
            true_reward = expected_rewards[choice]
            reward = true_reward + randn(rng) * 0.1

            push!(choices, choice)
            push!(rewards, reward)
        end

        return θ_true, contexts, choices, rewards
    end

    @testset for context_dim in (2, 3), n_arms in (3, 4), n_rounds in (50, 100)
        θ_true, contexts, choices, rewards = generate_contextual_bandits_data(n_rounds, context_dim, n_arms)

        client = TestUtils.TestClient(
            roles = ["user"],
            headers = Dict(
                "Prefer" => "distributions_repr=data,distributions_data=mean_cov,mdarray_data=array_of_arrays,mdarray_repr=data"
            )
        )
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "ContextualBandits-v1",
            description = "Testing contextual bandits model",
            arguments = Dict("context_dim" => context_dim, "n_arms" => n_arms, "iterations" => 10)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        # Create events for all observations
        events = [
            Dict("data" => Dict("context" => contexts[i], "reward" => rewards[i], "choice" => choices[i])) for
            i in 1:n_rounds
        ]

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
        @test length(episode.events) == n_rounds

        # Learn from the data
        learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
        learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

        @test info.status == 200
        @test !isnothing(learn_response)

        # Check that the learned parameters are available
        @test haskey(learn_response.learned_parameters, "θ")
        @test haskey(learn_response.learned_parameters, "γ")
        @test haskey(learn_response.learned_parameters, "τ")

        # Run inference on a new context to get arm selection
        new_context = randn(context_dim)
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("context" => new_context))
        inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, instance_id, inference_request
        )

        @test info.status == 200
        @test !isnothing(inference_response)

        # Check that the inference result is a valid arm choice
        @test haskey(inference_response.results, "chosen_arm")
        chosen_arm = inference_response.results["chosen_arm"]
        @test chosen_arm isa Integer
        @test 1 <= chosen_arm <= n_arms
        @test haskey(inference_response.results, "expected_rewards")
        expected_rewards = inference_response.results["expected_rewards"]
        @test length(expected_rewards) == n_arms
        @test all(expected_rewards .<= expected_rewards[chosen_arm])

        # Delete model instance
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"
    end
end

@testitem "model should handle different context dimensions and arm counts" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    @testset for context_dim in (1, 2, 5), n_arms in (2, 5, 10)
        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "ContextualBandits-v1",
            description = "Testing contextual bandits model with different dimensions",
            arguments = Dict("context_dim" => context_dim, "n_arms" => n_arms, "iterations" => 3)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        # Test inference with a simple context
        context = ones(context_dim)
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("context" => context))
        inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, instance_id, inference_request
        )

        @test info.status == 200
        @test !isnothing(inference_response)
        @test haskey(inference_response.results, "chosen_arm")
        chosen_arm = inference_response.results["chosen_arm"]
        @test 1 <= chosen_arm <= n_arms
        @test haskey(inference_response.results, "expected_rewards")
        expected_rewards = inference_response.results["expected_rewards"]
        @test length(expected_rewards) == n_arms
        @test all(expected_rewards .<= expected_rewards[chosen_arm])

        # Clean up
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
    end
end
