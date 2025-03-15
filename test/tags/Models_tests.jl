@testitem "200 on /models endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    server_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)
    response, info = TestUtils.RxInferClientOpenAPI.get_models(server_api)

    @test info.status == 200
    @test !isempty(response.models)

    # Check that the CoinToss model is present, which should be located under the `models` directory
    @test any(m -> m.name === "CoinToss-v1", response.models)
end

@testitem "200 on model info endpoint" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

    # Get model info
    response, info = TestUtils.RxInferClientOpenAPI.get_model_info(models_api, "CoinToss-v1")
    
    # Check HTTP status code
    @test info.status == 200

    # Verify model properties
    @test !isnothing(response.info)
    @test !isnothing(response.config)
    
    # Verify basic info
    @test response.info.name == "CoinToss-v1"
    @test response.info.description == "A simple coin toss model"
    
    # Verify config content
    @test isa(response.config, Dict)
    @test response.config["name"] == "CoinToss-v1"
    @test response.config["description"] == "A simple coin toss model"
    @test response.config["author"] == "Lazy Dynamics"
end
