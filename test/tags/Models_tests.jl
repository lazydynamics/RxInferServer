@testitem "`get_available_models` operation should return a list of available models" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    server_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
    available_models, info = TestUtils.RxInferClientOpenAPI.get_available_models(server_api)

    @test info.status == 200
    @test !isnothing(available_models)
    @test !isempty(available_models)

    # Check that the CoinToss model is present, which should be located under the `models` directory
    @test any(m -> m.details.name === "BetaBernoulli-v1", available_models)
end

@testitem "`get_available_models` operation should return a list of available models specific to the user's roles" setup = [
    TestUtils
] begin
    # Check that an arbitrary user cannot access any models
    # In this case, the `available_models` should be empty because 
    # we don't have any models that are accessible to users with the role `arbitrary`
    TestUtils.with_temporary_token(roles = ["arbitrary"]) do
        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
        available_models, info = TestUtils.RxInferClientOpenAPI.get_available_models(models_api)
        @test info.status == 200
        @test isempty(available_models)
    end

    # A user has multiple roles, and some of them are allowed to access some models
    # In this case, the `available_models` should contain the models that are accessible to the role `user`
    for roles in [["arbitrary", "user"], ["user", "arbitrary"]]
        TestUtils.with_temporary_token(roles = roles) do
            client = TestUtils.TestClient()
            models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
            available_models, info = TestUtils.RxInferClientOpenAPI.get_available_models(models_api)
            @test info.status == 200
            @test !isnothing(available_models)
            @test !isempty(available_models)
            @test any(m -> m.details.name === "BetaBernoulli-v1", available_models)
        end
    end
end

@testitem "401 on `get_available_models` operation without authorization" setup = [TestUtils] begin
    client = TestUtils.TestClient(authorized = false)
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
    response, info = TestUtils.RxInferClientOpenAPI.get_available_models(models_api)

    @test info.status == 401
    @test response.error == "Unauthorized"
    @test occursin("The request requires authentication", response.message)
end

@testitem "`get_available_model` operation should return an information about a model" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Get model info
    response, info = TestUtils.RxInferClientOpenAPI.get_available_model(models_api, "BetaBernoulli-v1")

    # Check HTTP status code
    @test info.status == 200

    # Verify model properties
    @test !isnothing(response.details)
    @test !isnothing(response.config)

    # Verify basic info
    @test response.details.name == "BetaBernoulli-v1"
    @test response.details.description == "A simple Beta-Bernoulli model"

    # Verify config content
    @test isa(response.config, Dict)
    @test response.config["name"] == "BetaBernoulli-v1"
    @test response.config["description"] == "A simple Beta-Bernoulli model"
    @test response.config["author"] == "Lazy Dynamics"
    @test !isempty(response.config["arguments"])
end

@testitem "404 on `get_available_model` operation if user's role does not have access" setup = [TestUtils] begin
    TestUtils.with_temporary_token(roles = ["arbitrary"]) do
        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
        response, info = TestUtils.RxInferClientOpenAPI.get_available_model(models_api, "BetaBernoulli-v1")

        @test info.status == 404
        @test response.error == "Not Found"
        @test response.message == "The requested model name `BetaBernoulli-v1` could not be found"
    end
end

@testitem "200 on `get_available_model` operation with mixed roles" setup = [TestUtils] begin
    for roles in [["arbitrary", "user"], ["user", "arbitrary"]]
        TestUtils.with_temporary_token(roles = roles) do
            client = TestUtils.TestClient()
            models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
            response, info = TestUtils.RxInferClientOpenAPI.get_available_model(models_api, "BetaBernoulli-v1")
            @test info.status == 200
            @test response.details.name == "BetaBernoulli-v1"
        end
    end
end

@testitem "401 on `get_available_model` operation without authorization" setup = [TestUtils] begin
    client = TestUtils.TestClient(authorized = false)
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.get_available_model(models_api, "BetaBernoulli-v1")

    @test info.status == 401
    @test response.error == "Unauthorized"
    @test occursin("The request requires authentication", response.message)
end

