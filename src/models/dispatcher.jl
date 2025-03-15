
Base.@kwdef struct ModelsDispatcher{L, M}
    locations::L
    models::M
end

function ModelsDispatcher(locations)::ModelsDispatcher
    models = Dict{String, LoadedModel}()

    @debug "Attempt to load models from `$locations`"
    load_models!(models, locations)

    return ModelsDispatcher(locations = locations, models = models)
end

function load_models!(models, locations)
    for location in locations
        if !isdir(location)
            error("Cannot create `ModelsDispatcher` from `$location` because it does not exist or is not a directory")
        end
        for directory in readdir(location)
            potential_model_dir = joinpath(location, directory)
            if isdir(potential_model_dir)
                @debug "Found potential model's directory `$directory`"
                model = LoadedModel(potential_model_dir)
                if haskey(models, model.name)
                    error(
                        "Cannot create `ModelsDispatcher` from `$location` because it contains multiple models with the same name: `$(model.name)`. The first one has already been loaded from `$(models[model.name].path)`."
                    )
                end
                models[model.name] = model
                @debug "Model `$(model.name)` has been loaded successfully from `$(model.path)`"
            end
        end
    end
end

function reload!(dispatcher::ModelsDispatcher)
    @debug "Reloading models from `$(dispatcher.locations)`"
    # Empty the models dictionary and reload the models
    load_models!(empty!(dispatcher.models), dispatcher.locations)
    @debug "Models have been reloaded"
end

"""
    get_models(dispatcher::ModelsDispatcher)

Get all non-private models from the given dispatcher
"""
function get_models(dispatcher::ModelsDispatcher)
    return filter(m -> !m.private, collect(values(dispatcher.models)))
end

"""
    get_model(dispatcher::ModelsDispatcher, model_name::String)

Get a model from the given dispatcher
"""
function get_model(dispatcher::ModelsDispatcher, model_name::String)::Union{LoadedModel, Nothing}
    if !haskey(dispatcher.models, model_name)
        return nothing
    end
    return dispatcher.models[model_name]
end
