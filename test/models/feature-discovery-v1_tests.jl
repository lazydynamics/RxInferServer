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

@testmodule FeatureDiscoveryUtils begin 
    function generate_feature_discovery_data(; N, x_dim, f, real_noise_precision, rng = StableRNG(1234))
        x = [randn(rng, x_dim) for _ in 1:N]
        y = [f(x[i]) + randn(rng) * sqrt(inv(real_noise_precision)) for i in 1:N]
        return x, y
    end

    export generate_feature_discovery_data
end

@testitem "A model can learn coefficients for hidden functions" setup = [TestUtils, FeatureDiscoveryUtils] begin
    using RxInfer, StableRNGs
    using .FeatureDiscoveryUtils

    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "FeatureDiscovery-v1", description = "Testing feature discovery model", arguments = Dict(
            "functions" => [
                "linear", "quadratic", "pairwise", "tripplewise"
            ]
        )
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
            N = 1500

            x, y = generate_feature_discovery_data(
                N = N, x_dim = x_dim, f = f, real_noise_precision = real_noise_precision, rng = rng
            )

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

            # Check that additional learning after the inference call doesn't break and yields the same results
            # since we don't add any new data, the inference call doesn't have the `y` so it should be skipped
            learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
            learn_response_repeated, info = TestUtils.RxInferClientOpenAPI.run_learning(
                models_api, instance_id, learn_request
            )
            @test info.status == 200
            @test !isnothing(learn_response)

            # Check that the learned parameters are the same
            @test learn_response_repeated.learned_parameters["omega_mean"] ==
                learn_response.learned_parameters["omega_mean"]
            @test learn_response_repeated.learned_parameters["omega_covariance"] ==
                learn_response.learned_parameters["omega_covariance"]
            @test learn_response_repeated.learned_parameters["noise_shape"] ==
                learn_response.learned_parameters["noise_shape"]
            @test learn_response_repeated.learned_parameters["noise_scale"] ==
                learn_response.learned_parameters["noise_scale"]

            # Now add some new data
            N_extra = 10
            x_extra, y_extra = generate_feature_discovery_data(
                N = N_extra, x_dim = x_dim, f = f, real_noise_precision = real_noise_precision, rng = rng
            )
            events_extra = [Dict("data" => Dict("x" => x_extra[i], "y" => y_extra[i])) for i in 1:N_extra]
            attach_events_request = TestUtils.RxInferClientOpenAPI.AttachEventsToEpisodeRequest(events = events_extra)
            attach_response, info = TestUtils.RxInferClientOpenAPI.attach_events_to_episode(
                models_api, instance_id, "default", attach_events_request
            )
            @test info.status == 200
            @test !isnothing(attach_response)

            learn_request_extra = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
            learn_response_extra, info = TestUtils.RxInferClientOpenAPI.run_learning(
                models_api, instance_id, learn_request_extra
            )
            @test info.status == 200
            @test !isnothing(learn_response_extra)

            # Check that the learned parameters are the same
            @test learn_response_extra.learned_parameters["omega_mean"] !=
                learn_response.learned_parameters["omega_mean"]
            @test learn_response_extra.learned_parameters["omega_covariance"] !=
                learn_response.learned_parameters["omega_covariance"]
            @test learn_response_extra.learned_parameters["noise_shape"] !=
                learn_response.learned_parameters["noise_shape"]
            @test learn_response_extra.learned_parameters["noise_scale"] !=
                learn_response.learned_parameters["noise_scale"]

            # Check that the inference results are still consistent
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

            # Check that we can re-learn the parameters from the episode
            relearn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"], relearn = true)
            relearn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(
                models_api, instance_id, relearn_request
            )
            @test info.status == 200
            @test !isnothing(relearn_response)

            # Check that the learned parameters are the not the same, since we are relearning from scratch
            # The first two learning calls were batched into two subsets, where the second learning call 
            # was reusing the learned parameters from the first learning call as its priors 
            # This is NOT exactly the same as learning on the full dataset
            @test relearn_response.learned_parameters["omega_mean"] !=
                learn_response_extra.learned_parameters["omega_mean"]
            @test relearn_response.learned_parameters["omega_covariance"] !=
                learn_response_extra.learned_parameters["omega_covariance"]
            @test relearn_response.learned_parameters["noise_shape"] !=
                learn_response_extra.learned_parameters["noise_shape"]
            @test relearn_response.learned_parameters["noise_scale"] !=
                learn_response_extra.learned_parameters["noise_scale"]

            # Check that re-learned parameters yield consistent inference results
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

@testitem "A model can learn coefficients for tripplewise hidden functions with tanh" setup = [TestUtils, FeatureDiscoveryUtils] begin
    using RxInfer, StableRNGs
    using .FeatureDiscoveryUtils

    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "FeatureDiscovery-v1", description = "Testing feature discovery model", arguments = Dict(
            "functions" => [
                "linear:sigmoid",
                "pairwise:abs",
                "tripplewise:tanh"
            ]
        )
    )

    rng = StableRNG(34)

    sigmoid(x) = 1.0 / (1.0 + exp(-x))

    fs_to_test = [
        (2, (x) -> 2.0 * sigmoid(x[1]) - 3.0 * sigmoid(x[2])),
        (3, (x) -> 3.0 * tanh(x[1] * x[2] * x[3])),
        (6, (x) -> tanh(x[1] * x[2] * x[3]) - 4.0 * tanh(x[4] * x[5] * x[6])),
        (4, (x) -> abs(x[1] * x[2]) + 2.0 * abs(x[3] * x[4])),
    ]

    real_noise_precision_to_test = [5.0]

    for (x_dim, f) in fs_to_test
        for real_noise_precision in real_noise_precision_to_test
            N = 1500

            x, y = generate_feature_discovery_data(
                N = N, x_dim = x_dim, f = f, real_noise_precision = real_noise_precision, rng = rng
            )

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