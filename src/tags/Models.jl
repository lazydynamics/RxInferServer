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
    token     = current_token()
    instances = __database_op_get_all_model_instances(; token)

    return map(instances) do instance
        return RxInferServerOpenAPI.ModelInstance(
            instance_id = instance["instance_id"],
            model_name = instance["model_name"],
            created_at = ZonedDateTime(instance["created_at"], TimeZones.localzone()),
            description = instance["description"],
            arguments = instance["arguments"],
            current_episode = instance["current_episode"]
        )
    end
end

function get_model_instance(req::HTTP.Request, instance_id::String)
    token = current_token()

    instance = @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found"
    )

    return RxInferServerOpenAPI.ModelInstance(
        instance_id = instance["instance_id"],
        model_name = instance["model_name"],
        created_at = ZonedDateTime(instance["created_at"], TimeZones.localzone()),
        description = instance["description"],
        arguments = instance["arguments"],
        current_episode = instance["current_episode"]
    )
end

function create_model_instance(req::HTTP.Request, create_model_request::RxInferServerOpenAPI.CreateModelInstanceRequest)
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

    instance_id = @expect __database_op_create_model_instance(;
        token, model_name, description, arguments, initial_state
    ) || RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to create model instance due to internal error"
    )

    episode = create_episode(req, instance_id, RxInferServerOpenAPI.CreateEpisodeRequest(name = "default"))

    if !isa(episode, RxInferServerOpenAPI.EpisodeInfo)
        @debug "Unable to create default episode, deleting the model instance" token instance_id episode
        delete_model_instance(req, instance_id)
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to create default episode due to internal error"
        )
    end

    return RxInferServerOpenAPI.CreateModelInstanceResponse(instance_id = instance_id)
end

function delete_model_instance(req::HTTP.Request, instance_id::String)
    token = current_token()
    @expect __database_op_delete_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found or deleted"
    )
    return RxInferServerOpenAPI.SuccessResponse(message = "Model instance deleted successfully")
end

function get_model_instance_state(req::HTTP.Request, instance_id::String)
    token = current_token()
    instance = @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found"
    )
    return RxInferServerOpenAPI.ModelInstanceState(state = instance["state"])
end

function run_inference(req::HTTP.Request, instance_id::String, infer_request::RxInferServerOpenAPI.InferRequest)
    @debug "Attempting to run inference" instance_id

    token = current_token()
    instance = @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found"
    )

    # Asynchronously attach data to the specified episode
    fill_episode_task = Threads.@spawn begin
        next_id = @expect __database_op_attach_event_to_episode(
            instance_id = instance_id,
            episode_name = infer_request.episode_name,
            data = infer_request.data,
            timestamp = DateTime(something(infer_request.timestamp, Dates.now()))
        ) || RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to attach data to the episode due to internal error"
        )
        return next_id
    end

    # Asynchronously run the inference
    inference_task = Threads.@spawn begin
        # Get the model's dispatcher
        dispatcher = Models.get_models_dispatcher()

        # Run the inference
        try
            model_name = instance["model_name"]
            model_state = instance["state"]

            @debug "Calling the model's `run_inference` method" instance_id
            inference_result, new_state = Models.dispatch(
                dispatcher, model_name, :run_inference, model_state, infer_request.data
            )

            # Update the model's state
            @expect __database_op_update_model_state(; instance_id, new_state) || RxInferServerOpenAPI.ErrorResponse(
                error = "Bad Request", message = "Unable to update model's state due to internal error"
            )

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

    @debug "Inference completed successfully" instance_id
    return RxInferServerOpenAPI.InferResponse(event_id = event_id, results = inference_task_result, errors = errors)
end