@testitem "404 on non-existent model `get_available_model` operation" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Try to get info for a non-existent model
    response, info = TestUtils.RxInferClientOpenAPI.get_available_model(models_api, "NonExistentModel")

    # Check HTTP status code
    @test info.status == 404

    # Verify error response
    @test response.error == "Not Found"
    @test response.message == "The requested model name `NonExistentModel` could not be found"
end

@testitem "200 on create model instance, get instance details and delete model instance" setup = [TestUtils] begin
    using Dates, TimeZones

    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1",
        description = "Testing beta-bernoulli model",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200

    model_id = response.model_id

    # Get model instance details
    response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
    @test info.status == 200
    @test !isnothing(response)
    @test response.model_id == model_id
    @test response.model_name == "BetaBernoulli-v1"
    @test response.description == "Testing beta-bernoulli model"
    @test response.arguments == Dict("prior_a" => 1, "prior_b" => 1)
    @test response.created_at < TimeZones.now(TimeZones.localzone())
    @test response.current_episode == "default"

    # Another user should not have access to this model and should not be able to delete it
    TestUtils.with_temporary_token() do
        another_client = TestUtils.TestClient()
        another_models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(another_client)
        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(another_models_api, model_id)
        @test info.status == 404

        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(another_models_api, model_id)
        @test info.status == 404
    end

    # Check that the model still exists, even though another user tried to delete it
    response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
    @test info.status == 200
    @test !isnothing(response)
    @test response.model_name == "BetaBernoulli-v1"

    # Check that the model is visible to the user from the list of all created models
    response, info = TestUtils.RxInferClientOpenAPI.get_model_instances(models_api)
    @test info.status == 200
    @test !isempty(response)
    @test any(m -> m.model_id == model_id, response)

    # Try to delete the model
    response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_id)
    @test info.status == 200
    @test response.message == "Model instance deleted successfully"

    # Check that the model is indeed deleted from user's perspective
    # The model may still exist in the database, but it should not be visible to the user
    response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
    @test info.status == 404
    @test response.error == "Not Found"
    @test response.message == "The requested model instance could not be found"

    # Check that the model is not visible in the list of all created models
    response, info = TestUtils.RxInferClientOpenAPI.get_model_instances(models_api)
    @test info.status == 200
    @test !any(m -> m.model_id == model_id, response)
end

@testitem "401 on create model instance endpoint without authorization" setup = [TestUtils] begin
    client = TestUtils.TestClient(authorized = false)
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1",
        description = "Testing beta-bernoulli model",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 401
    @test response.error == "Unauthorized"
    @test occursin("The request requires authentication", response.message)
end

@testitem "404 on create model instance endpoint with no access to model" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Create a request for a model that the token doesn't have access to
    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "NonExistentModel",
        description = "Attempting to create a non-existent model",
        arguments = Dict("param" => "value")
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    # Check HTTP status code
    @test info.status == 404

    # Verify error response
    @test response.error == "Not Found"
    @test response.message == "The requested model name `NonExistentModel` could not be found"
end

@testitem "404 on create model endpoint with temporary token that has no access to model" setup = [TestUtils] begin
    TestUtils.with_temporary_token(roles = ["arbitrary"]) do
        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        # Create a request for a model that the temporary token doesn't have access to
        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

        # Check HTTP status code
        @test info.status == 404

        # Verify error response
        @test response.error == "Not Found"
        @test response.message == "The requested model name `BetaBernoulli-v1` could not be found"
    end
end

