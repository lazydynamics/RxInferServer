@testitem "missing required arguments should lead to an error" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "HierarchicalBinomial-v1", description = "Testing hierarchical binomial model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 400
    @test !isnothing(response)
    @test response.error == "Bad Request"
    @test occursin("model configuration argument n_components is required", response.message)
end

@testitem "it should be possible to create a model with the correct arguments" setup = [TestUtils] begin
    client = TestUtils.TestClient(roles = ["user"])
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "HierarchicalBinomial-v1",
        description = "Testing hierarchical binomial model",
        arguments = Dict("n_components" => 3, "number_of_iterations" => 5)
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
    using RxInfer, StableRNGs, LinearAlgebra

    function generate_hierarchical_binomial_data(n_trials, n_components; rng = StableRNG(1234))
        # True parameters for each arm
        y_true = rand(rng, Binomial(n_trials, 0.5), n_components)
        return y_true, fill(n_trials, n_components)
    end

    y_true, n_trials = generate_hierarchical_binomial_data(10, 5)

    client = TestUtils.TestClient(
        roles = ["user"],
        headers = Dict(
            "Prefer" => "distributions_repr=data,distributions_data=mean_cov,mdarray_data=array_of_arrays,mdarray_repr=data"
        )
    )
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "HierarchicalBinomial-v1",
        description = "Testing hierarchical binomial model",
        arguments = Dict("n_components" => 5, "number_of_iterations" => 10)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    instance_id = response.instance_id

    # Create events for all observations
    events = [Dict("data" => Dict("y" => y_true, "n_trials" => n_trials))]
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

    # Learn from the data
    learn_request = TestUtils.RxInferClientOpenAPI.LearnRequest(episodes = ["default"])
    learn_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, instance_id, learn_request)

    @test info.status == 200
    @test !isnothing(learn_response)

    # Check that the learned parameters are available
    @test haskey(learn_response.learned_parameters, "transformation_shapes")
    @test haskey(learn_response.learned_parameters, "transformation_rates")
    @test haskey(learn_response.learned_parameters, "latent_mean")
    @test haskey(learn_response.learned_parameters, "latent_precision")

    # Delete model instance
    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"
end
