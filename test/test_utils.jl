@testmodule TestUtils begin
    using Test, RxInferServer
    using Base.ScopedValues

    import RxInferClientOpenAPI
    import RxInferClientOpenAPI.OpenAPI.Clients: Client, set_header
    import RxInferClientOpenAPI: ServerApi, AuthenticationApi

    export TestClient
    export ServerApi, AuthenticationApi

    function TestClient(; authorized = true)
        _client = Client("http://localhost:8000/v1")
        if authorized
            set_header(_client, "Authorization", "Bearer $(RxInferServer.DEV_TOKEN)")
        end
        return _client
    end
end