@testitem "200 on get created models instances endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1",
        description = "Testing beta-bernoulli model",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response1, info1 = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    response2, info2 = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info1.status == 200
    @test info2.status == 200

    response, info = TestUtils.RxInferClientOpenAPI.get_model_instances(models_api)
    @test info.status == 200
    @test !isempty(response)
    @test any(m -> m.model_id == response1.model_id, response) # The first model should be visible
    @test any(m -> m.model_id == response2.model_id, response) # The second model should be visible
    @test length(response) >= 2 # Might be more than 2 if there are other tests that create models

    TestUtils.with_temporary_token() do
        another_client = TestUtils.TestClient()
        another_models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(another_client)
        response, info = TestUtils.RxInferClientOpenAPI.get_model_instances(another_models_api)
        @test info.status == 200
        @test isempty(response)
    end

    # Check that the models can be deleted one by one
    dresponse1, dinfo1 = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, response1.model_id)
    @test dinfo1.status == 200
    @test dresponse1.message == "Model instance deleted successfully"

    response, info = TestUtils.RxInferClientOpenAPI.get_model_instances(models_api)
    @test info.status == 200
    @test !isempty(response)
    @test !any(m -> m.model_id == response1.model_id, response) # The first model should be deleted
    @test any(m -> m.model_id == response2.model_id, response) # But the second model should be visible
    @test length(response) >= 1 # There might be other tests that create models

    dresponse2, dinfo2 = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, response2.model_id)
    @test dinfo2.status == 200
    @test dresponse2.message == "Model instance deleted successfully"

    response, info = TestUtils.RxInferClientOpenAPI.get_model_instances(models_api)
    @test info.status == 200
    @test length(response) >= 0 # There might be other tests that create models
    @test !any(m -> m.model_id == response2.model_id, response) # But the second model should be deleted
    @test !any(m -> m.model_id == response1.model_id, response) # And the first one too
end

@testitem "Creating model without arguments should create a model with default values" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    @testset "Absolutely no arguments" begin
        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
        @test info.status == 200
        @test !isnothing(response)

        # Check that the model has default arguments
        response2, info2 = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, response.model_id)
        @test info2.status == 200
        @test !isnothing(response2)
        @test response2.arguments == Dict("prior_a" => 1, "prior_b" => 1)

        # Delete the models at the end of the test
        dresponse, dinfo = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, response.model_id)
        @test dinfo.status == 200
        @test dresponse.message == "Model instance deleted successfully"
    end

    @testset "`a` is specified but `b` is not" begin
        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model", arguments = Dict("prior_a" => 3)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
        @test info.status == 200
        @test !isnothing(response)

        # Check that the model has default arguments
        response2, info2 = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, response.model_id)
        @test info2.status == 200
        @test !isnothing(response2)
        @test response2.arguments == Dict("prior_a" => 3, "prior_b" => 1)

        # Delete the models at the end of the test
        dresponse, dinfo = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, response.model_id)
        @test dinfo.status == 200
        @test dresponse.message == "Model instance deleted successfully"
    end

    @testset "`a` is not specified but `b` is" begin
        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model", arguments = Dict("prior_b" => 3)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
        @test info.status == 200
        @test !isnothing(response)

        # Check that the model has default arguments
        response2, info2 = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, response.model_id)
        @test info2.status == 200
        @test !isnothing(response2)
        @test response2.arguments == Dict("prior_a" => 1, "prior_b" => 3)

        # Delete the models at the end of the test
        dresponse, dinfo = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, response.model_id)
        @test dinfo.status == 200
        @test dresponse.message == "Model instance deleted successfully"
    end
end

@testitem "When creating a model, a default episode should be created automatically" setup = [TestUtils] begin
    using Dates, TimeZones

    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(response)

    model_id = response.model_id

    # Check that the episode is created
    response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
    @test info.status == 200
    @test !isnothing(response)
    @test response.current_episode == "default"

    mcat = response.created_at

    response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_id, "default")
    @test info.status == 200
    @test !isnothing(response)
    @test response.name == "default"
    @test response.created_at < TimeZones.now(TimeZones.localzone())
    @test response.created_at >= mcat
    @test response.model_id == model_id
    @test response.events == [] # no events yet

    # Used to identify the episode in the list of episodes
    cat = response.created_at

    # Check that the episode is visible in the list of episodes
    response, info = TestUtils.RxInferClientOpenAPI.get_episodes(models_api, model_id)
    @test info.status == 200
    @test !isnothing(response)
    @test any(e -> e.name == "default", response)
    @test any(e -> e.created_at == cat, response)

    # Other users should not have access to the episode
    TestUtils.with_temporary_token() do
        another_client = TestUtils.TestClient()
        another_models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(another_client)
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(another_models_api, model_id, "default")
        @test info.status == 404

        response, info = TestUtils.RxInferClientOpenAPI.get_episodes(another_models_api, model_id)
        @test info.status == 404
    end

    # Delete model after the test
    dresponse, dinfo = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_id)
    @test dinfo.status == 200
    @test dresponse.message == "Model instance deleted successfully"

    # List of episodes should not be available anymore 
    response, info = TestUtils.RxInferClientOpenAPI.get_episodes(models_api, model_id)
    @test info.status == 404
