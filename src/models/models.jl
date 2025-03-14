module Models

using YAML
using Base.ScopedValues

struct VersionedModel
    name::String
    version::String
    description::String
    author::String
    private::Bool
    mod::Module
end

include("dispatcher.jl")

end