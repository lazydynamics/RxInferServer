# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""CreateModelInstanceResponse

    CreateModelInstanceResponse(;
        instance_id=nothing,
    )

    - instance_id::String : Unique identifier for the created model instance
"""
Base.@kwdef mutable struct CreateModelInstanceResponse <: OpenAPI.APIModel
    instance_id::Union{Nothing, String} = nothing

    function CreateModelInstanceResponse(instance_id, )
        o = new(instance_id, )
        OpenAPI.validate_properties(o)
        return o
    end
end # type CreateModelInstanceResponse

const _property_types_CreateModelInstanceResponse = Dict{Symbol,String}(Symbol("instance_id")=>"String", )
OpenAPI.property_type(::Type{ CreateModelInstanceResponse }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_CreateModelInstanceResponse[name]))}

function OpenAPI.check_required(o::CreateModelInstanceResponse)
    o.instance_id === nothing && (return false)
    true
end

function OpenAPI.validate_properties(o::CreateModelInstanceResponse)
    OpenAPI.validate_property(CreateModelInstanceResponse, Symbol("instance_id"), o.instance_id)
end

function OpenAPI.validate_property(::Type{ CreateModelInstanceResponse }, name::Symbol, val)

    if name === Symbol("instance_id")
        OpenAPI.validate_param(name, "CreateModelInstanceResponse", :format, val, "uuid")
    end
end
