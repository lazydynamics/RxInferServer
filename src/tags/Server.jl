using HTTP, Pkg

"""
The server edition identifier.
This can be configured using the `RXINFER_SERVER_EDITION` environment variable.
This setting is used to identify the server edition in the server information endpoint and has no functional impact on server behavior.
Defaults to "CommunityEdition" if not specified.

```julia
# Set server edition via environment variable
ENV["RXINFER_SERVER_EDITION"] = "EnterpriseEdition"
RxInferServer.serve()
```
"""
RXINFER_SERVER_EDITION() = get(ENV, "RXINFER_SERVER_EDITION", "CommunityEdition")

function ping_server(req::HTTP.Request)::HTTP.Response
    return HTTP.Response(200, RxInferServerOpenAPI.PingResponse(status = "ok"))
end

function get_server_info(req::HTTP.Request)::HTTP.Response
    return HTTP.Response(
        200,
        RxInferServerOpenAPI.ServerInfo(
            rxinfer_version = string(pkgversion(RxInfer)),
            server_version = string(pkgversion(RxInferServer)),
            server_edition = RXINFER_SERVER_EDITION(),
            julia_version = string(VERSION),
            api_version = "v1"
        )
    )
end
