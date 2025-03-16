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
    @debug "Attempting to create a new model" create_model_request.model
    model_details = get_model_details(req, create_model_request.model)

    # In this case, the response is probably an error response
    if !isa(model_details, RxInferServerOpenAPI.ModelDetails)
        @debug "Could not create model, `model_details` is not a `ModelDetails` object" create_model_request.model
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
    episode = create_episode(req, model_id, "default")

    if !isa(episode, RxInferServerOpenAPI.EpisodeInfo)
        @debug "Unable to create default episode, deleting model" model_id episode
        delete_model(req, model_id)
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create default episode due to internal error"
        )
    end

    @debug "Model created successfully" model_id
    return RxInferServerOpenAPI.CreateModelResponse(model_id = model_id)
end

function get_created_models_info(req::HTTP.Request)
    @debug "Attempting to get created models info"
    token = current_token()
    collection = Database.collection("models")
    query = Mongoc.BSON("created_by" => token, "deleted" => false)
    result = Mongoc.find(collection, query)

    @debug "Found models"
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
    @debug "Attempting to get model info" model_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    # If no model is found, return `NotFoundResponse`
    if isnothing(result)
        @debug "Cannot get model info because the model does not exist or token has no access to it" model_id
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
    @debug "Attempt to delete model" model_id
    token = current_token()

    # Update the model to be deleted
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("deleted" => true))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Cannot delete model because it does not exist" model_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    if result["modifiedCount"] != 1
        @debug "Unable to delete model due to internal error" model_id
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to delete model due to internal error"
        )
    end

    @debug "Model deleted successfully" model_id
    return RxInferServerOpenAPI.SuccessResponse(message = "Model deleted successfully")
end

function get_model_state(req::HTTP.Request, model_id::String)
    @debug "Attempting to get model state" model_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get model state because the model does not exist or token has no access to it" model_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    @debug "Successfully got model state" model_id
    return RxInferServerOpenAPI.ModelState(state = result["state"])
end

function run_inference(req::HTTP.Request, model_id::String, infer_request::RxInferServerOpenAPI.InferRequest)
    @debug "Attempting to run inference" model_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Cannot run inference because the model does not exist or token has no access to it" model_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Asynchronously attach data to the specified episode
    @debug "Attaching data to the episode" model_id infer_request.episode_name
    fill_episode_task = Threads.@spawn begin
        # Query the database for the episode
        collection = Database.collection("episodes")
        query = Mongoc.BSON("model_id" => model_id, "name" => infer_request.episode_name, "deleted" => false)

        # Get the current number of events from the n_events field
        options = Mongoc.BSON("projection" => Mongoc.BSON("events_id_counter" => 1))
        current = Mongoc.find_one(collection, query; options = options)
        next_id = isnothing(current) ? 1 : current["events_id_counter"] + 1

        update = Mongoc.BSON(
            "\$push" => Mongoc.BSON(
                "events" => Dict(
                    "event_id" => next_id,
                    "data" => infer_request.data,
                    "timestamp" => DateTime(something(infer_request.timestamp, Dates.now())) # OpenAPI eh?
                )
            ),
            "\$set" => Mongoc.BSON("events_id_counter" => next_id)
        )

        options = Mongoc.BSON(
            "returnDocument" => "after", "projection" => Mongoc.BSON("event_id" => Mongoc.BSON("\$size" => "\$events"))
        )
        result = Mongoc.find_one_and_update(collection, query, update; options = options)

        if isnothing(result)
            @debug "Unable to attach data to the episode due to internal error" model_id infer_request.episode_name
            return RxInferServerOpenAPI.ErrorResponse(
                error = "Bad Request", message = "Unable to attach data to the episode due to internal error"
            )
        end

        @debug "Successfully attached data to the episode" model_id infer_request.episode_name next_id
        return next_id
    end

    # Asynchronously run the inference
    @debug "Running inference" model_id
    inference_task = Threads.@spawn begin
        # Get the model's dispatcher
        dispatcher = Models.get_models_dispatcher()

        # Run the inference
        try
            model_name = model["model_name"]
            model_state = model["state"]

            inference_result, new_state = Models.dispatch(
                dispatcher, model_name, :inference, model_state, infer_request.data
            )

            # Update the model's state
            collection = Database.collection("models")
            query = Mongoc.BSON("model_id" => model_id)
            update = Mongoc.BSON("\$set" => Mongoc.BSON("state" => new_state))
            result = Mongoc.update_one(collection, query, update)

            if result["matchedCount"] != 1
                @debug "Unable to update model's state due to internal error" model_id
                return RxInferServerOpenAPI.ErrorResponse(
                    error = "Bad Request", message = "Unable to update model's state due to internal error"
                )
            end

            @debug "Successfully updated model's state" model_id
            return inference_result
        catch e
            @error "Unable to run inference due to internal error. Check debug logs for more information." model_id
            @debug "Unable to run inference due to internal error." exception = (e, catch_backtrace())
            return RxInferServerOpenAPI.ErrorResponse(
                error = "Bad Request", message = "Unable to run inference due to internal error"
            )
        end
    end

    # Wait for the episode to be filled and the inference to be run
    inference_task_result = fetch(inference_task)

    if isa(inference_task_result, RxInferServerOpenAPI.ErrorResponse)
        return inference_task_result
    end

    # Inference completed successfully, but there might be non-fatal errors
    # for example, the episode might not be filled successfully, which is sad, but not a big deal
    errors = []
    event_id = nothing

    fill_episode_task_result = fetch(fill_episode_task)

    if isa(fill_episode_task_result, RxInferServerOpenAPI.ErrorResponse)
        push!(errors, fill_episode_task_result)
    else
        event_id = fill_episode_task_result
    end

    return RxInferServerOpenAPI.InferResponse(event_id = event_id, results = inference_task_result, errors = errors)
