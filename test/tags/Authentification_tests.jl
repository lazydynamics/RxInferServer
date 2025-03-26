@testitem "Generate token should generate a valid token that can be used to access protected endpoints" setup = [
    TestUtils
] begin
    client = TestUtils.TestClient(authorized = false)
    api    = TestUtils.RxInferClientOpenAPI.AuthenticationApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.token_generate(api)
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
    response, info = TestUtils.RxInferClientOpenAPI.token_generate(authorized_api)

    @test info.status == 200
    @test response.token == token

    # Drop the token from the database
    RxInferServer.Database.with_connection() do
        collection = RxInferServer.Database.collection("tokens")
        reply = RxInferServer.Mongoc.delete_one(collection, RxInferServer.Mongoc.BSON("token" => token))
        @test reply["deletedCount"] == 1
    end
end

@testitem "Get token roles should return 401 if the token is not authorized" setup = [
    TestUtils
] begin
    client = TestUtils.TestClient(authorized = false)
    api    = TestUtils.RxInferClientOpenAPI.AuthenticationApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.token_roles(api)
    @test info.status == 401
end

@testitem "Get token roles should return the list of roles for a token #1" setup = [
    TestUtils
] begin
    client = TestUtils.TestClient(authorized = true)
    api    = TestUtils.RxInferClientOpenAPI.AuthenticationApi(client)
    
    response, info = TestUtils.RxInferClientOpenAPI.token_roles(api)
    @test info.status == 200
    @test "user" in response.roles
end

@testitem "Get token roles should return the list of roles for a token #2" setup = [
    TestUtils
] begin
    TestUtils.with_temporary_token(roles = [ "private-role-1", "private-role-2" ]) do
        client = TestUtils.TestClient(authorized = true)
        api    = TestUtils.RxInferClientOpenAPI.AuthenticationApi(client)
        
        response, info = TestUtils.RxInferClientOpenAPI.token_roles(api)
        @test info.status == 200
        @test "private-role-1" in response.roles
        @test "private-role-2" in response.roles
        @test length(response.roles) == 2
        @test !("user" in response.roles)
    end
end