end

@testitem "Episodes can be created, deleted and wiped" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)

    @test info.status == 200
    @test !isnothing(response)

    model_id = response.model_id

    response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
    @test info.status == 200
    @test !isnothing(response)
    @test response.current_episode == "default"

    model_created_at = response.created_at

    @testset "Check that the current episode is the default episode" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.current_episode == "default"
    end

    @testset "Create a new episode and check that it is the current episode" begin
        response, info = TestUtils.RxInferClientOpenAPI.create_episode(models_api, model_id, "new_episode")
        @test info.status == 200
        @test !isnothing(response)
        @test response.name == "new_episode"
        @test response.created_at > model_created_at
        @test response.model_id == model_id
        @test response.events == [] # no events yet

        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.current_episode == "new_episode"
    end

    @testset "Check that another episode with the same name cannot be created" begin
        response, info = TestUtils.RxInferClientOpenAPI.create_episode(models_api, model_id, "new_episode")
        @test info.status == 400
        @test response.error == "Bad Request"
        @test response.message == "The requested episode already exists"
    end

    @testset "Retrieve the list of episodes and check that the new episode is present" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episodes(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test any(e -> e.name == "new_episode", response)
        @test any(e -> e.name == "default", response)
    end

    @testset "Check that the default episode cannot be deleted" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_episode(models_api, model_id, "default")
        @test info.status == 400
        @test response.error == "Bad Request"
        @test response.message == "Default episode cannot be deleted, wipe data instead"
    end

    @testset "Create yet another episode and check that it is the current episode" begin
        response, info = TestUtils.RxInferClientOpenAPI.create_episode(models_api, model_id, "yet_another_episode")
        @test info.status == 200
        @test !isnothing(response)

        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.current_episode == "yet_another_episode"
    end

    @testset "Check that the new episode can be deleted, however since it is NOT the current episode, model state is not affected" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_episode(models_api, model_id, "new_episode")
        @test info.status == 200
        @test response.message == "Episode deleted successfully"

        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.current_episode == "yet_another_episode"
    end

    @testset "Retrieve the list of episodes and check that the new episode is not present" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episodes(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test !any(e -> e.name == "new_episode", response)
    end

    @testset "Delete the yet another episode and check that the default episode becomes the current episode" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_episode(models_api, model_id, "yet_another_episode")
        @test info.status == 200
        @test response.message == "Episode deleted successfully"

        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.current_episode == "default"
    end

    @testset "Retrieve the list of episodes and check that only the default episode is present" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episodes(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test any(e -> e.name == "default", response)
        @test !any(e -> e.name == "yet_another_episode", response)
        @test !any(e -> e.name == "new_episode", response)
        @test length(response) == 1

        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance(models_api, model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.current_episode == "default"
    end

    @testset "Wipe the default episode and check that it is empty" begin
        response, info = TestUtils.RxInferClientOpenAPI.wipe_episode(models_api, model_id, "default")
        @test info.status == 200
        @test response.message == "Episode wiped successfully"

        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_id, "default")
        @test info.status == 200
        @test !isnothing(response)
        @test response.events == []
    end
end

@testitem "Inference calls should update the model's state" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    model_instance, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(model_instance)

    @testset "Check that the model's state is empty" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance_state(models_api, model_instance.model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.state["number_of_infer_calls"] == 0
    end

    @testset "Run inference on the model" begin
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))
        inference, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, model_instance.model_id, inference_request)
        @test info.status == 200
        @test !isnothing(inference)
    end

    @testset "Check that the model's state has been updated" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance_state(models_api, model_instance.model_id)
        @test info.status == 200
        @test !isnothing(response)
        @test response.state["number_of_infer_calls"] == 1
    end

    @testset "Delete the model and check that the model's state is not available anymore" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_instance.model_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"

        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance_state(models_api, model_instance.model_id)
        @test info.status == 404
        @test response.error == "Not Found"
        @test response.message == "The requested model instance could not be found"
    end
end

@testitem "Inference requests should populate the episode with events" setup = [TestUtils] begin
    using Dates

    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    model_instance, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(model_instance)

    episode, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
    @test info.status == 200
    @test !isnothing(episode)
    @test episode.name == "default"
    @test episode.model_id == model_instance.model_id

    # Check that the episode is empty before running any inference tasks
    @test episode.events == []

    # By default, the "default" episode is used
    inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))

    event_ids = []

    inference, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, model_instance.model_id, inference_request)

    @test info.status == 200
    @test !isnothing(inference)

    push!(event_ids, inference.event_id)

    @testset "Check that the episode has one event" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test !isnothing(response)
        @test length(response.events) == 1
        @test response.events[1]["data"] == Dict("observation" => 1)
        @test DateTime(response.events[1]["timestamp"]) < Dates.now()
    end

    for i in 1:10
        iter_inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 0))
        iter_inference, iter_info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, model_instance.model_id, iter_inference_request
        )
        @test iter_info.status == 200
        @test !isnothing(iter_inference)

        push!(event_ids, iter_inference.event_id)
    end

    @testset "Check that the episode has 11 events" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test !isnothing(response)
        @test length(response.events) == 11
        @test allunique(e["timestamp"] for e in response.events)
        @test allunique(e["event_id"] for e in response.events)
        @test all(e["event_id"] in event_ids for e in response.events)
    end

    @testset "Delete the model and check that the episode is not accessible anymore" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_instance.model_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"

        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 404
        @test response.error == "Not Found"
        @test response.message == "The requested model could not be found"
    end
