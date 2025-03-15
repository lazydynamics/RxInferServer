using HTTP, Pkg

"""
The edition of the RxInfer server.
This can be configured using the `RXINFER_SERVER_EDITION` environment variable.
This setting is used to identify the server edition in the server information endpoint and has no functional impact on server behavior.
Defaults to "CommunityEdition" if not specified.

```julia
# Set server edition
ENV["RXINFER_SERVER_EDITION"] = "CommunityEdition"
```
"""
const RXINFER_SERVER_EDITION = get(ENV, "RXINFER_SERVER_EDITION", "CommunityEdition")

function ping_server(req::HTTP.Request)::RxInferServerOpenAPI.PingResponse
    return RxInferServerOpenAPI.PingResponse(status = "ok")
end

function get_server_info(req::HTTP.Request)::RxInferServerOpenAPI.ServerInfo
    return RxInferServerOpenAPI.ServerInfo(
        rxinfer_version = string(pkgversion(RxInfer)),
        server_version = string(pkgversion(RxInferServer)),
        server_edition = RXINFER_SERVER_EDITION,
        julia_version = string(VERSION),
        api_version = "v1"
    )
end
