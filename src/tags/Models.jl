using UUIDs, Mongoc, TimeZones

function get_available_models(req::HTTP.Request)
    models = Models.get_models()
    roles = current_roles()

    filtered_models = filter(models) do model
        return any(r -> r in roles, model.roles)
    end

    return map(filtered_models) do model
        return RxInferServerOpenAPI.AvailableModel(
            details = (name = model.name, description = model.description, author = model.author, roles = model.roles),
            config = model.config
        )
    end
end

function get_available_model(req::HTTP.Request, model_name::String)
    model = Models.get_model(model_name)
    roles = current_roles()

    if isnothing(model) || !any(r -> r in roles, model.roles)
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model name `$model_name` could not be found"
        )
    end

    return RxInferServerOpenAPI.AvailableModel(
        details = (name = model.name, description = model.description, author = model.author, roles = model.roles),
        config = model.config
    )
end

function get_model_instances(req::HTTP.Request)
    token = current_token()

    @debug "Attempting to get model instances" token
    collection = Database.collection("models")
    query = Mongoc.BSON("created_by" => token, "deleted" => false)
    result = Mongoc.find(collection, query)

    @debug "Found model instances" token
    return map(result) do model
        return RxInferServerOpenAPI.ModelInstance(
            instance_id = model["instance_id"],
            model_name = model["model_name"],
            created_at = ZonedDateTime(model["created_at"], TimeZones.localzone()),
            description = model["description"],
            arguments = model["arguments"],
            current_episode = model["current_episode"]
        )
    end
end

function get_model_instance(req::HTTP.Request, instance_id::String)
    token = current_token()

    @debug "Attempting to get model instance" token instance_id
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get model instance because the instance does not exist or token has no access to it" token instance_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model instance could not be found"
        )
    end

    @debug "Successfully retrieved model instance" token instance_id
    return RxInferServerOpenAPI.ModelInstance(
        instance_id = result["instance_id"],
        model_name = result["model_name"],
        created_at = ZonedDateTime(result["created_at"], TimeZones.localzone()),
        description = result["description"],
        arguments = result["arguments"],
        current_episode = result["current_episode"]
    )
end

function create_model_instance(req::HTTP.Request, create_model_request::RxInferServerOpenAPI.CreateModelInstanceRequest)
    @debug "Attempting to create a new model" create_model_request.model_name

    token = current_token()
    model_name = create_model_request.model_name
    response = get_available_model(req, model_name)

    # In this case, the response is probably an error response
    if !isa(response, RxInferServerOpenAPI.AvailableModel)
        @debug "Could not create a new model instance, `response` is not a `AvailableModel` object" token model_name
        return response
    end

    model = response::RxInferServerOpenAPI.AvailableModel

    # Check if the retrieved model name is correct
    if !isequal(create_model_request.model_name, model.details.name)
        @debug "Could not create a new model instance, `model_name` from the request is not equal to the retrieved `model.details.name`" create_model_request.model_name model.details.name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "The requested model name `$model_name` could not be found"
        )
    end

    # Merge the default arguments with the arguments provided by the user
    # If user has not provided any arguments merge with the empty dictionary
    arguments = merge(
        Models.parse_default_arguments_from_config(model.config),
        @something(create_model_request.arguments, Dict{String, Any}())
    )

    # If user has not provided a description, use empty description
    description = @something(create_model_request.description, "")

    # Create the model's initial state
    dispatcher    = Models.get_models_dispatcher()
    initial_state = Models.dispatch(dispatcher, model_name, :initial_state, arguments)

    created_at = Dates.now()

    @debug "Creating new model instance in the database" model_name token
    instance_id = string(UUIDs.uuid4())
    document = Mongoc.BSON(
        "instance_id" => instance_id,
        "model_name" => model_name,
        "created_at" => created_at,
        "created_by" => token,
        "arguments" => arguments,
        "description" => description,
        "state" => initial_state,
        "current_episode" => "default",
        "deleted" => false
    )
    collection = Database.collection("models")
    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        @error "Unable to create model instance due to internal error" token
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create model instance due to internal error"
        )
    end

    @debug "Creating default episode for the model instance" instance_id
    episode = create_episode(req, instance_id, "default")

    if !isa(episode, RxInferServerOpenAPI.EpisodeInfo)
        @debug "Unable to create default episode, deleting the model instance" token instance_id episode
        delete_model(req, instance_id)
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create default episode due to internal error"
        )
    end

    @debug "Model instance created successfully" token instance_id
    return RxInferServerOpenAPI.CreateModelInstanceResponse(instance_id = instance_id)
