
function get_models(req::HTTP.Request)::HTTP.Response
    # Filter out private models
    models = Models.get_models()

    # Filter models by role if provided
    roles = current_roles()

    filtered_models = filter(models) do model
        return any(r -> r in roles, model.roles)
    end

    # Create a list of lightweight model info
    model_list = map(filtered_models) do model
        return RxInferServerOpenAPI.LightweightModelDetails(name = model.name, description = model.description)
    end

    return HTTP.Response(200, RxInferServerOpenAPI.ModelList(model_list))
end

function get_model_details(req::HTTP.Request, model_name::String)::HTTP.Response
    model = Models.get_model(model_name)

    if isnothing(model)
        return HTTP.Response(
            404,
            RxInferServerOpenAPI.ErrorResponse(error = "Not Found", message = "The requested model could not be found")
        )
    end

    roles = current_roles()

    if !any(r -> r in roles, model.roles)
        return HTTP.Response(
            404,
            RxInferServerOpenAPI.ErrorResponse(error = "Not Found", message = "The requested model could not be found")
        )
    end

    return HTTP.Response(
        200,
        RxInferServerOpenAPI.ModelDetails(
            details = RxInferServerOpenAPI.LightweightModelDetails(name = model.name, description = model.description),
            config = model.config
        )
    )
end

function create_model(req::HTTP.Request, create_model_request::RxInferServerOpenAPI.CreateModelRequest)::HTTP.Response
    error("Not implemented")
end
