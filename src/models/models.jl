module Models

using YAML, Base.ScopedValues

"""
    RXINFER_SERVER_MODELS_LOCATIONS

The directories where the models are stored. Colon-separated list of directories.
This can be configured using the `RXINFER_SERVER_MODELS_LOCATIONS` environment variable.
Defaults to `"models"` if not specified.

```julia
ENV["RXINFER_SERVER_MODELS_LOCATIONS"] = "/path/to/models1:/path/to/models2"
RxInferServer.serve()
```
"""
RXINFER_SERVER_MODELS_LOCATIONS() = split(get(ENV, "RXINFER_SERVER_MODELS_LOCATIONS", "models"), ':')

include("loaded_model.jl")
include("dispatcher.jl")

const models_dispatcher = ScopedValue{ModelsDispatcher}()

function with_models(f::F; locations = RXINFER_SERVER_MODELS_LOCATIONS()) where {F}
    with(models_dispatcher => ModelsDispatcher(locations)) do
        f()
    end
end

function get_models_dispatcher()::ModelsDispatcher
    dispatcher = @inline Base.ScopedValues.get(models_dispatcher)
    return @something dispatcher error("Models dispatcher is not initialized. Use `with_models` to initialize it.")
end

"""
    get_models()

Get all non-private models using the current dispatcher
"""
get_models() = get_models(get_models_dispatcher())

"""
    get_model(model_name::String)

Get a model from the current dispatcher
"""
get_model(model_name::String) = get_model(get_models_dispatcher(), model_name)

end
