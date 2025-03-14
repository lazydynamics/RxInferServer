
function get_models(req::HTTP.Request)::RxInferServerOpenAPI.ModelList
    dispatcher = Models.get_models_dispatcher()

    # Filter out private models
    public_models = filter(m -> !m.private, collect(values(dispatcher.models)))

    # Create a list of lightweight model info
    model_list = map(public_models) do model
        RxInferServerOpenAPI.LightweightModelInfo(name = model.name, version = model.version, description = model.description)
    end

    return RxInferServerOpenAPI.ModelList(model_list)
end