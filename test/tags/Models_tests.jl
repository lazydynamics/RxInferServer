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

@testitem "200 on create model endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    create_model_request = RxInferServerOpenAPI.CreateModelRequest(
        model = "BetaBernoulli-v1",
        description = "Testing beta-bernoulli model",
        arguments = Dict("prior_a" => 1, "prior_b" => 1)
    )

    response, info = TestUtils.RxInferClientOpenAPI.create_model(models_api, create_model_request)
    @test info.status == 200
end
