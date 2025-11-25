@testitem "missing required arguments should lead to an error" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "LinearRegression-v1", description = "Testing linear regression model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)
    # Linear regression model doesn't require any arguments, so it should succeed
end

@testitem "it should be possible to create a model instance" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "LinearRegression-v1", description = "Testing linear regression model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testitem "model should be able to learn from data and make predictions" setup = [TestUtils] begin
    using RxInfer, StableRNGs, LinearAlgebra

    function generate_linear_regression_data(n, true_a, true_b, true_noise; rng = StableRNG(1234))
        x = collect(range(-5, 5, length = n))
        y = true_a .* x .+ true_b .+ randn(rng, n) .* sqrt(true_noise)
        return x, y
    end

    @testset for n in (1000, 2000),
        true_a in (0.5, 2.0, -1.0), true_b in (0.0, 5.0, -3.0),
        true_noise in (0.1, 0.5, 2.0)

        x_data, y_data = generate_linear_regression_data(n, true_a, true_b, true_noise)

        client = TestUtils.TestClient(
            roles = ["user"],
            headers = Dict(
                "Prefer" => "distributions_repr=data,distributions_data=mean_cov,mdarray_data=array_of_arrays,mdarray_repr=data"
            )
        )
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "LinearRegression-v1", description = "Testing linear regression model"
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        # Create events for all observations
        events = [Dict("data" => Dict("x" => x_data[i], "y" => y_data[i])) for i in 1:n]

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
        @test length(episode.events) == n
        @test all(e -> e[1]["data"]["x"] == e[2] && e[1]["data"]["y"] == e[3], zip(episode.events, x_data, y_data))

        # Learn from the data
        learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
        learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

        @test info.status == 200
        @test !isnothing(learn_response)

        # Check that learned parameters are reasonable
        learned_a_mean = learn_response.learned_parameters["a_mean"]
        learned_b_mean = learn_response.learned_parameters["b_mean"]

        # The learned parameters should be reasonably close to the true values
        # Allow for some tolerance due to noise and finite sample size
        @test isapprox(learned_a_mean, true_a, atol = 0.1)
        @test isapprox(learned_b_mean, true_b, atol = 0.1)

        # Test inference on new data points
        test_x = [0.0, 2.0, -2.0]
        test_y_true = true_a .* test_x .+ true_b

        for (i, test_x) in enumerate(test_x)
            inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("x" => test_x))
            inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
                models_api, instance_id, inference_request
            )

            @test info.status == 200
            @test !isnothing(inference_response)

            @test haskey(inference_response.results, "y_mean")
            @test haskey(inference_response.results, "y_variance")

            # The inferred parameters should be close to the true parameters
            @test all(isapprox.(inference_response.results["y_mean"], test_y_true[i], atol = 0.1))
        end

        # Delete model instance
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"
    end
end