function run_learning(req::HTTP.Request, instance_id::String, learn_request::RxInferServerOpenAPI.LearnRequest)
    @debug "Attempting to run learning" instance_id

    token = current_token()
    instance = @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found"
    )

    episodes = @something(learn_request.episodes, ["default"])

    # TODO: Only one episode is supported for now
    if length(episodes) != 1
        @debug "Cannot run learning because only one episode is supported for now" instance_id
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Learning is supported only for one episode at a time"
        )
    end

    episode = @expect __database_op_get_episode(; instance_id, episode_name = episodes[1]) ||
        RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested episode could not be found"
    )

    dispatcher = Models.get_models_dispatcher()

    model_name = instance["model_name"]
    model_state = instance["state"]
    episode_events = episode["events"]

    @debug "Calling the model's `run_learning` method" instance_id
    learning_result, new_state = Models.dispatch(
        dispatcher, model_name, :run_learning, model_state, learn_request.parameters, episode_events
    )

    # Update the model's state
    @expect __database_op_update_model_state(; instance_id, new_state) || RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to update model's state due to internal error"
    )

    @debug "Learning completed successfully" instance_id
    return RxInferServerOpenAPI.LearnResponse(learned_parameters = learning_result)
end

function get_episode_info(req::HTTP.Request, instance_id::String, episode_name::String)
    token = current_token()

    @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found"
    )

    episode = @expect __database_op_get_episode(; instance_id, episode_name) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested episode could not be found"
    )

    return RxInferServerOpenAPI.EpisodeInfo(
        instance_id = instance_id,
        episode_name = episode_name,
        created_at = ZonedDateTime(episode["created_at"], TimeZones.localzone()),
        events = episode["events"]
    )
end

function get_episodes(req::HTTP.Request, instance_id::String)
    token = current_token()

    @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found"
    )

    episodes = __database_op_get_all_episodes(; instance_id)

    return map(episodes) do episode
        return RxInferServerOpenAPI.EpisodeInfo(
            instance_id = instance_id,
            episode_name = episode["episode_name"],
            created_at = ZonedDateTime(episode["created_at"], TimeZones.localzone()),
            events = episode["events"]
        )
    end
end

function create_episode(
    req::HTTP.Request, instance_id::String, create_episode_request::RxInferServerOpenAPI.CreateEpisodeRequest
)
    token = current_token()

    @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model instance could not be found"
    )

    # Check that the episode does not already exist
    episode_name = create_episode_request.name
    existing_episode = __database_op_get_episode(; instance_id, episode_name)

    if !isnothing(existing_episode)
        @debug "Episode already exists" instance_id episode_name
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "The requested episode already exists"
        )
    end

    @expect __database_op_create_episode(; instance_id, episode_name) || RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to create episode due to internal error"
    )

    # Update the model to point to the new episode
    @expect __database_op_update_model_current_episode(; instance_id, episode_name) ||
        RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request",
        message = "The episode has been created, but the model could not be updated to point to the new episode due to internal error"
    )

    return get_episode_info(req, instance_id, episode_name)
end

function delete_episode(req::HTTP.Request, instance_id::String, episode_name::String)

    # Short-circuit if the episode is the default episode
    if episode_name == "default"
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Default episode cannot be deleted, wipe data instead"
        )
    end

    token = current_token()

    instance = @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model could not be found"
    )

    @expect __database_op_get_episode(; instance_id, episode_name) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested episode could not be found"
    )

    # Delete the episode
    @expect __database_op_delete_episode(; instance_id, episode_name) || RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to delete episode due to internal error"
    )

    # Update the model if the deleted episode was the current episode
    if instance["current_episode"] == episode_name
        @expect __database_op_update_model_current_episode(; instance_id, episode_name = "default") ||
            RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request",
            message = "The episode has been deleted, but the model could not be updated to point to the default episode due to internal error"
        )
    end

    return RxInferServerOpenAPI.SuccessResponse(message = "Episode deleted successfully")
end

function wipe_episode(req::HTTP.Request, instance_id::String, episode_name::String)
    token = current_token()

    @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model could not be found"
    )

    @expect __database_op_get_episode(; instance_id, episode_name) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested episode could not be found"
    )

    @expect __database_op_wipe_episode(; instance_id, episode_name) || RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to wipe episode due to internal error"
    )

    return RxInferServerOpenAPI.SuccessResponse(message = "Episode wiped successfully")
end

