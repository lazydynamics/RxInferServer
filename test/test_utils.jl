@testmodule TestUtils begin
    using Test, RxInferServer
    using Base.ScopedValues

    import RxInferClientOpenAPI
    import RxInferClientOpenAPI.OpenAPI.Clients: Client, set_header
    import RxInferClientOpenAPI: ServerApi, AuthenticationApi

    export TestClient
    export ServerApi, AuthenticationApi

    const TEST_SERVER_URL = "http://localhost:8000$(RxInferServer.API_PATH_PREFIX)"

    function TestClient(; authorized = true, token = RxInferServer.RXINFER_SERVER_DEV_TOKEN)
        _client = Client(TEST_SERVER_URL)
        if authorized
            set_header(_client, "Authorization", "Bearer $(token)")
        end
        return _client
    end
end
