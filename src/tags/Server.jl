using HTTP

function get_server_info(req::HTTP.Request)::RxInferServerOpenAPI.ServerInfo
    return RxInferServerOpenAPI.ServerInfo(
        rxinfer_version="0.0.0",
        server_version="0.0.7",
        julia_version=string(VERSION)
    )
end