@testitem "A model can be created" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "FeatureDiscovery-v1", description = "Testing feature discovery model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)
    # Feature discovery model doesn't require any arguments, so it should succeed

    instance_id = response.instance_id

    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end

@testitem "A model can learn coefficients for hidden functions" setup = [TestUtils] begin
    using RxInfer, StableRNGs

    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "FeatureDiscovery-v1", description = "Testing feature discovery model"
    )

    rng = StableRNG(34)

    fs_to_test = [
        (3, (x) -> x[1] * 2.0 + x[2] * 3.0 + x[3] * 4.0),
        (4, (x) -> x[1] * 2.0 + x[2] * 3.0 + x[3] * 4.0 + x[4] * 5.0),
        (2, (x) -> x[1] * x[2]),
        (3, (x) -> -3.0 * x[1] * x[2] + x[3] * 4.0),
        (5, (x) -> x[1] * x[2] - x[3] * x[4] + x[5] * 6.0),
        (3, (x) -> x[1] * x[2] * x[3]),
        (3, (x) -> x[1] * x[2] * x[3] - x[1] * x[2] - 2 * x[2] * x[3] + 3 * x[1] + 2 * x[2] + 1 * x[3])
    ]

    real_noise_precision_to_test = [2.0, 5.0, 7.0]

    for (x_dim, f) in fs_to_test
        for real_noise_precision in real_noise_precision_to_test
            N = 1000

            x = [randn(rng, x_dim) for _ in 1:N]

            y = [f(x[i]) + randn(rng) * sqrt(inv(real_noise_precision)) for i in 1:N]

            events = [Dict("data" => Dict("x" => x[i], "y" => y[i])) for i in 1:N]

            response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(
                models_api, create_model_instance_request
            )

            @test info.status == 200
            @test !isnothing(response)

            instance_id = response.instance_id

            attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events)
            attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
                models_api, instance_id, "default", attach_events_request
            )

            @test info.status == 200
            @test !isnothing(attach_response)

            learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
            learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

            @test info.status == 200
            @test !isnothing(learn_response)

            @test haskey(learn_response.learned_parameters, "omega_mean")
            @test haskey(learn_response.learned_parameters, "omega_covariance")
            @test haskey(learn_response.learned_parameters, "noise_shape")
            @test haskey(learn_response.learned_parameters, "noise_scale")

            noise_precision_inferred_mean =
                learn_response.learned_parameters["noise_shape"] * learn_response.learned_parameters["noise_scale"]
            @test isapprox(noise_precision_inferred_mean, real_noise_precision, rtol = 0.1)

            # Check different x values
            x_to_test = [rand(rng, x_dim) for _ in 1:10]

            for test_x in x_to_test
                test_y_true = f(test_x)

                inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("x" => test_x))
                inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
                    models_api, instance_id, inference_request
                )

                @test info.status == 200
                @test !isnothing(inference_response)

                @test haskey(inference_response.results, "y_mean")
                @test haskey(inference_response.results, "y_variance")

                @test inference_response.results["y_mean"] ≈ test_y_true atol = 0.05
            end

            response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
            @test info.status == 200
            @test response.message == "Model instance deleted successfully"
        end
    end
end
