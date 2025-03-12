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