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

    # Merge the default arguments with the arguments provided by the user
    # If user has not provided any arguments merge with the empty dictionary
    arguments = merge(
        Models.parse_default_arguments_from_config(model_details.config),
        @something(create_model_request.arguments, Dict{String, Any}())
    )

    # If user has not provided a description, use empty description
    description = @something(create_model_request.description, "")

    # Create the model's initial state
    dispatcher    = Models.get_models_dispatcher()
    initial_state = Models.dispatch(dispatcher, model_name, :initial_state, arguments)

    created_at = Dates.now()

    @debug "Creating new model in the database" model_name created_by
    model_id = string(UUIDs.uuid4())
    document = Mongoc.BSON(
        "model_id" => model_id,
        "model_name" => model_name,
        "created_at" => created_at,
        "created_by" => created_by,
        "arguments" => arguments,
        "description" => description,
        "state" => initial_state,
        "current_episode" => "default",
        "deleted" => false
    )
    collection = Database.collection("models")
    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        @error "Unable to create model due to internal error"
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create model due to internal error"
        )
    end

    @debug "Creating default episode for a model" model_id
    episode = Mongoc.BSON(
        "model_id" => model_id,
        "name" => "default",
        "created_at" => created_at,
        "events" => []
    )
    collection = Database.collection("episodes")
    insert_result = Mongoc.insert_one(collection, episode)

    if insert_result.reply["insertedCount"] != 1
        @error "Unable to create default episode due to internal error"

        # Delete the model if the default episode cannot be created
        delete_model(req, model_id)

        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create default episode due to internal error"
        )
    end

    @debug "Model created successfully" model_id
    return RxInferServerOpenAPI.CreateModelResponse(model_id = model_id)
end

function get_created_models_info(req::HTTP.Request)
    token = current_token()
    collection = Database.collection("models")
    query = Mongoc.BSON("created_by" => token, "deleted" => false)
    result = Mongoc.find(collection, query)

    return map(result) do model
        return RxInferServerOpenAPI.CreatedModelInfo(
            model_id = model["model_id"],
            model_name = model["model_name"],
            created_at = ZonedDateTime(model["created_at"], TimeZones.localzone()),
            description = model["description"],
            arguments = model["arguments"]
        )
    end
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
        arguments = result["arguments"],
        current_episode = result["current_episode"]
    )
end

function delete_model(req::HTTP.Request, model_id::String)
    token = current_token()

    # Update the model to be deleted
    @debug "Attempt to delete model" model_id token
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

    @debug "Model deleted successfully" model_id
    return RxInferServerOpenAPI.SuccessResponse(message = "Model deleted successfully")
end

function get_episode_info(req::HTTP.Request, model_id::String, episode_name::String)
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("model_id" => model_id, "name" => episode_name)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    return RxInferServerOpenAPI.EpisodeInfo(
        model_id = model_id,
        name = episode_name,
        created_at = ZonedDateTime(result["created_at"], TimeZones.localzone()),
        events = result["events"]
    )
end

function get_episodes(req::HTTP.Request, model_id::String)
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episodes
    collection = Database.collection("episodes")
    query = Mongoc.BSON("model_id" => model_id)
    result = Mongoc.find(collection, query)

    return map(result) do episode
        return RxInferServerOpenAPI.EpisodeInfo(
            model_id = model_id,
            name = episode["name"],
            created_at = ZonedDateTime(episode["created_at"], TimeZones.localzone()),
            events = episode["events"]
        )
    end
end
