using HTTP, Pkg

const SERVER_EDITION = get(ENV, "RXINFER_SERVER_EDITION", "CommunityEdition")

function ping_server(req::HTTP.Request)::RxInferServerOpenAPI.PingResponse
    return RxInferServerOpenAPI.PingResponse(status = "ok")
end

function get_server_info(req::HTTP.Request)::RxInferServerOpenAPI.ServerInfo
    return RxInferServerOpenAPI.ServerInfo(
        rxinfer_version = string(pkgversion(RxInfer)),
        server_version = string(pkgversion(RxInferServer)),
        server_edition = SERVER_EDITION,
        julia_version = string(VERSION),
        api_version = "v1"
    )
end
