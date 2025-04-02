"""
    ModelsDispatcher

A dispatcher that manages loaded models from specified locations.
Responsible for model discovery, loading, and providing access to models.

# Fields
- `locations::L`: The locations where models are stored
- `models::M`: Dictionary mapping model names to loaded model instances
"""
Base.@kwdef struct ModelsDispatcher{L, M}
    locations::L
    models::M
end

"""
    ModelsDispatcher(locations)::ModelsDispatcher

Construct a ModelsDispatcher by scanning the provided locations for models.

# Arguments
- `locations`: List of directories to scan for models

# Returns
- `ModelsDispatcher`: A dispatcher containing all models found in the specified locations

# Throws
- `ErrorException`: If a location does not exist or if duplicate model names are found
"""
function ModelsDispatcher(locations)::ModelsDispatcher
    models = Dict{String, LoadedModel}()

    if RXINFER_SERVER_LOAD_TEST_MODELS()
        @debug "RXINFER_SERVER_LOAD_TEST_MODELS is set to `true`, adding test models from `$(RXINFER_SERVER_TEST_MODELS_LOCATION())` to the `locations` list"
        locations = vcat(locations, [RXINFER_SERVER_TEST_MODELS_LOCATION()])
    end

    @debug "Attempt to load models from `$locations`"
    load_models!(models, locations)

    return ModelsDispatcher(locations = locations, models = models)
end

"""
    load_models!(models, locations)

Load models from the specified locations into the models dictionary.

# Arguments
- `models`: Dictionary to populate with loaded models (name => LoadedModel)
- `locations`: List of directories to scan for models

# Throws
- `ErrorException`: If a location does not exist or if duplicate model names are found
"""
function load_models!(models, locations)
    for location in locations
        if !isdir(location)
            @warn "Cannot load models from `$location` because it does not exist or is not a directory"
            continue
        end
        for directory in readdir(location)
            potential_model_dir = joinpath(location, directory)
            if isdir(potential_model_dir)
                @debug "Found potential model's directory `$directory`"
                try
                    model = LoadedModel(potential_model_dir)
                    if haskey(models, model.name)
                        error(
                            "Cannot create `ModelsDispatcher` from `$location` because it contains multiple models with the same name: `$(model.name)`. The first one has already been loaded from `$(models[model.name].path)`."
                        )
                    end
                    models[model.name] = model
                    @debug "Model `$(model.name)` has been added to the dispatcher"
                catch e
                    @error "Error loading model from `$potential_model_dir`" exception = (e, catch_backtrace())
                end
            end
        end
    end
end

"""
    reload!(dispatcher::ModelsDispatcher)

Reload all models from the dispatcher's locations, updating the dispatcher's models.
Used for hot-reloading models when their files change.

# Arguments
- `dispatcher::ModelsDispatcher`: The dispatcher to reload models for

!!! warning
    This function completely replaces the models dictionary with newly loaded models,
    allowing for model updates, additions, and removals to be recognized. Indented for interactive use only.
"""
function reload!(dispatcher::ModelsDispatcher)
    @debug "Reloading models from `$(dispatcher.locations)`"
    # Empty the models dictionary and reload the models
    load_models!(empty!(dispatcher.models), dispatcher.locations)
    @debug "Models have been reloaded"
end

"""
    get_models(dispatcher::ModelsDispatcher; role = nothing)

Get all non-private models from the given dispatcher.

# Arguments
- `dispatcher::ModelsDispatcher`: The dispatcher to get models from
- `roles::Union{Vector{String}, Nothing}`: The roles to filter models by (optional)

# Returns
- A collection of all non-private loaded models
"""
function get_models(dispatcher::ModelsDispatcher)
    return collect(values(dispatcher.models))
end

"""
    get_model(dispatcher::ModelsDispatcher, model_name::String)

Get a specific model by name from the dispatcher.

# Arguments
- `dispatcher::ModelsDispatcher`: The dispatcher to get the model from
- `model_name::String`: The name of the model to retrieve

# Returns
- `LoadedModel` or `nothing`: The requested model if found, otherwise `nothing`
"""
function get_model(dispatcher::ModelsDispatcher, model_name::String)::Union{LoadedModel, Nothing}
    if !haskey(dispatcher.models, model_name)
        return nothing
    end
    return dispatcher.models[model_name]
end

function dispatch(dispatcher::ModelsDispatcher, model_name::String, operation::Symbol, args...; kwargs...)
    model = get_model(dispatcher, model_name)
    if isnothing(model)
        error("Cannot dispatch operation `$operation` on model `$model_name` because it is not loaded")
    end
    return dispatch(model, operation, args...; kwargs...)
end
