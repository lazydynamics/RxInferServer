struct ModelsDispatcher
    models::Dict{String, VersionedModel}
end

function scan_models(path)::ModelsDispatcher
    if !isdir(path)
        error("Cannot scan models in $path because it does not exist or is not a directory")
    end

    models = Dict{String, VersionedModel}()

    for directory in readdir(path)
        potential_model_dir = joinpath(path, directory)

        if isdir(potential_model_dir)
            model = scan_potential_model(potential_model_dir)
            if !isnothing(model)
                models[model.name] = model
            end
        end
    end

    return ModelsDispatcher(models)
end

function scan_potential_model(path)::Union{VersionedModel, Nothing}
    potential_model_file = joinpath(path, "model.jl")
    potential_model_config = joinpath(path, "config.yaml")

    if !isfile(potential_model_file)
        @warn "Directory $path does not have a model.jl file. Skipping..."
        return nothing
    end

    if !isfile(potential_model_config)
        @warn "Directory $path does not have a config.yaml file. Skipping..."
        return nothing
    end

    try
        config = YAML.load_file(potential_model_config)

        name = config["name"]
        version = config["version"]
        description = config["description"]
        author = config["author"]
        private = config["private"]

        mod = Module(Symbol(name, version))

        Base.include(mod, potential_model_file)

        return VersionedModel(name, version, description, author, private, mod)
    catch e
        @warn "Error loading config.yaml file for model $path: $e"
        return nothing
    end
end

const models_dispatcher = ScopedValue{ModelsDispatcher}()

function with_models(f::F, path) where {F}
    with(models_dispatcher => scan_models(path)) do
        f()
    end
end

function get_models_dispatcher()
    dispatcher = @inline Base.ScopedValues.get(models_dispatcher)
    return @something dispatcher error("Models dispatcher is not initialized. Use `with_models` to initialize it.")
end