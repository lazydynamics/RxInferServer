"""
    LoadedModel

Represents a loaded RxInfer probabilistic model with its metadata and implementation.

# Fields
- `path::String`: Path to the model directory
- `name::String`: Name of the model
- `description::String`: Description of the model's purpose and functionality
- `author::String`: Author or organization that created the model
- `private::Bool`: Whether the model is private (not listed in API responses)
- `config::Dict{String, Any}`: Configuration parameters for the model
- `mod::Module`: Julia module containing the model's implementation
"""
Base.@kwdef struct LoadedModel
    path::String
    name::String
    description::String
    author::String
    private::Bool
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

# Implementation Notes
The model directory must contain:
1. `model.jl`: Julia code implementing the model
2. `config.yaml`: Configuration file with required fields:
   - `name`: Model name
   - `description`: Model description
   - `author`: Model author
   - `private`: Boolean indicating if model is private

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

    name = config["name"]
    description = config["description"]
    author = config["author"]
    private = config["private"]

    @debug "Including model's code from `$potential_model_file`"
    mod = Module(Symbol(:LoadedModel, name))
    Base.include(mod, potential_model_file)

    @debug "Model `$(name)` has been loaded from `$path`" name description author private
    return LoadedModel(
        path = path,
        name = name,
        description = description,
        author = author,
        private = private,
        config = config,
        mod = mod
    )
end