end

@testitem "It should be possible to attach metadata to different events" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    model_instance, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(model_instance)

    inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))

    inference1, info1 = TestUtils.RxInferClientOpenAPI.run_inference(models_api, model_instance.model_id, inference_request)
    @test info1.status == 200
    @test !isnothing(inference1)

    inference2, info2 = TestUtils.RxInferClientOpenAPI.run_inference(models_api, model_instance.model_id, inference_request)
    @test info2.status == 200
    @test !isnothing(inference2)

    @testset "Check that the two inference requests have different event ids" begin
        @test inference1.event_id != inference2.event_id
    end

    @testset "Attach metadata to the first inference request" begin
        metadata = Dict("key" => "value", "hello" => "world")
        attach_metadata_request = TestUtils.RxInferClientOpenAPI.AttachMetadataToEventRequest(metadata = metadata)
        response, info = TestUtils.RxInferClientOpenAPI.attach_metadata_to_event(
            models_api, model_instance.model_id, "default", inference1.event_id, attach_metadata_request
        )
        @test info.status == 200
        @test !isnothing(response)
    end

    @testset "Retrieve the episode info and check that the metadata is attached" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test !isnothing(response)

        # Find the event with the first event id
        event_1 = findfirst(e -> e["event_id"] == inference1.event_id, response.events)
        @test !isnothing(event_1)
        @test response.events[event_1]["metadata"] == Dict("key" => "value", "hello" => "world")

        # Other event should not have metadata
        event_2 = findfirst(e -> e["event_id"] == inference2.event_id, response.events)
        @test !isnothing(event_2)
        @test !haskey(response.events[event_2], "metadata")
    end

    @testset "Attach metadata to the second inference request" begin
        metadata = Dict("another_key" => "another_value", "another_hello" => "another_world")
        attach_metadata_request = TestUtils.RxInferClientOpenAPI.AttachMetadataToEventRequest(metadata = metadata)
        response, info = TestUtils.RxInferClientOpenAPI.attach_metadata_to_event(
            models_api, model_instance.model_id, "default", inference2.event_id, attach_metadata_request
        )
        @test info.status == 200
        @test !isnothing(response)
    end

    @testset "Retrieve the episode info and check that the metadata is attached" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test !isnothing(response)

        # Find the event with the second event id
        event_2 = findfirst(e -> e["event_id"] == inference2.event_id, response.events)
        @test !isnothing(event_2)
        @test response.events[event_2]["metadata"] ==
            Dict("another_key" => "another_value", "another_hello" => "another_world")

        # First event should have the same metadata as before
        event_1 = findfirst(e -> e["event_id"] == inference1.event_id, response.events)
        @test !isnothing(event_1)
        @test response.events[event_1]["metadata"] == Dict("key" => "value", "hello" => "world")
    end

    @testset "Delete the model and check that the episode is not accessible anymore and attach metadata should fail too" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_instance.model_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"

        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 404
        @test response.error == "Not Found"
        @test response.message == "The requested model could not be found"

        for event_id in [inference1.event_id, inference2.event_id]
            attach_metadata_request = TestUtils.RxInferClientOpenAPI.AttachMetadataToEventRequest(
                metadata = Dict(
                    "updated_key_after_deletion" => "updated_value_after_deletion",
                    "updated_hello_after_deletion" => "updated_world_after_deletion"
                )
            )
            response, info = TestUtils.RxInferClientOpenAPI.attach_metadata_to_event(
                models_api, model_instance.model_id, "default", event_id, attach_metadata_request
            )
            @test info.status == 404
            @test response.error == "Not Found"
            @test response.message == "The requested model could not be found"
        end
    end
