
function get_models(req::HTTP.Request)::HTTP.Response
    # Filter out private models
    models = Models.get_models()

    # Create a list of lightweight model info
    model_list = map(models) do model
        return RxInferServerOpenAPI.LightweightModelInfo(name = model.name, description = model.description)
    end

    return HTTP.Response(200, RxInferServerOpenAPI.ModelList(model_list))
end

function get_model_info(req::HTTP.Request, model_name::String)::HTTP.Response
    model = Models.get_model(model_name)

    if isnothing(model)
        return HTTP.Response(
            404,
            RxInferServerOpenAPI.ErrorResponse(error = "Not Found", message = "The requested model could not be found")
        )
    end

    return HTTP.Response(
        200,
        RxInferServerOpenAPI.ModelInfo(
            info = RxInferServerOpenAPI.LightweightModelInfo(name = model.name, description = model.description),
            config = model.config
        )
    )
end
