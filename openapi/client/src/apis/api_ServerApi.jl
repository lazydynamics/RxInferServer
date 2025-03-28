# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.

struct ServerApi <: OpenAPI.APIClientImpl
    client::OpenAPI.Clients.Client
end

"""
The default API base path for APIs in `ServerApi`.
This can be used to construct the `OpenAPI.Clients.Client` instance.
"""
basepath(::Type{ ServerApi }) = "http://localhost:8000/v1"

const _returntypes_get_server_info_ServerApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => ServerInfo,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
)

function _oacinternal_get_server_info(_api::ServerApi; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_server_info_ServerApi, "/info", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get server information

Returns information about the server, such as the RxInferServer version, RxInfer version, Julia version, server edition and API version

Params:

Return: ServerInfo, OpenAPI.Clients.ApiResponse
"""
function get_server_info(_api::ServerApi; _mediaType=nothing)
    _ctx = _oacinternal_get_server_info(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_server_info(_api::ServerApi, response_stream::Channel; _mediaType=nothing)
    _ctx = _oacinternal_get_server_info(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_ping_server_ServerApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => PingResponse,
)

function _oacinternal_ping_server(_api::ServerApi; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_ping_server_ServerApi, "/ping", [])
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Health check endpoint

Simple endpoint to check if the server is alive and running

Params:

Return: PingResponse, OpenAPI.Clients.ApiResponse
"""
function ping_server(_api::ServerApi; _mediaType=nothing)
    _ctx = _oacinternal_ping_server(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function ping_server(_api::ServerApi, response_stream::Channel; _mediaType=nothing)
    _ctx = _oacinternal_ping_server(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

export get_server_info
export ping_server