end

@testitem "Inference requests should be able to specify the episode" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    model_instance, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(model_instance)

    @testset "Create episode1" begin
        response, info = TestUtils.RxInferClientOpenAPI.create_episode(models_api, model_instance.model_id, "episode1")
        @test info.status == 200
        @test !isnothing(response)
        @test response.name == "episode1"
    end

    @testset "Create episode2" begin
        response, info = TestUtils.RxInferClientOpenAPI.create_episode(models_api, model_instance.model_id, "episode2")
        @test info.status == 200
        @test !isnothing(response)
        @test response.name == "episode2"
    end

    @testset "Check that episode1 is empty" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "episode1")
        @test info.status == 200
        @test !isnothing(response)
        @test response.events == []
    end

    @testset "Check that episode2 is empty" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "episode2")
        @test info.status == 200
        @test !isnothing(response)
        @test response.events == []
    end

    @testset "Run inference on episode1" begin
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(
            episode_name = "episode1", data = Dict("observation" => 1)
        )

        inference, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, model_instance.model_id, inference_request)
        @test info.status == 200
        @test !isnothing(inference)
    end

    @testset "Run inference on episode2" begin
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(
            episode_name = "episode2", data = Dict("observation" => 0)
        )

        inference, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, model_instance.model_id, inference_request)
        @test info.status == 200
        @test !isnothing(inference)
    end

    @testset "Check that episode1 has one event" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "episode1")
        @test info.status == 200
        @test !isnothing(response)
        @test length(response.events) == 1
        @test response.events[1]["data"] == Dict("observation" => 1)
    end

    @testset "Check that episode2 has one event" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "episode2")
        @test info.status == 200
        @test !isnothing(response)
        @test length(response.events) == 1
        @test response.events[1]["data"] == Dict("observation" => 0)
    end

    @testset "Check that default episode is empty" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test !isnothing(response)
        @test response.events == []
    end

    @testset "Delete the model and check that the episodes are not accessible anymore" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_instance.model_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"

        for episode_name in ["episode1", "episode2", "default"]
            response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, episode_name)
            @test info.status == 404
            @test response.error == "Not Found"
            @test response.message == "The requested model could not be found"
        end
    end
end

