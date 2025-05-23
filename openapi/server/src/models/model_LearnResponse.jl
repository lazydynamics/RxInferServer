# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""LearnResponse

    LearnResponse(;
        learned_parameters=nothing,
    )

    - learned_parameters::Dict{String, Any} : A dictionary of learned parameters and their values
"""
Base.@kwdef mutable struct LearnResponse <: OpenAPI.APIModel
    learned_parameters::Union{Nothing, Dict{String, Any}} = nothing

    function LearnResponse(learned_parameters, )
        o = new(learned_parameters, )
        OpenAPI.validate_properties(o)
        return o
    end
end # type LearnResponse

const _property_types_LearnResponse = Dict{Symbol,String}(Symbol("learned_parameters")=>"Dict{String, Any}", )
OpenAPI.property_type(::Type{ LearnResponse }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_LearnResponse[name]))}

function OpenAPI.check_required(o::LearnResponse)
    o.learned_parameters === nothing && (return false)
    true
end

function OpenAPI.validate_properties(o::LearnResponse)
    OpenAPI.validate_property(LearnResponse, Symbol("learned_parameters"), o.learned_parameters)
end

function OpenAPI.validate_property(::Type{ LearnResponse }, name::Symbol, val)

end
