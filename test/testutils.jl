@testmodule TestUtils begin
    using Test, RxInferServer
    using ScopedValues

    import Mongoc
    import RxInferServer.RxInferClientOpenAPI
    import RxInferServer.RxInferClientOpenAPI.OpenAPI.Clients: Client, set_header
    import RxInferServer.RxInferClientOpenAPI: ServerApi, AuthenticationApi, ModelsApi

    const TEST_SERVER_URL = "http://localhost:8000$(RxInferServer.API_PATH_PREFIX)"

    projectdir(paths...) = joinpath(@__DIR__, "..", paths...)

    test_token(roles::Nothing) = RxInferServer.DEFAULT_DEV_TOKEN
    test_token(roles::Vector{String}) = "$(RxInferServer.DEFAULT_DEV_TOKEN):$(join(roles, ","))"

    function TestClient(; headers = [], authorized = true, roles = ["test-only"], token = test_token(roles))
        _client = Client(TEST_SERVER_URL)

        if authorized
            set_header(_client, "Authorization", "Bearer $token")
        end

        for (key, value) in headers
            set_header(_client, key, value)
        end

        return _client
    end

    function with_temporary_token(f::Function; roles::Vector{String} = ["test-only"])
        _client = TestClient(authorized = false)

        auth = RxInferClientOpenAPI.AuthenticationApi(_client)
        response, info = RxInferClientOpenAPI.token_generate(auth)

        if info.status != 200
            error("Failed to generate a temporary token for roles `$roles`")
        end

        token = string(response.token)

        # Update the token with the specified role in the database
        RxInferServer.Database.with_connection(verbose = false) do
            collection = RxInferServer.Database.collection("tokens")
            query = Mongoc.BSON("token" => token)
            update = Mongoc.BSON("\$set" => Mongoc.BSON("roles" => roles))
            result = Mongoc.update_one(collection, query, update)

            if result["matchedCount"] != 1
                error("Failed to update token with roles `$roles`", result)
            end
        end

        try
            f(token)
        finally
            # Delete the token from the database
            RxInferServer.Database.with_connection(verbose = false) do
                collection = RxInferServer.Database.collection("tokens")
                query = Mongoc.BSON("token" => token)
                result = Mongoc.delete_one(collection, query)

                if result["deletedCount"] != 1
                    error("Failed to delete token from the database")
                end
            end
        end
    end
end

@testitem "projectdir should return the correct path" setup = [TestUtils] begin
    @test TestUtils.projectdir() == joinpath(@__DIR__, "..")
    @test TestUtils.projectdir("models") == joinpath(@__DIR__, "..", "models")
end

@testitem "TestClient should have the correct authorization header" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    @test occursin("Bearer ", client.headers["Authorization"])
    @test !isempty(replace(client.headers["Authorization"], "Bearer " => ""))
end

@testitem "TestClient should support arbitrary roles" setup = [TestUtils] begin
    for roles in [["arbitrary", "arbitrary2"], ["arbitrary"], ["user", "admin"]]
        client = TestUtils.TestClient(roles = roles)
        api = TestUtils.AuthenticationApi(client)
        response, info = TestUtils.RxInferClientOpenAPI.token_roles(api)
        @test info.status == 200
        @test response.roles == roles
    end
end

@testitem "TestClient should be able to generate a temporary token" setup = [TestUtils] begin
    TestUtils.with_temporary_token() do token
        client = TestUtils.TestClient(token = token)
        api = TestUtils.AuthenticationApi(client)
        response, info = TestUtils.RxInferClientOpenAPI.token_roles(api)
        @test info.status == 200
    end
end

@testitem "TestClient should be able to generate a temporary token with an arbitrary role" setup = [TestUtils] begin
    TestUtils.with_temporary_token(roles = ["arbitrary"]) do token
        client = TestUtils.TestClient(token = token)
        api = TestUtils.AuthenticationApi(client)
        response, info = TestUtils.RxInferClientOpenAPI.token_roles(api)
        @test info.status == 200
        @test response.roles == ["arbitrary"]
    end
end