end

function attach_metadata_to_event(
    req::HTTP.Request,
    model_id,
    episode_name,
    event_id,
    attach_metadata_to_event_request::RxInferServerOpenAPI.AttachMetadataToEventRequest
)
    @debug "Attempting to attach metadata to an event" model_id episode_name event_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Cannot attach metadata to an event because the model does not exist or token has no access to it" model_id episode_name event_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON(
        "model_id" => model_id,
        "name" => episode_name,
        "deleted" => false,
        "events" => Mongoc.BSON("\$elemMatch" => Mongoc.BSON("event_id" => event_id))
    )
    episode = Mongoc.find_one(collection, query)

    if isnothing(episode)
        @debug "Cannot attach metadata to an event because the episode does not exist or event not found" model_id episode_name event_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found",
            message = "The requested episode could not be found or the event with the specified ID does not exist"
        )
    end

    # Update the specific event with the metadata
    update = Mongoc.BSON("\$set" => Mongoc.BSON("events.\$.metadata" => attach_metadata_to_event_request.metadata))

    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Unable to attach metadata to the event due to internal error" model_id episode_name event_id
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to attach metadata to the event due to internal error"
        )
    end

    @debug "Successfully attached metadata to the event" model_id episode_name event_id
    return RxInferServerOpenAPI.SuccessResponse(message = "Metadata attached to the event successfully")
end

function get_episode_info(req::HTTP.Request, model_id::String, episode_name::String)
    @debug "Attempting to get episode info" model_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get episode info because the model does not exist or token has no access to it" model_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("model_id" => model_id, "name" => episode_name, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get episode info because the episode does not exist" model_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    @debug "Successfully got episode info" model_id episode_name
    return RxInferServerOpenAPI.EpisodeInfo(
        model_id = model_id,
        name = episode_name,
        created_at = ZonedDateTime(result["created_at"], TimeZones.localzone()),
        events = result["events"]
    )
end

function get_episodes(req::HTTP.Request, model_id::String)
    @debug "Attempting to get episodes" model_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get episodes because the model does not exist or token has no access to it" model_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episodes
    collection = Database.collection("episodes")
    query = Mongoc.BSON("model_id" => model_id, "deleted" => false)
    result = Mongoc.find(collection, query)

    @debug "Found episodes" model_id
    return map(result) do episode
        return RxInferServerOpenAPI.EpisodeInfo(
            model_id = model_id,
            name = episode["name"],
            created_at = ZonedDateTime(episode["created_at"], TimeZones.localzone()),
            events = episode["events"]
        )
    end
