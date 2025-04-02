"""
    LoadedModel

Represents a loaded RxInfer probabilistic model with its metadata and implementation.

# Fields
- `path::String`: Path to the model directory
- `name::String`: Name of the model
- `description::String`: Description of the model's purpose and functionality
- `author::String`: Author or organization that created the model
- `roles::Vector{String}`: List of roles that can access the model
- `config::Dict{String, Any}`: Configuration parameters for the model
- `mod::Module`: Julia module containing the model's implementation
"""
Base.@kwdef struct LoadedModel
    path::String
    name::String
    description::String
    author::String
    roles::Vector{String}
    config::Dict{String, Any}
    mod::Module
end

"""
    LoadedModel(path::String)::LoadedModel

Load a model from the specified directory path.

# Arguments
- `path::String`: Path to the directory containing model.jl and config.yaml

# Returns
- `LoadedModel`: The loaded model with all its metadata and implementation

# Throws
- `ErrorException`: If model.jl or config.yaml is missing, or if required config fields are missing

The model code is loaded into a separate module to isolate its namespace.
"""
function LoadedModel(path::String)::LoadedModel
    potential_model_file = joinpath(path, "model.jl")
    potential_model_config = joinpath(path, "config.yaml")

    isfile(potential_model_file) ||
        error("Cannot create `LoadedModel` from `$path` because it does not have a `model.jl` file.")
    isfile(potential_model_config) ||
        error("Cannot create `LoadedModel` from `$path` because it does not have a `config.yaml` file.")

    @debug "Reading model's config from `$potential_model_config`"
    config = YAML.load_file(potential_model_config)

    header_validation = validate_model_config_header(config)
    isnothing(header_validation) || throw(header_validation)

    name = config["name"]
    description = config["description"]
    author = config["author"]
    roles = config["roles"]

    @debug "Including model's code from `$potential_model_file`"
    mod = Module(Symbol(:LoadedModel, name))
    Base.include(mod, potential_model_file)

    @debug "Model `$(name)` has been loaded from `$path`" name author roles
    return LoadedModel(
        path = path, name = name, description = description, author = author, roles = roles, config = config, mod = mod
    )
end

function dispatch(model::LoadedModel, operation::Symbol, args...; kwargs...)
    func = getproperty(model.mod, operation)
    return func(args...; kwargs...)
end
