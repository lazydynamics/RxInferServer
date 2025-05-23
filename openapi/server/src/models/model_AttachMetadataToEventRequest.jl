# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""AttachMetadataToEventRequest

    AttachMetadataToEventRequest(;
        metadata=nothing,
    )

    - metadata::Dict{String, Any} : Metadata to attach to the event
"""
Base.@kwdef mutable struct AttachMetadataToEventRequest <: OpenAPI.APIModel
    metadata::Union{Nothing, Dict{String, Any}} = nothing

    function AttachMetadataToEventRequest(metadata, )
        o = new(metadata, )
        OpenAPI.validate_properties(o)
        return o
    end
end # type AttachMetadataToEventRequest

const _property_types_AttachMetadataToEventRequest = Dict{Symbol,String}(Symbol("metadata")=>"Dict{String, Any}", )
OpenAPI.property_type(::Type{ AttachMetadataToEventRequest }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_AttachMetadataToEventRequest[name]))}

function OpenAPI.check_required(o::AttachMetadataToEventRequest)
    o.metadata === nothing && (return false)
    true
end

function OpenAPI.validate_properties(o::AttachMetadataToEventRequest)
    OpenAPI.validate_property(AttachMetadataToEventRequest, Symbol("metadata"), o.metadata)
end

function OpenAPI.validate_property(::Type{ AttachMetadataToEventRequest }, name::Symbol, val)

end
