@testitem "missing required arguments should lead to an error" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "Autoregressive-v1", description = "Testing autoregressive model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 400
    @test !isnothing(response)
    @test response.error == "Bad Request"
    @test occursin("model configuration argument order is required", response.message)
end

@testitem "it should be possible to create a model with the correct arguments" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "Autoregressive-v1",
        description = "Testing autoregressive model",
        arguments = Dict("order" => 2, "horizon" => 5)
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

    function generate_ar_data(n, order, horizon; rng = StableRNG(1234))
        # AR coefficients
        θ_true = [0.8, -0.5, 0.3][1:min(3, order)]
        if order > 3
            append!(θ_true, zeros(order - 3))
        end

        # Precision parameters
        τ_true = 10.0  # Process noise precision
        γ_true = 5.0   # Observation noise precision

        # Generate data
        x = zeros(n + horizon, order)
        y = zeros(n + horizon)

        # Initial states
        for i in 1:order
            x[i, :] = zeros(order)
            x[i, 1] = rand(rng, Normal(0, 1 / sqrt(τ_true)))
            y[i] = x[i, 1] + rand(rng, Normal(0, 1 / sqrt(γ_true)))
        end

        # Generate remaining data
        for i in (order + 1):(n + horizon)
            # Compute AR prediction
            x_new = zeros(order)
            x_new[1] = sum(θ_true .* x[i - 1, 1:order])

            # Add process noise
            x_new[1] += rand(rng, Normal(0, 1 / sqrt(τ_true)))

            # Shift states
            x_new[2:end] = x[i - 1, 1:(order - 1)]

            x[i, :] = x_new

            # Generate observation with noise
            y[i] = x[i, 1]
        end

        return θ_true, τ_true, x, y
    end

    @testset for n in (100, 200), order in (2, 3), horizon in (3, 5)
        θ_true, τ_true, x_generated, y_generated = generate_ar_data(n, order, horizon)

        y_train = y_generated[1:n]
        y_future = y_generated[(n + 1):(n + horizon)]

        client = TestUtils.TestClient(
            roles = ["user"],
            headers = Dict(
                "Prefer" => "distributions_repr=data,distributions_data=mean_cov,mdarray_data=array_of_arrays,mdarray_repr=data"
            )
        )
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "Autoregressive-v1",
            description = "Testing autoregressive model",
            arguments = Dict("order" => order, "horizon" => horizon)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        @test info.status == 200
        @test !isnothing(response)

        instance_id = response.instance_id

        # Create events for all observations
        events = [Dict("data" => Dict("observation" => obs)) for obs in y_train]

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
        @test length(episode.events) == length(y_train)

        # Learn from the data
        learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
        learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

        @test info.status == 200
        @test !isnothing(learn_response)

        # The learned θ parameter should be close to the true θ
        @test haskey(learn_response.learned_parameters["parameters"], "θ_μ")
        learned_θ = learn_response.learned_parameters["parameters"]["θ_μ"]
        @test isapprox(learned_θ, θ_true, rtol = 0.2)

        # Run inference on the latest data to get predictions
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => [y_train[end]]))
        inference_response, info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, instance_id, inference_request
        )

        @test info.status == 200
        @test !isnothing(inference_response)

        # Check that the predicted states are available
        @test haskey(inference_response.results, "states")
        predicted_states = inference_response.results["states"]
        @test length(predicted_states) >= horizon

        # The first state should correspond to the last observation
        # Subsequent states should be predictions
        for i in 1:horizon
            # For each prediction, extract the relevant state value
            predicted_mean = predicted_states[i + 1]["mean"][1]  # First component corresponds to observation

            # Check that predictions are reasonable
            @test isfinite(predicted_mean)

            # For more strict testing, calculate prediction error
            prediction_error = abs(predicted_mean - y_future[i])

            # The error should be within a reasonable range
            # This is a bit lenient due to the stochastic nature of the process
            @test prediction_error < 3.0 * sqrt(1 / τ_true)
        end

        # Delete model instance
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"
    end
end
