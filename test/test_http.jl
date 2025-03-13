# This module is used to redirect tests to the HTTP server
# Running in the application in background in the docker container
@testmodule TestHTTP begin
    using Test, RxInferServer, HTTP, JSON
    using Base.ScopedValues

    const current_token = ScopedValue("")

    function test_server_url(path::String)
        return "http://localhost:8000$(RxInferServer.API_PATH_PREFIX)$(path)"
    end

    function get(path, headers = HTTP.Header[], body = HTTP.nobody; kwargs...)
        if !isempty(current_token[])
            headers = vcat(headers, [HTTP.Header("Authorization", "Bearer $(current_token[])")])
        end
        return HTTP.get(test_server_url(path), headers, body; kwargs...)
    end

    function with_auth(f::F) where {F}
        with(f, current_token => RxInferServer.DEV_TOKEN)
    end

    function response_body_as(response::HTTP.Response, ::Type{T}) where {T}
        body = String(response.body)
        json = JSON.parse(body)
        return RxInferServer.RxInferServerOpenAPI.OpenAPI.convert(T, json)
    end
end