end

function delete_model_instance(req::HTTP.Request, instance_id::String)
    token = current_token()

    @debug "Attempting to delete the model instance" token instance_id
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("deleted" => true))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Cannot delete model instance because it does not exist" token instance_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model instance could not be found"
        )
    end

    if result["modifiedCount"] != 1
        @debug "Unable to delete model instance due to internal error" token instance_id
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to delete model instance due to internal error"
        )
    end

    @debug "Model instance deleted successfully" token instance_id
    return RxInferServerOpenAPI.SuccessResponse(message = "Model instance deleted successfully")
end

function get_model_instance_state(req::HTTP.Request, instance_id::String)
    token = current_token()

    @debug "Attempting to get model instance state" token instance_id
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get model instance state because the instance does not exist or token has no access to it" token instance_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model instance could not be found"
        )
    end

    @debug "Successfully retrieved model instance state" token instance_id
    return RxInferServerOpenAPI.ModelInstanceState(state = result["state"])
end

function run_inference(req::HTTP.Request, instance_id::String, infer_request::RxInferServerOpenAPI.InferRequest)
    @debug "Attempting to run inference" instance_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Cannot run inference because the model does not exist or token has no access to it" instance_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Asynchronously attach data to the specified episode
    @debug "Attaching data to the episode" instance_id infer_request.episode_name
    fill_episode_task = Threads.@spawn begin
        # Query the database for the episode
        collection = Database.collection("episodes")
        query = Mongoc.BSON("instance_id" => instance_id, "name" => infer_request.episode_name, "deleted" => false)

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
            @debug "Unable to attach data to the episode due to internal error" instance_id infer_request.episode_name
            return RxInferServerOpenAPI.ErrorResponse(
                error = "Bad Request", message = "Unable to attach data to the episode due to internal error"
            )
        end

        @debug "Successfully attached data to the episode" instance_id infer_request.episode_name next_id
        return next_id
    end

    # Asynchronously run the inference
    @debug "Running inference" instance_id
    inference_task = Threads.@spawn begin
        # Get the model's dispatcher
        dispatcher = Models.get_models_dispatcher()

        # Run the inference
        try
            model_name = model["model_name"]
            model_state = model["state"]

            inference_result, new_state = Models.dispatch(
                dispatcher, model_name, :run_inference, model_state, infer_request.data
            )

            # Update the model's state
            collection = Database.collection("models")
            query = Mongoc.BSON("instance_id" => instance_id)
            update = Mongoc.BSON("\$set" => Mongoc.BSON("state" => new_state))
            result = Mongoc.update_one(collection, query, update)

            if result["matchedCount"] != 1
                @debug "Unable to update model's state due to internal error" instance_id
                return RxInferServerOpenAPI.ErrorResponse(
                    error = "Bad Request", message = "Unable to update model's state due to internal error"
                )
            end

            @debug "Successfully updated model's state" instance_id
            return inference_result
        catch e
            @error "Unable to run inference due to internal error. Check debug logs for more information." instance_id
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

