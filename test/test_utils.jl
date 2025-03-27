@testmodule TestUtils begin
    using Test, RxInferServer
    using Base.ScopedValues

    import Mongoc
    import RxInferClientOpenAPI
    import RxInferClientOpenAPI.OpenAPI.Clients: Client, set_header
    import RxInferClientOpenAPI: ServerApi, AuthenticationApi, ModelsApi

    const TEST_SERVER_URL = "http://localhost:8000$(RxInferServer.API_PATH_PREFIX)"
    const TEST_TOKEN = ScopedValue{String}(RxInferServer.RXINFER_SERVER_DEV_TOKEN())

    current_test_token() = TEST_TOKEN[]

    function TestClient(; authorized = true, token = current_test_token())
        _client = Client(TEST_SERVER_URL)
        _token = @something token RxInferServer.RXINFER_SERVER_DEV_TOKEN()

        if authorized && !isnothing(_token)
            set_header(_client, "Authorization", "Bearer $(_token)")
        end

        if authorized && isnothing(_token)
            error(
                "Cannot be authorized if no token is provided. Use `RXINFER_SERVER_DEV_TOKEN` environment variable to set a default token for testing purposes."
            )
        end

        return _client
    end

    function with_temporary_token(f::Function; roles::Vector{String} = ["user"])
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
            with(TEST_TOKEN => token) do
                f()
            end
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

@testitem "TestClient should be able to generate a token for a role" setup = [TestUtils] begin
    client = TestUtils.TestClient()
    @test client.headers["Authorization"] == "Bearer $(RxInferServer.RXINFER_SERVER_DEV_TOKEN())"
end

@testitem "TestClient should be able to generate a temporary token with an arbitrary role" setup = [TestUtils] begin
    using Mongoc

    created_token = Ref{String}("")
    default_token = TestUtils.current_test_token()
    TestUtils.with_temporary_token(roles = ["arbitrary", "arbitrary2"]) do
        client = TestUtils.TestClient()
        temporary_token = TestUtils.current_test_token()
        @test temporary_token != default_token
        @test client.headers["Authorization"] == "Bearer $(temporary_token)"
        created_token[] = temporary_token

        # Check the role of the token in the database 
        RxInferServer.Database.with_connection() do
            collection = RxInferServer.Database.collection("tokens")
            query = Mongoc.BSON("token" => created_token[])
            result = Mongoc.find_one(collection, query)
            @test result["roles"] == ["arbitrary", "arbitrary2"]
        end
    end

    # Check that the token was deleted from the database
    RxInferServer.Database.with_connection() do
        collection = RxInferServer.Database.collection("tokens")
        query = Mongoc.BSON("token" => created_token[])
        result = Mongoc.find_one(collection, query)
        @test isnothing(result)
    end
end
