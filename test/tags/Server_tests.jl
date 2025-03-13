@testitem "200 on /ping endpoint regardless of authentication" setup = [TestUtils] begin
    authorized_client = TestUtils.TestClient(authorized = true)
    nonauthorized_client = TestUtils.TestClient(authorized = false)

    for client in [authorized_client, nonauthorized_client]
        server_api = TestUtils.RxInferClientOpenAPI.ServerApi(client)
        response, info = TestUtils.RxInferClientOpenAPI.ping_server(server_api)
        @test info.status == 200
        @test response.status == "ok"
    end
end

@testitem "401 on /info endpoint without `Authorization`" setup = [TestUtils] begin
    client     = TestUtils.TestClient(authorized = false)
    server_api = TestUtils.RxInferClientOpenAPI.ServerApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.get_server_info(server_api)

    @test info.status == 401
    @test response.error == "Unauthorized"
    @test occursin("The request requires authentication", response.message)
end

@testitem "200 on /info endpoint with `Authorization`" setup = [TestUtils] begin
    using TOML

    project_toml = TOML.parse(read(joinpath(@__DIR__, "..", "..", "Project.toml"), String))
    server_version = VersionNumber(project_toml["version"])
    minimum_julia_version = VersionNumber(project_toml["compat"]["julia"])
    minimum_rxinfer_version = VersionNumber(project_toml["compat"]["RxInfer"])

    client     = TestUtils.TestClient()
    server_api = TestUtils.RxInferClientOpenAPI.ServerApi(client)

    response, info = TestUtils.RxInferClientOpenAPI.get_server_info(server_api)

    @test info.status === 200
    @test !isempty(response.rxinfer_version) && VersionNumber(response.rxinfer_version) >= minimum_rxinfer_version
    @test !isempty(response.server_version) && VersionNumber(response.server_version) == server_version
    @test !isempty(response.julia_version) && VersionNumber(response.julia_version) >= minimum_julia_version
    @test !isempty(response.server_edition)
end
