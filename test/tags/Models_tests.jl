@testitem "200 on /models endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    server_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
    response, info = TestUtils.RxInferClientOpenAPI.get_models(server_api)

    @test info.status == 200
    @test !isempty(response.models)

    # Check that the CoinToss model is present, which should be located under the `models` directory
    @test any(m -> m.name === "BetaBernoulli-v1", response.models)
end

@testitem "200 on /models endpoint but arbitrary role should return empty list" setup = [TestUtils] begin
    TestUtils.with_temporary_token(role = "arbitrary") do
        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
        response, info = TestUtils.RxInferClientOpenAPI.get_models(models_api)
        @test info.status == 200
        @test isempty(response.models)
    end
end

@testitem "200 on /models endpoint with mixed roles should return non-empty list" setup = [TestUtils] begin
    for role in ["arbitrary,user", "user,arbitrary"]
        TestUtils.with_temporary_token(role = role) do
            client = TestUtils.TestClient()
            models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
            response, info = TestUtils.RxInferClientOpenAPI.get_models(models_api)
            @test info.status == 200
            @test !isempty(response.models)
            @test any(m -> m.name === "BetaBernoulli-v1", response.models)
        end
    end
end

@testitem "401 on /models endpoint without authorization" setup = [TestUtils] begin
    client = TestUtils.TestClient(authorized = false)
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.get_models(models_api)

    @test info.status == 401
    @test response.error == "Unauthorized"
    @test occursin("The request requires authentication", response.message)
end

@testitem "200 on model info endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Get model info
    response, info = TestUtils.RxInferClientOpenAPI.get_model_details(models_api, "BetaBernoulli-v1")

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

@testitem "404 on model info endpoint if user's role does not have access" setup = [TestUtils] begin
    TestUtils.with_temporary_token(role = "arbitrary") do
        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
        response, info = TestUtils.RxInferClientOpenAPI.get_model_details(models_api, "BetaBernoulli-v1")

        @test info.status == 404
        @test response.error == "Not Found"
        @test response.message == "The requested model could not be found"
    end
end

@testitem "200 on model info endpoint with mixed roles" setup = [TestUtils] begin
    for role in ["arbitrary,user", "user,arbitrary"]
        TestUtils.with_temporary_token(role = role) do
            client = TestUtils.TestClient()
            models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
            response, info = TestUtils.RxInferClientOpenAPI.get_model_details(models_api, "BetaBernoulli-v1")
            @test info.status == 200
        end
    end
end

@testitem "401 on model info endpoint without authorization" setup = [TestUtils] begin
    client = TestUtils.TestClient(authorized = false)
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.get_model_details(models_api, "BetaBernoulli-v1")

    @test info.status == 401
    @test response.error == "Unauthorized"
    @test occursin("The request requires authentication", response.message)
end

@testitem "404 on non-existent model info endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Try to get info for a non-existent model
    response, info = TestUtils.RxInferClientOpenAPI.get_model_details(models_api, "NonExistentModel")

    # Check HTTP status code
    @test info.status == 404

    # Verify error response
    @test response.error == "Not Found"
    @test response.message == "The requested model could not be found"
end