function attach_metadata_to_event(
    req::HTTP.Request,
    instance_id,
    episode_name,
    event_id,
    attach_metadata_to_event_request::RxInferServerOpenAPI.AttachMetadataToEventRequest
)
    token = current_token()

    @expect __database_op_get_model_instance(; token, instance_id) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found", message = "The requested model could not be found"
    )

    @expect __database_op_get_episode(; instance_id, episode_name) || RxInferServerOpenAPI.NotFoundResponse(
        error = "Not Found",
        message = "The requested episode could not be found or the event with the specified ID does not exist"
    )

    @expect __database_op_attach_metadata_to_event(;
        instance_id, episode_name, event_id, metadata = attach_metadata_to_event_request.metadata
    ) || RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to attach metadata to the event due to internal error"
    )

    return RxInferServerOpenAPI.SuccessResponse(message = "Metadata attached to the event successfully")
end

# Database operations

## Get model instances for a given token
function __database_op_get_all_model_instances(; token)
    @debug "Attempting to get all model instances for token" token

    collection = Database.collection("models")
    query = Mongoc.BSON("created_by" => token, "deleted" => false)
    result = Mongoc.find(collection, query)

    if isnothing(result)
        @debug "Cannot get model instances because the token has no access to any model instances" token
    else
        @debug "Successfully retrieved model instances" token
    end

    return result
end

## Get a model instance for a given token and instance ID
function __database_op_get_model_instance(; token, instance_id)
    @debug "Attempting to get model instance" token instance_id

    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get model instance because the instance does not exist or token has no access to it" token instance_id
    else
        @debug "Successfully retrieved model instance" token instance_id
    end

    return result
end

function __database_op_create_model_instance(; token, model_name, description, arguments, initial_state)
    @debug "Creating new model instance in the database" model_name token

    instance_id = string(UUIDs.uuid4())
    document = Mongoc.BSON(
        "instance_id" => instance_id,
        "model_name" => model_name,
        "description" => description,
        "created_at" => Dates.now(),
        "created_by" => token,
        "arguments" => arguments,
        "state" => initial_state,
        "current_episode" => "default",
        "deleted" => false
    )
    collection = Database.collection("models")
    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        @error "Unable to create model instance in the database due to an internal error" token model_name
        return nothing
    end

    @debug "Successfully created model instance" token model_name instance_id
    return instance_id
end

function __database_op_delete_model_instance(; token, instance_id)
    @debug "Attempting to delete the model instance" token instance_id

    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id, "created_by" => token, "deleted" => false)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("deleted" => true))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Cannot delete model instance because it does not exist" token instance_id
        return nothing
    end

    if result["modifiedCount"] != 1
        @debug "Unable to delete model instance due to internal error" token instance_id
        return nothing
    end

    @debug "Successfully deleted model instance" token instance_id
    return result
end

## Get all episodes for a given model instance
function __database_op_get_all_episodes(; instance_id::String)
    @debug "Attempting to get all episodes for model instance" instance_id

    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "deleted" => false)
    result = Mongoc.find(collection, query)

    if isnothing(result)
        @debug "Cannot get episodes because the model instance does not exist" instance_id
    else
        @debug "Successfully retrieved episodes" instance_id
    end

    return result
end

## Get episode by instance ID and episode name
function __database_op_get_episode(; instance_id::String, episode_name::String)
    @debug "Attempting to get episode" instance_id episode_name

    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "episode_name" => episode_name, "deleted" => false)
    result = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Cannot get episode because it does not exist" instance_id episode_name
    else
        @debug "Successfully retrieved episode" instance_id episode_name
    end

    return result
end

## Create a new episode
function __database_op_create_episode(; instance_id::String, episode_name::String)
    @debug "Creating new episode in the database" instance_id episode_name

    document = Mongoc.BSON(
        "instance_id" => instance_id,
        "episode_name" => episode_name,
        "created_at" => Dates.now(),
        "events" => [],
        "events_id_counter" => 0,
        "deleted" => false
    )
    collection = Database.collection("episodes")
    result = Mongoc.insert_one(collection, document)

    if result.reply["insertedCount"] != 1
        @debug "Unable to create episode due to internal error" instance_id episode_name
        return nothing
    end

    @debug "Successfully created episode" instance_id episode_name
    return result
end

