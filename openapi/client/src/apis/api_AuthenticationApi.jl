# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.

struct AuthenticationApi <: OpenAPI.APIClientImpl
    client::OpenAPI.Clients.Client
end

"""
The default API base path for APIs in `AuthenticationApi`.
This can be used to construct the `OpenAPI.Clients.Client` instance.
"""
basepath(::Type{ AuthenticationApi }) = "http://localhost:8000/v1"

const _returntypes_generate_token_AuthenticationApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => TokenResponse,
    Regex("^" * replace("400", "x"=>".") * "\$") => ErrorResponse,
)

function _oacinternal_generate_token(_api::AuthenticationApi; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "POST", _returntypes_generate_token_AuthenticationApi, "/token", [])
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Generate authentication token

Generates a new authentication token for accessing protected endpoints

Params:

Return: TokenResponse, OpenAPI.Clients.ApiResponse
"""
function generate_token(_api::AuthenticationApi; _mediaType=nothing)
    _ctx = _oacinternal_generate_token(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function generate_token(_api::AuthenticationApi, response_stream::Channel; _mediaType=nothing)
    _ctx = _oacinternal_generate_token(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

export generate_token