end

function create_episode(req::HTTP.Request, model_id::String, episode_name::String)
    @debug "Attempting to create episode" model_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Episode cannot be created because the model does not exist or token has no access to it" model_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Check that the episode does not already exist
    collection = Database.collection("episodes")
    query = Mongoc.BSON("model_id" => model_id, "name" => episode_name)
    result = Mongoc.find_one(collection, query)

    if !isnothing(result)
        @debug "Episode cannot be created because it already exists" model_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "The requested episode already exists"
        )
    end

    # Create the episode
    created_at = Dates.now()
    document = Mongoc.BSON(
        "model_id" => model_id,
        "name" => episode_name,
        "created_at" => created_at,
        "events" => [],
        "events_id_counter" => 0,
        "deleted" => false
    )
    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        @debug "Unable to create episode due to internal error" model_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create episode due to internal error"
        )
    end

    # Update the model to point to the new episode
    @debug "Updating model to point to the new episode" model_id episode_name
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("current_episode" => episode_name))
    update_result = Mongoc.update_one(collection, query, update)

    if update_result["matchedCount"] != 1
        @debug "Unable to update model to point to the new episode" model_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request",
            message = "The episode has been created, but the model could not be updated to point to the new episode due to internal error"
        )
    end

    @debug "Episode created successfully" model_id episode_name
    return RxInferServerOpenAPI.EpisodeInfo(
        model_id = model_id,
        name = episode_name,
        created_at = ZonedDateTime(created_at, TimeZones.localzone()),
        events = []
    )
end

function delete_episode(req::HTTP.Request, model_id::String, episode_name::String)
    @debug "Attempting to delete episode" model_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Episode cannot be deleted because the model does not exist or token has no access to it" model_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    if episode_name == "default"
        @debug "Episode cannot be deleted because it is the default episode" model_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Default episode cannot be deleted, wipe data instead"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("model_id" => model_id, "name" => episode_name, "deleted" => false)
    episode = Mongoc.find_one(collection, query)

    if isnothing(episode)
        @debug "Episode cannot be deleted because it does not exist" model_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    # Delete the episode
    update = Mongoc.BSON("\$set" => Mongoc.BSON("deleted" => true))
    delete_result = Mongoc.update_one(collection, query, update)

    if delete_result["matchedCount"] != 1
        @debug "Unable to delete episode due to internal error" model_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to delete episode due to internal error"
        )
    end

    # Update the model if the deleted episode was the current episode
    if model["current_episode"] == episode_name
        @debug "Updating model to point to the default episode" model_id
        collection = Database.collection("models")
        query = Mongoc.BSON("model_id" => model_id)
        update = Mongoc.BSON("\$set" => Mongoc.BSON("current_episode" => "default"))
        update_result = Mongoc.update_one(collection, query, update)

        if update_result["matchedCount"] != 1
            return RxInferServerOpenAPI.ErrorResponse(
                error = "Bad Request",
                message = "The episode has been deleted, but the model could not be updated to point to the default episode due to internal error"
            )
        end
    end

    @debug "Episode deleted successfully" model_id episode_name
    return RxInferServerOpenAPI.SuccessResponse(message = "Episode deleted successfully")
end

function wipe_episode(req::HTTP.Request, model_id::String, episode_name::String)
    @debug "Wiping episode" model_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("model_id" => model_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Episode cannot be wiped because the model does not exist or token has no access to it" model_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("model_id" => model_id, "name" => episode_name, "deleted" => false)
    episode = Mongoc.find_one(collection, query)

    if isnothing(episode)
        @debug "Episode cannot be wiped because it does not exist" model_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    # Wipe the episode
    update = Mongoc.BSON("\$set" => Mongoc.BSON("events" => []))
    wipe_result = Mongoc.update_one(collection, query, update)

    if wipe_result["matchedCount"] != 1
        @debug "Unable to wipe episode due to internal error" model_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to wipe episode due to internal error"
        )
    end

    @debug "Episode wiped successfully" model_id episode_name
    return RxInferServerOpenAPI.SuccessResponse(message = "Episode wiped successfully")
end
