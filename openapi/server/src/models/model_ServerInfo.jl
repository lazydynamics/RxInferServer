# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""ServerInfo

    ServerInfo(;
        rxinfer_version=nothing,
        server_version=nothing,
        julia_version=nothing,
    )

    - rxinfer_version::String : The version of RxInfer that the server is using
    - server_version::String : The version of the RxInferServer
    - julia_version::String : The version of Julia
"""
Base.@kwdef mutable struct ServerInfo <: OpenAPI.APIModel
    rxinfer_version::Union{Nothing, String} = nothing
    server_version::Union{Nothing, String} = nothing
    julia_version::Union{Nothing, String} = nothing

    function ServerInfo(rxinfer_version, server_version, julia_version, )
        OpenAPI.validate_property(ServerInfo, Symbol("rxinfer_version"), rxinfer_version)
        OpenAPI.validate_property(ServerInfo, Symbol("server_version"), server_version)
        OpenAPI.validate_property(ServerInfo, Symbol("julia_version"), julia_version)
        return new(rxinfer_version, server_version, julia_version, )
    end
end # type ServerInfo

const _property_types_ServerInfo = Dict{Symbol,String}(Symbol("rxinfer_version")=>"String", Symbol("server_version")=>"String", Symbol("julia_version")=>"String", )
OpenAPI.property_type(::Type{ ServerInfo }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_ServerInfo[name]))}

function check_required(o::ServerInfo)
    o.rxinfer_version === nothing && (return false)
    o.server_version === nothing && (return false)
    true
end

function OpenAPI.validate_property(::Type{ ServerInfo }, name::Symbol, val)



end
