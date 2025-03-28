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

@testitem "model should be able to learn from observations" setup = [TestUtils] begin
    using RxInfer, StableRNGs

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

    @testset for k in (2, 4, 8)
        A, x, y = generate_rotate_ssm_data(100, k)

        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BlackBoxStateSpaceModel-v1",
            description = "Testing black-box state space model",
            arguments = Dict("state_dimension" => 2, "horizon" => 10)
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

        # Delete model instance
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"
    end
end
