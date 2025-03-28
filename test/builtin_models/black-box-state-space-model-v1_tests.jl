@testitem "missing required arguments should lead to an error" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BlackBoxStateSpaceModel-v1", description = "Testing black-box state space model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 400
    @test !isnothing(response)
    @test response.error == "Bad Request"
    @test occursin("model configuration argument state_dimension is required", response.message)
end

@testitem "it should be possible to create a model with the correct arguments" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BlackBoxStateSpaceModel-v1",
        description = "Testing black-box state space model",
        arguments = Dict("state_dimension" => 2)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testitem "model should be able to learn from observations and predict future signal" setup = [TestUtils] begin
    using RxInfer, StableRNGs, LinearAlgebra

    function generate_rotate_ssm_data(n, k; rng = StableRNG(1234))
        θ = π / k
        A = [cos(θ) -sin(θ); sin(θ) cos(θ)]
        Q = diageye(2)
        P = diageye(2)

        x_prev = ones(2)

        x = Vector{Vector{Float64}}(undef, n)
        y = Vector{Vector{Float64}}(undef, n)

        for i in 1:n
            x[i] = rand(rng, MvNormal(A * x_prev, Q))
            y[i] = rand(rng, MvNormal(x[i], P))
            x_prev = x[i]
        end

        return A, x, y
    end

    @testset for n in (200, 300), k in (2, 4, 8), horizon in (3, 6)
        A, x_generated, y_generated = generate_rotate_ssm_data(n + horizon, k)

        x = x_generated[1:n]
        y = y_generated[1:n]

        x_future = x_generated[(n + 1):end]
        y_future = y_generated[(n + 1):end]

        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BlackBoxStateSpaceModel-v1",
            description = "Testing black-box state space model",
            arguments = Dict("state_dimension" => 2, "horizon" => horizon)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        # Create events for all observations
        events = [Dict("data" => Dict("observation" => obs)) for obs in y]

        # Attach all events at once
        attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events)
        attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
            models_api, instance_id, "default", attach_events_request
        )

        @test info.status == 200
        @test !isnothing(attach_response)

        # Double check that the episode has the correct number of events and that the events are correct
        episode, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, instance_id, "default")
        @test info.status == 200
        @test !isnothing(episode)
        @test length(episode.events) == length(y)
        @test all(e -> e[1]["data"]["observation"] == e[2], zip(episode.events, y))

        # Learn from the data
        learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
        learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

        @test info.status == 200
        @test !isnothing(learn_response)
        @test isapprox(A, reshape(learn_response.learned_parameters["A_flattened"], 2, 2), rtol = 0.1)

        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(
            data = Dict("observation" => y[end], "current_state" => x[end])
        )
        inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, instance_id, inference_request
        )

        @test info.status == 200
        @test !isnothing(inference_response)

        # Check that the predicted states are consistent with the future states
        predicted_states = inference_response.results["states"]

        # We expect some deviation due to the stochastic nature of the model
        # and the fact that we're using approximate inference
        for i in 1:horizon
            # The states should be reasonably close to the true future states
            # given that the process noise has unit covariance
            @test isapprox(predicted_states[i], x_future[i], rtol = 0.3)

            # Calculate the error between predicted and actual
            error_vector = predicted_states[i] - x_future[i]

            # For a unit covariance MvNormal, we expect errors to be typically within 2-3 standard deviations
            # This is a probabilistic test, so we use a relatively loose bound
            @test norm(error_vector) < 3 * sqrt(length(error_vector))
        end

        # Delete model instance
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"
    end
end
