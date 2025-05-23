# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""AvailableModel_details
Primary model details. Note that these are also included in the &#x60;config&#x60; object. 

    AvailableModelDetails(;
        name=nothing,
        description=nothing,
        author=nothing,
        roles=nothing,
    )

    - name::String : Name of the model (usually with the version identifier, e.g. \&quot;BetaBernoulli-v1\&quot;)
    - description::String : Brief description of the model
    - author::String : Author of the model
    - roles::Vector{String} : List of roles that can access the model
"""
Base.@kwdef mutable struct AvailableModelDetails <: OpenAPI.APIModel
    name::Union{Nothing, String} = nothing
    description::Union{Nothing, String} = nothing
    author::Union{Nothing, String} = nothing
    roles::Union{Nothing, Vector{String}} = nothing

    function AvailableModelDetails(name, description, author, roles, )
        o = new(name, description, author, roles, )
        OpenAPI.validate_properties(o)
        return o
    end
end # type AvailableModelDetails

const _property_types_AvailableModelDetails = Dict{Symbol,String}(Symbol("name")=>"String", Symbol("description")=>"String", Symbol("author")=>"String", Symbol("roles")=>"Vector{String}", )
OpenAPI.property_type(::Type{ AvailableModelDetails }, name::Symbol) = Union{Nothing,eval(Base.Meta.parse(_property_types_AvailableModelDetails[name]))}

function OpenAPI.check_required(o::AvailableModelDetails)
    true
end

function OpenAPI.validate_properties(o::AvailableModelDetails)
    OpenAPI.validate_property(AvailableModelDetails, Symbol("name"), o.name)
    OpenAPI.validate_property(AvailableModelDetails, Symbol("description"), o.description)
    OpenAPI.validate_property(AvailableModelDetails, Symbol("author"), o.author)
    OpenAPI.validate_property(AvailableModelDetails, Symbol("roles"), o.roles)
end

function OpenAPI.validate_property(::Type{ AvailableModelDetails }, name::Symbol, val)




end
