# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""LearnRequest

    LearnRequest(;
        episodes=nothing,
    )

    - episodes::Vector{String} : List of episodes to learn from
"""
Base.@kwdef mutable struct LearnRequest <: OpenAPI.APIModel
    episodes::Union{Nothing, Vector{String}} = nothing

    function LearnRequest(episodes, )
        o = new(episodes, )
        OpenAPI.validate_properties(o)
        return o
    end
end # type LearnRequest

const _property_types_LearnRequest = Dict{Symbol,String}(Symbol("episodes")=>"Vector{String}", )
OpenAPI.property_type(::Type{ LearnRequest }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_LearnRequest[name]))}

function OpenAPI.check_required(o::LearnRequest)
    o.episodes === nothing && (return false)
    true
end

function OpenAPI.validate_properties(o::LearnRequest)
    OpenAPI.validate_property(LearnRequest, Symbol("episodes"), o.episodes)
end

function OpenAPI.validate_property(::Type{ LearnRequest }, name::Symbol, val)

end