function run_learning(req::HTTP.Request, instance_id::String, learn_request::RxInferServerOpenAPI.LearnRequest)
    @debug "Attempting to run learning" instance_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Cannot run learning because the model does not exist or token has no access to it" instance_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    episodes = @something(learn_request.episodes, ["default"])

    # TODO: Only one episode is supported for now
    if length(episodes) != 1
        @debug "Cannot run learning because only one episode is supported for now" instance_id
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Learning is supported only for one episode at a time"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "name" => episodes[1], "deleted" => false)
    episode = Mongoc.find_one(collection, query)

    if isnothing(episode)
        @debug "Cannot run learning because the episode does not exist" instance_id episodes[1]
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    dispatcher = Models.get_models_dispatcher()

    model_name = model["model_name"]
    model_state = model["state"]
    episode_events = episode["events"]

    learning_result, new_state = Models.dispatch(
        dispatcher, model_name, :run_learning, model_state, learn_request.parameters, episode_events
    )
    @debug "Successfully ran learning" instance_id

    # Update the model's state
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("state" => new_state))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Unable to update model's state due to internal error" instance_id
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to update model's state due to internal error"
        )
    end

    @debug "Successfully updated model's state" instance_id
    return RxInferServerOpenAPI.LearnResponse(learned_parameters = learning_result)
end

function attach_metadata_to_event(
    req::HTTP.Request,
    instance_id,
    episode_name,
    event_id,
    attach_metadata_to_event_request::RxInferServerOpenAPI.AttachMetadataToEventRequest
)
    @debug "Attempting to attach metadata to an event" instance_id episode_name event_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Cannot attach metadata to an event because the model does not exist or token has no access to it" instance_id episode_name event_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON(
        "instance_id" => instance_id,
        "name" => episode_name,
        "deleted" => false,
        "events" => Mongoc.BSON("\$elemMatch" => Mongoc.BSON("event_id" => event_id))
    )
    episode = Mongoc.find_one(collection, query)

    if isnothing(episode)
        @debug "Cannot attach metadata to an event because the episode does not exist or event not found" instance_id episode_name event_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found",
            message = "The requested episode could not be found or the event with the specified ID does not exist"
        )
    end

    # Update the specific event with the metadata
    update = Mongoc.BSON("\$set" => Mongoc.BSON("events.\$.metadata" => attach_metadata_to_event_request.metadata))

    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Unable to attach metadata to the event due to internal error" instance_id episode_name event_id
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to attach metadata to the event due to internal error"
        )
    end

    @debug "Successfully attached metadata to the event" instance_id episode_name event_id
    return RxInferServerOpenAPI.SuccessResponse(message = "Metadata attached to the event successfully")
end

function get_episode_info(req::HTTP.Request, instance_id::String, episode_name::String)
    @debug "Attempting to get episode info" instance_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get episode info because the model does not exist or token has no access to it" instance_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "name" => episode_name, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get episode info because the episode does not exist" instance_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    @debug "Successfully got episode info" instance_id episode_name
    return RxInferServerOpenAPI.EpisodeInfo(
        instance_id = instance_id,
        name = episode_name,
        created_at = ZonedDateTime(result["created_at"], TimeZones.localzone()),
        events = result["events"]
    )
end

function get_episodes(req::HTTP.Request, instance_id::String)
    @debug "Attempting to get episodes" instance_id
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get episodes because the model does not exist or token has no access to it" instance_id
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episodes
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "deleted" => false)
    result = Mongoc.find(collection, query)

    @debug "Found episodes" instance_id
    return map(result) do episode
        return RxInferServerOpenAPI.EpisodeInfo(
            instance_id = instance_id,
            name = episode["name"],
            created_at = ZonedDateTime(episode["created_at"], TimeZones.localzone()),
            events = episode["events"]
        )
    end
end

