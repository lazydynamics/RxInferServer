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

@testitem "A model can perform continual learning with forgetting factors" setup = [TestUtils] begin
    using RxInfer, StableRNGs, LinearAlgebra

    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "FeatureDiscovery-v1", description = "Testing continual learning"
    )

    rng = StableRNG(42)

    # Test with a simple linear function
    x_dim = 3
    f = (x) -> x[1] * 2.0 + x[2] * 3.0 + x[3] * 4.0
    real_noise_precision = 5.0

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    instance_id = response.instance_id

    # Phase 1: Initial learning (use default episode)
    N1 = 500
    x1 = [randn(rng, x_dim) for _ in 1:N1]
    y1 = [f(x1[i]) + randn(rng) * sqrt(inv(real_noise_precision)) for i in 1:N1]
    events1 = [Dict("data" => Dict("x" => x1[i], "y" => y1[i])) for i in 1:N1]

    attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events1)
    attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "default", attach_events_request
    )
    @test info.status == 200

    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response1, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)
    @test info.status == 200

    # Store initial parameters for comparison
    initial_omega_mean = learn_response1.learned_parameters["omega_mean"]
    initial_omega_cov = learn_response1.learned_parameters["omega_covariance"]
    initial_noise_shape = learn_response1.learned_parameters["noise_shape"]
    initial_noise_scale = learn_response1.learned_parameters["noise_scale"]

    # Phase 2: Create new episode for continual learning
    create_episode_request = TestUtils.RxInferClientOpenAPI.CreateEpisodeRequest(name = "phase2")
    episode_response, info = TestUtils.RxInferClientOpenAPI.create_episode(
        models_api, instance_id, create_episode_request
    )
    @test info.status == 200

    N2 = 100
    x2 = [randn(rng, x_dim) for _ in 1:N2]
    y2 = [f(x2[i]) + randn(rng) * sqrt(inv(real_noise_precision)) for i in 1:N2]
    events2 = [Dict("data" => Dict("x" => x2[i], "y" => y2[i])) for i in 1:N2]

    attach_events_request2 = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events2)
    attach_response2, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "phase2", attach_events_request2
    )
    @test info.status == 200

    # Test continual learning (this should use the forgetting factor internally)
    learn_request2 = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["phase2"])
    learn_response2, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request2)
    @test info.status == 200

    # Verify that parameters have been updated
    updated_omega_mean = learn_response2.learned_parameters["omega_mean"]
    updated_omega_cov = learn_response2.learned_parameters["omega_covariance"]
    updated_noise_shape = learn_response2.learned_parameters["noise_shape"]
    updated_noise_scale = learn_response2.learned_parameters["noise_scale"]

    # Test that parameters have changed (indicating continual learning occurred)
    @test updated_omega_mean != initial_omega_mean
    @test updated_omega_cov != initial_omega_cov

    # Test that the model still works for inference
    test_x = randn(rng, x_dim)
    test_y_true = f(test_x)

    inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("x" => test_x))
    inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, instance_id, inference_request)

    @test info.status == 200
    @test haskey(inference_response.results, "y_mean")
    @test haskey(inference_response.results, "y_variance")
    @test inference_response.results["y_mean"] ≈ test_y_true atol = 0.1

    # Cleanup
    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
end

@testitem "Merged learning function maintains backward compatibility" setup = [TestUtils] begin
    using RxInfer, StableRNGs

    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "FeatureDiscovery-v1", description = "Testing backward compatibility"
    )

    rng = StableRNG(123)

    # Simple test case
    x_dim = 2
    f = (x) -> x[1] + x[2]
    N = 100

    x = [randn(rng, x_dim) for _ in 1:N]
    y = [f(x[i]) + 0.1 * randn(rng) for i in 1:N]
    events = [Dict("data" => Dict("x" => x[i], "y" => y[i])) for i in 1:N]

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    instance_id = response.instance_id

    attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events)
    attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
        models_api, instance_id, "default", attach_events_request
    )
    @test info.status == 200

    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

    @test info.status == 200
    @test haskey(learn_response.learned_parameters, "omega_mean")
    @test haskey(learn_response.learned_parameters, "omega_covariance")
    @test haskey(learn_response.learned_parameters, "noise_shape")
    @test haskey(learn_response.learned_parameters, "noise_scale")

    # Test inference still works
    test_x = [1.0, 2.0]
    inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("x" => test_x))
    inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, instance_id, inference_request)

    @test info.status == 200
    @test haskey(inference_response.results, "y_mean")
    @test haskey(inference_response.results, "y_variance")

    # Cleanup
    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
end
