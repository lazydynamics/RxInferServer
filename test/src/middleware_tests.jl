@testitem "ErrorResponse should return 400 status code" setup = [TestUtils] begin
    using HTTP, RxInferServer

    request = HTTP.Request("POST", "test", HTTP.Headers())
    error_response = RxInferServer.RxInferServerOpenAPI.ErrorResponse()

    response = RxInferServer.postprocess_response(request, error_response)

    @test response.status == 400
end

@testitem "UnauthorizedResponse should return 401 status code" setup = [TestUtils] begin
    using HTTP, RxInferServer

    request = HTTP.Request("POST", "test", HTTP.Headers())
    unauthorized_response = RxInferServer.RxInferServerOpenAPI.UnauthorizedResponse()

    response = RxInferServer.postprocess_response(request, unauthorized_response)

    @test response.status == 401
end

@testitem "NotFoundResponse should return 404 status code" setup = [TestUtils] begin
    using HTTP, RxInferServer

    request = HTTP.Request("POST", "test", HTTP.Headers())
    not_found_response = RxInferServer.RxInferServerOpenAPI.NotFoundResponse()

    response = RxInferServer.postprocess_response(request, not_found_response)

    @test response.status == 404
end