function create_episode(req::HTTP.Request, instance_id::String, episode_name::String)
    @debug "Attempting to create episode" instance_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Episode cannot be created because the model does not exist or token has no access to it" instance_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Check that the episode does not already exist
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "name" => episode_name)
    result = Mongoc.find_one(collection, query)

    if !isnothing(result)
        @debug "Episode cannot be created because it already exists" instance_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "The requested episode already exists"
        )
    end

    # Create the episode
    created_at = Dates.now()
    document = Mongoc.BSON(
        "instance_id" => instance_id,
        "name" => episode_name,
        "created_at" => created_at,
        "events" => [],
        "events_id_counter" => 0,
        "deleted" => false
    )
    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        @debug "Unable to create episode due to internal error" instance_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create episode due to internal error"
        )
    end

    # Update the model to point to the new episode
    @debug "Updating model to point to the new episode" instance_id episode_name
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("current_episode" => episode_name))
    update_result = Mongoc.update_one(collection, query, update)

    if update_result["matchedCount"] != 1
        @debug "Unable to update model to point to the new episode" instance_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request",
            message = "The episode has been created, but the model could not be updated to point to the new episode due to internal error"
        )
    end

    @debug "Episode created successfully" instance_id episode_name
    return RxInferServerOpenAPI.EpisodeInfo(
        instance_id = instance_id,
        name = episode_name,
        created_at = ZonedDateTime(created_at, TimeZones.localzone()),
        events = []
    )
end

function delete_episode(req::HTTP.Request, instance_id::String, episode_name::String)
    @debug "Attempting to delete episode" instance_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Episode cannot be deleted because the model does not exist or token has no access to it" instance_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    if episode_name == "default"
        @debug "Episode cannot be deleted because it is the default episode" instance_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Default episode cannot be deleted, wipe data instead"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "name" => episode_name, "deleted" => false)
    episode = Mongoc.find_one(collection, query)

    if isnothing(episode)
        @debug "Episode cannot be deleted because it does not exist" instance_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    # Delete the episode
    update = Mongoc.BSON("\$set" => Mongoc.BSON("deleted" => true))
    delete_result = Mongoc.update_one(collection, query, update)

    if delete_result["matchedCount"] != 1
        @debug "Unable to delete episode due to internal error" instance_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to delete episode due to internal error"
        )
    end

    # Update the model if the deleted episode was the current episode
    if model["current_episode"] == episode_name
        @debug "Updating model to point to the default episode" instance_id
        collection = Database.collection("models")
        query = Mongoc.BSON("instance_id" => instance_id)
        update = Mongoc.BSON("\$set" => Mongoc.BSON("current_episode" => "default"))
        update_result = Mongoc.update_one(collection, query, update)

        if update_result["matchedCount"] != 1
            return RxInferServerOpenAPI.ErrorResponse(
                error = "Bad Request",
                message = "The episode has been deleted, but the model could not be updated to point to the default episode due to internal error"
            )
        end
    end

    @debug "Episode deleted successfully" instance_id episode_name
    return RxInferServerOpenAPI.SuccessResponse(message = "Episode deleted successfully")
end

function wipe_episode(req::HTTP.Request, instance_id::String, episode_name::String)
    @debug "Wiping episode" instance_id episode_name
    token = current_token()

    # Query the database for the model
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    model = Mongoc.find_one(collection, query)

    if isnothing(model)
        @debug "Episode cannot be wiped because the model does not exist or token has no access to it" instance_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested model could not be found"
        )
    end

    # Query the database for the episode
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "name" => episode_name, "deleted" => false)
    episode = Mongoc.find_one(collection, query)

    if isnothing(episode)
        @debug "Episode cannot be wiped because it does not exist" instance_id episode_name
        return RxInferServerOpenAPI.NotFoundResponse(
            error = "Not Found", message = "The requested episode could not be found"
        )
    end

    # Wipe the episode
    update = Mongoc.BSON("\$set" => Mongoc.BSON("events" => []))
    wipe_result = Mongoc.update_one(collection, query, update)

    if wipe_result["matchedCount"] != 1
        @debug "Unable to wipe episode due to internal error" instance_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to wipe episode due to internal error"
        )
    end

    @debug "Episode wiped successfully" instance_id episode_name
    return RxInferServerOpenAPI.SuccessResponse(message = "Episode wiped successfully")
end
