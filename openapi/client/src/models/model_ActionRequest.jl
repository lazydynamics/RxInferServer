# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""ActionRequest

    ActionRequest(;
        data=nothing,
        timestamp=nothing,
        episode_name="default",
    )

    - data::Dict{String, Any} : Model-specific data to run action on
    - timestamp::ZonedDateTime : Timestamp of the action request, used to mark the event in the episode
    - episode_name::String : Name of the episode to run action on
"""
Base.@kwdef mutable struct ActionRequest <: OpenAPI.APIModel
    data::Union{Nothing, Dict{String, Any}} = nothing
    timestamp::Union{Nothing, ZonedDateTime} = nothing
    episode_name::Union{Nothing, String} = "default"

    function ActionRequest(data, timestamp, episode_name, )
        OpenAPI.validate_property(ActionRequest, Symbol("data"), data)
        OpenAPI.validate_property(ActionRequest, Symbol("timestamp"), timestamp)
        OpenAPI.validate_property(ActionRequest, Symbol("episode_name"), episode_name)
        return new(data, timestamp, episode_name, )
    end
end # type ActionRequest

const _property_types_ActionRequest = Dict{Symbol,String}(Symbol("data")=>"Dict{String, Any}", Symbol("timestamp")=>"ZonedDateTime", Symbol("episode_name")=>"String", )
OpenAPI.property_type(::Type{ ActionRequest }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_ActionRequest[name]))}

function check_required(o::ActionRequest)
    o.data === nothing && (return false)
    true
end

function OpenAPI.validate_property(::Type{ ActionRequest }, name::Symbol, val)


    if name === Symbol("timestamp")
        OpenAPI.validate_param(name, "ActionRequest", :format, val, "date-time")
    end

end
