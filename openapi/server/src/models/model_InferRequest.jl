# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""InferRequest

    InferRequest(;
        data=nothing,
        timestamp=nothing,
        episode_name="default",
    )

    - data::Dict{String, Any} : Model-specific data to run inference on
    - timestamp::ZonedDateTime : Timestamp of the inference request, used to mark the event in the episode
    - episode_name::String : Name of the episode to run inference on
"""
Base.@kwdef mutable struct InferRequest <: OpenAPI.APIModel
    data::Union{Nothing, Dict{String, Any}} = nothing
    timestamp::Union{Nothing, ZonedDateTime} = nothing
    episode_name::Union{Nothing, String} = "default"

    function InferRequest(data, timestamp, episode_name, )
        o = new(data, timestamp, episode_name, )
        OpenAPI.validate_properties(o)
        return o
    end
end # type InferRequest

const _property_types_InferRequest = Dict{Symbol,String}(Symbol("data")=>"Dict{String, Any}", Symbol("timestamp")=>"ZonedDateTime", Symbol("episode_name")=>"String", )
OpenAPI.property_type(::Type{ InferRequest }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_InferRequest[name]))}

function OpenAPI.check_required(o::InferRequest)
    o.data === nothing && (return false)
    true
end

function OpenAPI.validate_properties(o::InferRequest)
    OpenAPI.validate_property(InferRequest, Symbol("data"), o.data)
    OpenAPI.validate_property(InferRequest, Symbol("timestamp"), o.timestamp)
    OpenAPI.validate_property(InferRequest, Symbol("episode_name"), o.episode_name)
end

function OpenAPI.validate_property(::Type{ InferRequest }, name::Symbol, val)


    if name === Symbol("timestamp")
        OpenAPI.validate_param(name, "InferRequest", :format, val, "date-time")
    end

end
