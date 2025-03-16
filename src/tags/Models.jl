using UUIDs, Mongoc, TimeZones

function get_models(req::HTTP.Request)
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

    return RxInferServerOpenAPI.ModelList(model_list)
end

function get_model_details(req::HTTP.Request, model_name::String)
    model = Models.get_model(model_name)

    if isnothing(model)
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    roles = current_roles()

    if !any(r -> r in roles, model.roles)
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    return RxInferServerOpenAPI.ModelDetails(
        details = RxInferServerOpenAPI.LightweightModelDetails(name = model.name, description = model.description),
        config = model.config
    )
end

function create_model(req::HTTP.Request, create_model_request::RxInferServerOpenAPI.CreateModelRequest)
    model_details = get_model_details(req, create_model_request.model)

    # In this case, the response is probably an error response
    if !isa(model_details, RxInferServerOpenAPI.ModelDetails)
        return model_details
    end

    # Create model in the database
    model_name = model_details.details.name
    created_by = current_token()
    @debug "Creating new model in the database" model_name created_by
    model_id = string(UUIDs.uuid4())
    document = Mongoc.BSON(
        "model_id"    => model_id,
        "model_name"  => model_name,
        "created_at"  => Dates.now(),
        "created_by"  => created_by,
        "arguments"   => create_model_request.arguments,
        "description" => @something(create_model_request.description, ""),
        "deleted"     => false
    )
    collection = Database.collection("models")
    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        @error "Unable to create model due to internal error"
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create model due to internal error"
        )
    end

    @debug "Model created successfully" model_id
    return RxInferServerOpenAPI.CreateModelResponse(model_id = model_id)
end

function get_model_info(req::HTTP.Request, model_id::String)
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    # If no model is found, return `NotFoundResponse`
    if isnothing(result)
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Return the model info
    return RxInferServerOpenAPI.CreatedModelInfo(
        model_id = result["model_id"],
        model_name = result["model_name"],
        created_at = ZonedDateTime(result["created_at"], TimeZones.localzone()), # OpenAPI eh?
        description = result["description"],
        arguments = result["arguments"]
    )
end

function delete_model(req::HTTP.Request, model_id::String)
    token = current_token()

    # Update the model to be deleted
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("deleted" => true))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    if result["modifiedCount"] != 1
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to delete model due to internal error"
        )
    end

    return RxInferServerOpenAPI.SuccessResponse(message = "Model deleted successfully")
end