## Delete an episode (mark as deleted)
function __database_op_delete_episode(; instance_id::String, episode_name::String)
    @debug "Attempting to delete episode" instance_id episode_name

    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "episode_name" => episode_name, "deleted" => false)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("deleted" => true))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Cannot delete episode because it does not exist" instance_id episode_name
        return nothing
    end

    if result["modifiedCount"] != 1
        @debug "Unable to delete episode due to internal error" instance_id episode_name
        return nothing
    end

    @debug "Successfully deleted episode" instance_id episode_name
    return result
end

## Wipe episode events
function __database_op_wipe_episode(; instance_id::String, episode_name::String)
    @debug "Attempting to wipe episode" instance_id episode_name
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "episode_name" => episode_name, "deleted" => false)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("events" => []))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Unable to wipe episode due to internal error" instance_id episode_name
        return nothing
    end

    # modifiedCount can be 0 if the episode has been empty before wiping
    @debug "Successfully wiped episode" instance_id episode_name
    return result
end

## Attach metadata to an event
function __database_op_attach_metadata_to_event(;
    instance_id::String, episode_name::String, event_id::Int, metadata::Dict
)
    @debug "Attempting to attach metadata to event" instance_id episode_name event_id

    collection = Database.collection("episodes")
    query = Mongoc.BSON(
        "instance_id" => instance_id,
        "episode_name" => episode_name,
        "deleted" => false,
        "events" => Mongoc.BSON("\$elemMatch" => Mongoc.BSON("event_id" => event_id))
    )
    update = Mongoc.BSON("\$set" => Mongoc.BSON("events.\$.metadata" => metadata))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Unable to attach metadata to event due to internal error" instance_id episode_name event_id
        return nothing
    end

    if result["modifiedCount"] != 1
        @debug "Unable to attach metadata to event due to internal error" instance_id episode_name event_id
        return nothing
    end

    @debug "Successfully attached metadata to event" instance_id episode_name event_id
    return result
end

## Update model state
function __database_op_update_model_state(; instance_id::String, new_state::Any)
    @debug "Attempting to update model state" instance_id
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("state" => new_state))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Unable to update model state due to internal error" instance_id
        return nothing
    end

    # modifiedCount can be 0 if the model state has not changed

    @debug "Successfully updated model state" instance_id
    return result
end

## Update model current episode
function __database_op_update_model_current_episode(; instance_id::String, episode_name::String)
    @debug "Attempting to update model current episode" instance_id episode_name
    collection = Database.collection("models")
    query = Mongoc.BSON("instance_id" => instance_id)
    update = Mongoc.BSON("\$set" => Mongoc.BSON("current_episode" => episode_name))
    result = Mongoc.update_one(collection, query, update)

    if result["matchedCount"] != 1
        @debug "Unable to update model current episode due to internal error" instance_id episode_name
        return nothing
    end

    # modifiedCount can be 0 if the model current episode has not changed
    @debug "Successfully updated model current episode" instance_id episode_name
    return result
end

## Attach event to episode and return the event ID
function __database_op_attach_event_to_episode(;
    instance_id::String, episode_name::String, data::Any, timestamp::DateTime
)::Union{Int, Nothing}
    @debug "Attempting to attach event to episode" instance_id episode_name
    collection = Database.collection("episodes")
    query = Mongoc.BSON("instance_id" => instance_id, "episode_name" => episode_name, "deleted" => false)

    # Get the current number of events from the n_events field
    options = Mongoc.BSON("projection" => Mongoc.BSON("events_id_counter" => 1))
    current = Mongoc.find_one(collection, query; options = options)
    next_id = isnothing(current) ? 1 : current["events_id_counter"] + 1

    update = Mongoc.BSON(
        "\$push" => Mongoc.BSON("events" => Dict("event_id" => next_id, "data" => data, "timestamp" => timestamp)),
        "\$set" => Mongoc.BSON("events_id_counter" => next_id)
    )

    options = Mongoc.BSON(
        "returnDocument" => "after", "projection" => Mongoc.BSON("event_id" => Mongoc.BSON("\$size" => "\$events"))
    )
    result = Mongoc.find_one_and_update(collection, query, update; options = options)

    if isnothing(result)
        @debug "Unable to attach event to episode due to internal error" instance_id episode_name
        return nothing
    end

    @debug "Successfully attached event to episode" instance_id episode_name next_id
    return next_id
end
