@testitem "401 on /info endpoint without `Authorization`" setup=[TestHTTP] begin
    response = TestHTTP.get("/info", status_exception = false)
    @test response.status == 401
end

@testitem "200 on /info endpoint with `Authorization`" setup=[TestHTTP] begin
    import RxInferServer.RxInferServerOpenAPI: ServerInfo

    TestHTTP.with_auth() do
        response = TestHTTP.get("/info", status_exception = false)
        @test response.status == 200

        info = TestHTTP.response_body_as(response, ServerInfo)
        @show info
    end
end

@testitem "blahblha" begin 
    import RxInferServer: Client, ServerApi
    import RxInferServer.RxInferClientOpenAPI: get_server_info

    client = Client("http://localhost:8000/v1")
    server_api = ServerApi(client)

    response, info = get_server_info(server_api)
    @test info.status === 401

    client = Client("http://localhost:8000/v1", 
        headers = Dict("Authorization" => "Bearer $(RxInferServer.DEV_TOKEN)")
    )
    server_api = ServerApi(client)

    response, info = get_server_info(server_api)
    @test info.status === 200
    @test !isempty(response.rxinfer_version)
    @test !isempty(response.server_version)
    @test !isempty(response.server_edition)
    @test !isempty(response.julia_version)
end