@testitem "It should be possible to wipe an episode" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    model_instance, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(model_instance)

    @testset "Create a new episode" begin
        response, info = TestUtils.RxInferClientOpenAPI.create_episode(models_api, model_instance.model_id, "another_episode")
        @test info.status == 200
        @test !isnothing(response)
        @test response.name == "another_episode"
    end

    # Make infer calls on the default episode
    for i in 1:10
        inference_request_1 = TestUtils.RxInferClientOpenAPI.InferRequest(
            episode_name = "default", data = Dict("observation" => 1)
        )
        inference_1, info_1 = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, model_instance.model_id, inference_request_1
        )
        @test info_1.status == 200
    end

    # Make infer calls on the another episode
    for i in 1:10
        inference_request_2 = TestUtils.RxInferClientOpenAPI.InferRequest(
            episode_name = "another_episode", data = Dict("observation" => 1)
        )
        inference_2, info_2 = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, model_instance.model_id, inference_request_2
        )
        @test info_2.status == 200
    end

    @testset "Check that the another_episode has 10 events" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "another_episode")
        @test info.status == 200
        @test !isnothing(response)
        @test length(response.events) == 10
    end

    @testset "Wipe the default episode" begin
        response, info = TestUtils.RxInferClientOpenAPI.wipe_episode(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test response.message == "Episode wiped successfully"
    end

    @testset "The another episode should not be affected" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "another_episode")
        @test info.status == 200
        @test !isnothing(response)
        @test length(response.events) == 10
    end

    @testset "Check that the default episode is empty" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test !isnothing(response)
        @test response.events == []
    end

    @testset "Wipe the another episode" begin
        response, info = TestUtils.RxInferClientOpenAPI.wipe_episode(models_api, model_instance.model_id, "another_episode")
        @test info.status == 200
        @test response.message == "Episode wiped successfully"
    end

    @testset "Check that the another episode is empty" begin
        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "another_episode")
        @test info.status == 200
        @test !isnothing(response)
        @test response.events == []
    end

    @testset "Delete the model and check that the episodes are not accessible anymore" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_instance.model_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"

        for episode_name in ["another_episode", "default"]
            response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, episode_name)
            @test info.status == 404
            @test response.error == "Not Found"
            @test response.message == "The requested model could not be found"
        end
    end
end

@testitem "It should be possible to specify the timestamp of the inference request manually" setup = [TestUtils] begin
    using Dates, TimeZones

    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    model_instance, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(model_instance)

    timestamp = ZonedDateTime(Dates.now(), localzone())

    @testset "Run inference with manual timestamp" begin
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(
            data = Dict("observation" => 1), timestamp = timestamp
        )

        inference, info = TestUtils.RxInferClientOpenAPI.run_inference(models_api, model_instance.model_id, inference_request)
        @test info.status == 200
        @test !isnothing(inference)

        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 200
        @test !isnothing(response)
        @test length(response.events) == 1
        @test response.events[1]["data"] == Dict("observation" => 1)
        @test ZonedDateTime(DateTime(response.events[1]["timestamp"]), localzone()) == timestamp
    end

    @testset "Delete the model and check that the episode is not accessible anymore" begin
        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, model_instance.model_id)
        @test info.status == 200
        @test response.message == "Model instance deleted successfully"

        response, info = TestUtils.RxInferClientOpenAPI.get_episode_info(models_api, model_instance.model_id, "default")
        @test info.status == 404
        @test response.error == "Not Found"
        @test response.message == "The requested model could not be found"
    end
end

@testitem "It should be possible to learn from previous observations" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
        model_name = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
    )

    model_instance, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
    @test info.status == 200
    @test !isnothing(model_instance)

    for i in 1:10
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 1))
        iter_inference, iter_info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, model_instance.model_id, inference_request
        )
        @test iter_info.status == 200
        @test !isnothing(iter_inference)
    end

    learning_request = TestUtils.RxInferClientOpenAPI.LearnRequest()
    learning_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, model_instance.model_id, learning_request)
    @test info.status == 200
    @test !isnothing(learning_response)

    @test learning_response.learned_parameters["posterior_a"] == 11
    @test learning_response.learned_parameters["posterior_b"] == 1

    # Check that the model state has been updated
    model_state, info = TestUtils.RxInferClientOpenAPI.get_model_instance_state(models_api, model_instance.model_id)
    @test info.status == 200
    @test !isnothing(model_state)
    @test model_state.state["posterior_a"] == 11
    @test model_state.state["posterior_b"] == 1

    for i in 1:10
        inference_request = TestUtils.RxInferClientOpenAPI.InferRequest(data = Dict("observation" => 0))
        iter_inference, iter_info = TestUtils.RxInferClientOpenAPI.run_inference(
            models_api, model_instance.model_id, inference_request
        )
        @test iter_info.status == 200
        @test !isnothing(iter_inference)
    end

    learning_request = TestUtils.RxInferClientOpenAPI.LearnRequest()
    learning_response, info = TestUtils.RxInferClientOpenAPI.run_learning(models_api, model_instance.model_id, learning_request)
    @test info.status == 200
    @test !isnothing(learning_response)

    @test learning_response.learned_parameters["posterior_a"] == 11
    @test learning_response.learned_parameters["posterior_b"] == 11
end
