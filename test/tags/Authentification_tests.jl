@testitem "Generate token should generate a valid token that can be used to access protected endpoints" setup = [
    TestUtils
] begin
    client = TestUtils.TestClient(authorized = false)
    api    = TestUtils.RxInferClientOpenAPI.AuthenticationApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.generate_token(api)
    token = response.token

    @test info.status == 200
    @test !isnothing(response.token)
    @test !isempty(response.token)

    authorized_client = TestUtils.TestClient(authorized = true, token = token)

    server_api = TestUtils.RxInferClientOpenAPI.ServerApi(authorized_client)
    response, info = TestUtils.RxInferClientOpenAPI.get_server_info(server_api)

    @test info.status == 200

    # It should return the same token if we call the endpoint again but authorized
    authorized_client = TestUtils.TestClient(authorized = true, token = token)
    authorized_api = TestUtils.RxInferClientOpenAPI.AuthenticationApi(authorized_client)
    response, info = TestUtils.RxInferClientOpenAPI.generate_token(authorized_api)

    @test info.status == 200
    @test response.token == token

    # Drop the token from the database
    RxInferServer.Database.with_connection() do
        collection = RxInferServer.Database.collection("tokens")
        reply = RxInferServer.Mongoc.delete_one(collection, RxInferServer.Mongoc.BSON("token" => token))
        @test reply["deletedCount"] == 1
    end
end
