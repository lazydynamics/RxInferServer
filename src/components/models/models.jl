"""
    Models

Module responsible for loading, managing, and accessing RxInfer probabilistic models in the server.
Handles model discovery, loading, and provides access to models through a dispatcher.
"""
module Models

using YAML, ScopedValues, Serialization

"""
    RXINFER_SERVER_MODELS_LOCATIONS

The directories where the models are stored. Colon-separated list of directories.
This can be configured using the `RXINFER_SERVER_MODELS_LOCATIONS` environment variable.
Defaults to `"models:custom_models"` if not specified. 
Note that the `custom_models` directory is git-ignored by default.
Use the `custom_models` directory to experiment with custom models without committing them to the repository.

```julia
ENV["RXINFER_SERVER_MODELS_LOCATIONS"] = "/path/to/models1:/path/to/models2"
RxInferServer.serve()
```
"""
RXINFER_SERVER_MODELS_LOCATIONS() = split(get(ENV, "RXINFER_SERVER_MODELS_LOCATIONS", "models:custom_models"), ':')

"""
    RXINFER_SERVER_LOAD_TEST_MODELS

Environment variable to determine whether to load test models. Can be either `true` or `false`.
The test models are located under the `test` directory of the project.

!!! note 
    `pkgdir(@__MODULE__)` is used to locate the project's directory and load the test models from there.
    This means that the test models can be loaded only when the package is installed in the development mode.
    Do not use this variable in the production environment.
"""
RXINFER_SERVER_LOAD_TEST_MODELS() = lowercase(get(ENV, "RXINFER_SERVER_LOAD_TEST_MODELS", "false")) == "true"

# This is fixed and cannot be changed
RXINFER_SERVER_TEST_MODELS_LOCATION() = relpath(joinpath(pkgdir(@__MODULE__), "test", "models_for_testing"), pwd())

include("model_utils.jl")
include("model_config.jl")
include("loaded_model.jl")
include("dispatcher.jl")

const models_dispatcher = ScopedValue{ModelsDispatcher}()

"""
    with_models(f::Function; locations = RXINFER_SERVER_MODELS_LOCATIONS())

Execute function `f` with an initialized models dispatcher for the given locations.
Creates a scoped context where models can be accessed via the dispatcher.

# Arguments
- `f::Function`: The function to execute within the models context
- `locations`: The locations to scan for models, defaults to `RXINFER_SERVER_MODELS_LOCATIONS()`
"""
function with_models(f::F; locations = RXINFER_SERVER_MODELS_LOCATIONS()) where {F}
    with(models_dispatcher => ModelsDispatcher(locations)) do
        f()
    end
end

"""
    get_models_dispatcher()::ModelsDispatcher

Get the current active models dispatcher. Must be called within a `with_models` context.

# Returns
- `ModelsDispatcher`: The active models dispatcher

# Throws
- `ErrorException`: If called outside of a `with_models` context
"""
function get_models_dispatcher()::ModelsDispatcher
    dispatcher = @inline Base.ScopedValues.get(models_dispatcher)
    return @something dispatcher error("Models dispatcher is not initialized. Use `with_models` to initialize it.")
end

"""
    get_models()

Get all non-private models using the current dispatcher.

# Returns
- A collection of all non-private loaded models
"""
get_models() = get_models(get_models_dispatcher())

"""
    get_model(model_name::String)

Get a specific model by name from the current dispatcher.

# Arguments
- `model_name::String`: The name of the model to retrieve

# Returns
- `LoadedModel` or `nothing`: The requested model if found, otherwise `nothing`
"""
get_model(model_name::String) = get_model(get_models_dispatcher(), model_name)

function loaded_models_banner_hint()
    locations = RXINFER_SERVER_MODELS_LOCATIONS()
    hint = "Model locations are $(join(map(l -> string('`', l, '`', ifelse(isdir(l), "", " (missing)")), locations), ", "))"

    if RXINFER_SERVER_LOAD_TEST_MODELS()
        hint = string(hint, " and test models `", RXINFER_SERVER_TEST_MODELS_LOCATION(), "`")
    end

    return hint
end

end