@testitem "200 on create model, get info and delete model" setup = [TestUtils] begin
    using Dates, TimeZones

    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_request = TestUtils.RxInferClientOpenAPI.CreateModelRequest(
        model = "BetaBernoulli-v1",
        description = "Testing beta-bernoulli model",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model(models_api, create_model_request)
    @test info.status == 200

    model_id = response.model_id

    # Get model info
    response, info = TestUtils.RxInferClientOpenAPI.get_model_info(models_api, model_id)
    @test info.status == 200
    @test !isnothing(response)
    @test response.model_id == model_id
    @test response.model_name == "BetaBernoulli-v1"
    @test response.description == "Testing beta-bernoulli model"
    @test response.arguments == Dict("prior_a" => 1, "prior_b" => 1)
    @test response.created_at < TimeZones.now(TimeZones.localzone())

    # Another user should not have access to this model and should not be able to delete it
    TestUtils.with_temporary_token() do
        another_client = TestUtils.TestClient()
        another_models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(another_client)
        response, info = TestUtils.RxInferClientOpenAPI.get_model_info(another_models_api, model_id)
        @test info.status == 404

        response, info = TestUtils.RxInferClientOpenAPI.delete_model(another_models_api, model_id)
        @test info.status == 404
    end

    # Check that the model still exists, even though another user tried to delete it
    response, info = TestUtils.RxInferClientOpenAPI.get_model_info(models_api, model_id)
    @test info.status == 200
    @test !isnothing(response)
    @test response.model_name == "BetaBernoulli-v1"

    # Check that the model is visible to the user from the list of all created models
    response, info = TestUtils.RxInferClientOpenAPI.get_created_models_info(models_api)
    @test info.status == 200
    @test !isempty(response)
    @test any(m -> m.model_id == model_id, response)

    # Try to delete the model
    response, info = TestUtils.RxInferClientOpenAPI.delete_model(models_api, model_id)
    @test info.status == 200
    @test response.message == "Model deleted successfully"

    # Check that the model is indeed deleted from user's perspective
    # The model may still exist in the database, but it should not be visible to the user
    response, info = TestUtils.RxInferClientOpenAPI.get_model_info(models_api, model_id)
    @test info.status == 404
    @test response.error == "Not Found"
    @test response.message == "The requested model could not be found"

    # Check that the model is not visible in the list of all created models
    response, info = TestUtils.RxInferClientOpenAPI.get_created_models_info(models_api)
    @test info.status == 200
    @test !any(m -> m.model_id == model_id, response)
end

@testitem "401 on create model endpoint without authorization" setup = [TestUtils] begin
    client = TestUtils.TestClient(authorized = false)
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_request = TestUtils.RxInferClientOpenAPI.CreateModelRequest(
        model = "BetaBernoulli-v1",
        description = "Testing beta-bernoulli model",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model(models_api, create_model_request)

    @test info.status == 401
    @test response.error == "Unauthorized"
    @test occursin("The request requires authentication", response.message)
end

@testitem "404 on create model endpoint with no access to model" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Create a request for a model that the token doesn't have access to
    create_model_request = TestUtils.RxInferClientOpenAPI.CreateModelRequest(
        model = "NonExistentModel",
        description = "Attempting to create a non-existent model",
        arguments = Dict("param" => "value")
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model(models_api, create_model_request)

    # Check HTTP status code
    @test info.status == 404

    # Verify error response
    @test response.error == "Not Found"
    @test response.message == "The requested model could not be found"
end

@testitem "404 on create model endpoint with temporary token that has no access to model" setup = [TestUtils] begin
    TestUtils.with_temporary_token(role = "arbitrary") do
        client = TestUtils.TestClient()
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        # Create a request for a model that the temporary token doesn't have access to
        create_model_request = TestUtils.RxInferClientOpenAPI.CreateModelRequest(
            model = "BetaBernoulli-v1", description = "Testing beta-bernoulli model"
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model(models_api, create_model_request)

        # Check HTTP status code
        @test info.status == 404

        # Verify error response
        @test response.error == "Not Found"
        @test response.message == "The requested model could not be found"
    end
end

@testitem "200 on get created models info endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_request = TestUtils.RxInferClientOpenAPI.CreateModelRequest(
        model = "BetaBernoulli-v1",
        description = "Testing beta-bernoulli model",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response1, info1 = TestUtils.RxInferClientOpenAPI.create_model(models_api, create_model_request)
    response2, info2 = TestUtils.RxInferClientOpenAPI.create_model(models_api, create_model_request)
    @test info1.status == 200
    @test info2.status == 200

    response, info = TestUtils.RxInferClientOpenAPI.get_created_models_info(models_api)
    @test info.status == 200
    @test !isempty(response)
    @test any(m -> m.model_id == response1.model_id, response)
    @test any(m -> m.model_id == response2.model_id, response)
    @test length(response) >= 2 # Might be more than 2 if there are other tests that create models

    TestUtils.with_temporary_token() do
        another_client = TestUtils.TestClient()
        another_models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(another_client)
        response, info = TestUtils.RxInferClientOpenAPI.get_created_models_info(another_models_api)
        @test info.status == 200
        @test isempty(response)
    end

    # Check that the models can be deleted one by one
    dresponse1, dinfo1 = TestUtils.RxInferClientOpenAPI.delete_model(models_api, response1.model_id)
    @test dinfo1.status == 200
    @test dresponse1.message == "Model deleted successfully"

    response, info = TestUtils.RxInferClientOpenAPI.get_created_models_info(models_api)
    @test info.status == 200
    @test !isempty(response)
    @test !any(m -> m.model_id == response1.model_id, response)
    @test any(m -> m.model_id == response2.model_id, response)
    @test length(response) >= 1

    dresponse2, dinfo2 = TestUtils.RxInferClientOpenAPI.delete_model(models_api, response2.model_id)
    @test dinfo2.status == 200
    @test dresponse2.message == "Model deleted successfully"

    response, info = TestUtils.RxInferClientOpenAPI.get_created_models_info(models_api)
    @test info.status == 200
    @test isempty(response)
    @test !any(m -> m.model_id == response2.model_id, response)
    @test !any(m -> m.model_id == response1.model_id, response)
    @test length(response) >= 0
end