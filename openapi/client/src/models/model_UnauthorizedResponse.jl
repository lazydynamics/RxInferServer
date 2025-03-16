# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""UnauthorizedResponse

    UnauthorizedResponse(;
        error=nothing,
        message=nothing,
    )

    - error::String : Error type, always \&quot;Unauthorized\&quot; for this error
    - message::String : Detailed message explaining why authentication failed
"""
Base.@kwdef mutable struct UnauthorizedResponse <: OpenAPI.APIModel
    error::Union{Nothing, String} = nothing
    message::Union{Nothing, String} = nothing

    function UnauthorizedResponse(error, message, )
        OpenAPI.validate_property(UnauthorizedResponse, Symbol("error"), error)
        OpenAPI.validate_property(UnauthorizedResponse, Symbol("message"), message)
        return new(error, message, )
    end
end # type UnauthorizedResponse

const _property_types_UnauthorizedResponse = Dict{Symbol,String}(Symbol("error")=>"String", Symbol("message")=>"String", )
OpenAPI.property_type(::Type{ UnauthorizedResponse }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_UnauthorizedResponse[name]))}

function check_required(o::UnauthorizedResponse)
    o.error === nothing && (return false)
    o.message === nothing && (return false)
    true
end

function OpenAPI.validate_property(::Type{ UnauthorizedResponse }, name::Symbol, val)

    if name === Symbol("error")
        OpenAPI.validate_param(name, "UnauthorizedResponse", :enum, val, ["Unauthorized"])
    end


end
