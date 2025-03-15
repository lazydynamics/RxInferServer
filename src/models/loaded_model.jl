Base.@kwdef struct LoadedModel
    path::String
    name::String
    description::String
    author::String
    private::Bool
    config::Dict{String, Any}
    mod::Module
end

function LoadedModel(path::String)::LoadedModel
    potential_model_file = joinpath(path, "model.jl")
    potential_model_config = joinpath(path, "config.yaml")

    isfile(potential_model_file) || error("Cannot create `LoadedModel` from `$path` because it does not have a `model.jl` file.")
    isfile(potential_model_config) || error("Cannot create `LoadedModel` from `$path` because it does not have a `config.yaml` file.")

    @debug "Reading model's config from `$potential_model_config`"
    config = YAML.load_file(potential_model_config)

    name = config["name"]
    description = config["description"]
    author = config["author"]
    private = config["private"]

    @debug "Including model's code from `$potential_model_file`"
    mod = Module(Symbol(:LoadedModel, name))
    Base.include(mod, potential_model_file)

    @debug "Model `$(name)` has been loaded from `$path`" name description author private
    return LoadedModel(path = path, name = name, description = description, author = author, private = private, config = config, mod = mod)
end