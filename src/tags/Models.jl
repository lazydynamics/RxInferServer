
function get_models(req::HTTP.Request)::RxInferServerOpenAPI.ModelList
    # Filter out private models
    models = Models.get_models()

    # Create a list of lightweight model info
    model_list = map(models) do model
        return RxInferServerOpenAPI.LightweightModelInfo(name = model.name, description = model.description)
    end

    return RxInferServerOpenAPI.ModelList(model_list)
end

function get_model_info(req::HTTP.Request, model_name::String)::RxInferServerOpenAPI.ModelInfo
    error("not implemented")
end
