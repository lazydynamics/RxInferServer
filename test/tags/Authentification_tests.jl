@testitem "Generate token should generate a valid token that can be used to access protected endpoints" setup = [TestUtils] begin
    client = TestUtils.TestClient(authorized = false)
    api    = TestUtils.RxInferClientOpenAPI.AuthenticationApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.generate_token(api)

    @test info.status == 200
    @test !isnothing(response.token)
    @test !isempty(response.token)

    authorized_client = TestUtils.TestClient(authorized = true, token = response.token)

    server_api = TestUtils.RxInferClientOpenAPI.ServerApi(authorized_client)
    response, info = TestUtils.RxInferClientOpenAPI.get_server_info(server_api)

    @test info.status == 200
end