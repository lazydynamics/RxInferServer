# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.

struct ModelsApi <: OpenAPI.APIClientImpl
    client::OpenAPI.Clients.Client
end

"""
The default API base path for APIs in `ModelsApi`.
This can be used to construct the `OpenAPI.Clients.Client` instance.
"""
basepath(::Type{ ModelsApi }) = "http://localhost:8000/v1"

const _returntypes_attach_metadata_to_event_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => SuccessResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_attach_metadata_to_event(_api::ModelsApi, instance_id::String, episode_name::String, event_id::Int64, attach_metadata_to_event_request::AttachMetadataToEventRequest; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "POST", _returntypes_attach_metadata_to_event_ModelsApi, "/models/i/{instance_id}/episodes/{episode_name}/events/{event_id}/attach-metadata", ["ApiKeyAuth", ], attach_metadata_to_event_request)
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_param(_ctx.path, "episode_name", episode_name)  # type String
    OpenAPI.Clients.set_param(_ctx.path, "event_id", event_id)  # type Int64
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? ["application/json", ] : [_mediaType])
    return _ctx
end

@doc raw"""Attach metadata to an event

Attach metadata to a specific event for a model

Params:
- instance_id::String (required)
- episode_name::String (required)
- event_id::Int64 (required)
- attach_metadata_to_event_request::AttachMetadataToEventRequest (required)

Return: SuccessResponse, OpenAPI.Clients.ApiResponse
"""
function attach_metadata_to_event(_api::ModelsApi, instance_id::String, episode_name::String, event_id::Int64, attach_metadata_to_event_request::AttachMetadataToEventRequest; _mediaType=nothing)
    _ctx = _oacinternal_attach_metadata_to_event(_api, instance_id, episode_name, event_id, attach_metadata_to_event_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function attach_metadata_to_event(_api::ModelsApi, response_stream::Channel, instance_id::String, episode_name::String, event_id::Int64, attach_metadata_to_event_request::AttachMetadataToEventRequest; _mediaType=nothing)
    _ctx = _oacinternal_attach_metadata_to_event(_api, instance_id, episode_name, event_id, attach_metadata_to_event_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_create_episode_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => EpisodeInfo,
    Regex("^" * replace("400", "x"=>".") * "\$") => ErrorResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_create_episode(_api::ModelsApi, instance_id::String, create_episode_request::CreateEpisodeRequest; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "POST", _returntypes_create_episode_ModelsApi, "/models/i/{instance_id}/create-episode", ["ApiKeyAuth", ], create_episode_request)
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? ["application/json", ] : [_mediaType])
    return _ctx
end

@doc raw"""Create a new episode for a model instance

Create a new episode for a specific model instance. Note that the default episode is created automatically when the model instance is created.  When a new episode is created, it becomes the current episode for the model instance. 

Params:
- instance_id::String (required)
- create_episode_request::CreateEpisodeRequest (required)

Return: EpisodeInfo, OpenAPI.Clients.ApiResponse
"""
function create_episode(_api::ModelsApi, instance_id::String, create_episode_request::CreateEpisodeRequest; _mediaType=nothing)
    _ctx = _oacinternal_create_episode(_api, instance_id, create_episode_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function create_episode(_api::ModelsApi, response_stream::Channel, instance_id::String, create_episode_request::CreateEpisodeRequest; _mediaType=nothing)
    _ctx = _oacinternal_create_episode(_api, instance_id, create_episode_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_create_model_instance_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => CreateModelInstanceResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("400", "x"=>".") * "\$") => ErrorResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_create_model_instance(_api::ModelsApi, create_model_instance_request::CreateModelInstanceRequest; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "POST", _returntypes_create_model_instance_ModelsApi, "/models/create-instance", ["ApiKeyAuth", ], create_model_instance_request)
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? ["application/json", ] : [_mediaType])
    return _ctx
end

@doc raw"""Create a new model instance

Creates a new instance of a model with the specified configuration

Params:
- create_model_instance_request::CreateModelInstanceRequest (required)

Return: CreateModelInstanceResponse, OpenAPI.Clients.ApiResponse
"""
function create_model_instance(_api::ModelsApi, create_model_instance_request::CreateModelInstanceRequest; _mediaType=nothing)
    _ctx = _oacinternal_create_model_instance(_api, create_model_instance_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function create_model_instance(_api::ModelsApi, response_stream::Channel, create_model_instance_request::CreateModelInstanceRequest; _mediaType=nothing)
    _ctx = _oacinternal_create_model_instance(_api, create_model_instance_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_delete_episode_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => SuccessResponse,
    Regex("^" * replace("400", "x"=>".") * "\$") => ErrorResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_delete_episode(_api::ModelsApi, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "DELETE", _returntypes_delete_episode_ModelsApi, "/models/i/{instance_id}/episodes/{episode_name}", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_param(_ctx.path, "episode_name", episode_name)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Delete an episode for a model

Delete a specific episode for a model instance. Note that the default episode cannot be deleted, but you can wipe data from it. If the deleted episode was the current episode, the default episode will become the current episode. 

Params:
- instance_id::String (required)
- episode_name::String (required)

Return: SuccessResponse, OpenAPI.Clients.ApiResponse
"""
function delete_episode(_api::ModelsApi, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = _oacinternal_delete_episode(_api, instance_id, episode_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function delete_episode(_api::ModelsApi, response_stream::Channel, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = _oacinternal_delete_episode(_api, instance_id, episode_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_delete_model_instance_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => SuccessResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_delete_model_instance(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "DELETE", _returntypes_delete_model_instance_ModelsApi, "/models/i/{instance_id}", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Delete a model instance

Delete a specific model instance by its ID

Params:
- instance_id::String (required)

Return: SuccessResponse, OpenAPI.Clients.ApiResponse
"""
function delete_model_instance(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_delete_model_instance(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function delete_model_instance(_api::ModelsApi, response_stream::Channel, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_delete_model_instance(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_available_model_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => AvailableModel,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_get_available_model(_api::ModelsApi, model_name::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_available_model_ModelsApi, "/models/available/{model_name}", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "model_name", model_name)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get information about a specific model available for creation

Retrieve detailed information about a specific model available for creation

Params:
- model_name::String (required)

Return: AvailableModel, OpenAPI.Clients.ApiResponse
"""
function get_available_model(_api::ModelsApi, model_name::String; _mediaType=nothing)
    _ctx = _oacinternal_get_available_model(_api, model_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_available_model(_api::ModelsApi, response_stream::Channel, model_name::String; _mediaType=nothing)
    _ctx = _oacinternal_get_available_model(_api, model_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_available_models_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => Vector{AvailableModel},
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
)

function _oacinternal_get_available_models(_api::ModelsApi; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_available_models_ModelsApi, "/models/available", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get models available for creation

Retrieve the list of models available for creation for a given token. This list specifies names and available arguments for each model.  **Note** The list of available models might differ for different access tokens. For example, a token with only the \"user\" role might not have access to all models. 

Params:

Return: Vector{AvailableModel}, OpenAPI.Clients.ApiResponse
"""
function get_available_models(_api::ModelsApi; _mediaType=nothing)
    _ctx = _oacinternal_get_available_models(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_available_models(_api::ModelsApi, response_stream::Channel; _mediaType=nothing)
    _ctx = _oacinternal_get_available_models(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_episode_info_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => EpisodeInfo,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_get_episode_info(_api::ModelsApi, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_episode_info_ModelsApi, "/models/i/{instance_id}/episodes/{episode_name}", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_param(_ctx.path, "episode_name", episode_name)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get episode information

Retrieve information about a specific episode of a model

Params:
- instance_id::String (required)
- episode_name::String (required)

Return: EpisodeInfo, OpenAPI.Clients.ApiResponse
"""
function get_episode_info(_api::ModelsApi, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = _oacinternal_get_episode_info(_api, instance_id, episode_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_episode_info(_api::ModelsApi, response_stream::Channel, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = _oacinternal_get_episode_info(_api, instance_id, episode_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_episodes_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => Vector{EpisodeInfo},
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_get_episodes(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_episodes_ModelsApi, "/models/i/{instance_id}/episodes", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get all episodes for a model instance

Retrieve all episodes for a specific model instance

Params:
- instance_id::String (required)

Return: Vector{EpisodeInfo}, OpenAPI.Clients.ApiResponse
"""
function get_episodes(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_episodes(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_episodes(_api::ModelsApi, response_stream::Channel, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_episodes(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_model_instance_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => ModelInstance,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_get_model_instance(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_model_instance_ModelsApi, "/models/i/{instance_id}", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get model instance information

Retrieve detailed information about a specific model instance

Params:
- instance_id::String (required)

Return: ModelInstance, OpenAPI.Clients.ApiResponse
"""
function get_model_instance(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instance(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_model_instance(_api::ModelsApi, response_stream::Channel, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instance(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_model_instance_parameters_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => ModelInstanceParameters,
    Regex("^" * replace("400", "x"=>".") * "\$") => ErrorResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_get_model_instance_parameters(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_model_instance_parameters_ModelsApi, "/models/i/{instance_id}/parameters", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get the parameters of a model instance

Retrieve the parameters of a specific model instance

Params:
- instance_id::String (required)

Return: ModelInstanceParameters, OpenAPI.Clients.ApiResponse
"""
function get_model_instance_parameters(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instance_parameters(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_model_instance_parameters(_api::ModelsApi, response_stream::Channel, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instance_parameters(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_model_instance_state_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => ModelInstanceState,
    Regex("^" * replace("400", "x"=>".") * "\$") => ErrorResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_get_model_instance_state(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_model_instance_state_ModelsApi, "/models/i/{instance_id}/state", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get the state of a model instance

Retrieve the state of a specific model instance

Params:
- instance_id::String (required)

Return: ModelInstanceState, OpenAPI.Clients.ApiResponse
"""
function get_model_instance_state(_api::ModelsApi, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instance_state(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_model_instance_state(_api::ModelsApi, response_stream::Channel, instance_id::String; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instance_state(_api, instance_id; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_get_model_instances_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => Vector{ModelInstance},
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
)

function _oacinternal_get_model_instances(_api::ModelsApi; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "GET", _returntypes_get_model_instances_ModelsApi, "/models/instances", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Get all created model instances

Retrieve detailed information about all created model instances for a specific token

Params:

Return: Vector{ModelInstance}, OpenAPI.Clients.ApiResponse
"""
function get_model_instances(_api::ModelsApi; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instances(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function get_model_instances(_api::ModelsApi, response_stream::Channel; _mediaType=nothing)
    _ctx = _oacinternal_get_model_instances(_api; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_run_inference_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => InferResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_run_inference(_api::ModelsApi, instance_id::String, infer_request::InferRequest; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "POST", _returntypes_run_inference_ModelsApi, "/models/i/{instance_id}/infer", ["ApiKeyAuth", ], infer_request)
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? ["application/json", ] : [_mediaType])
    return _ctx
end

@doc raw"""Run inference

Run inference on a specific model instance

Params:
- instance_id::String (required)
- infer_request::InferRequest (required)

Return: InferResponse, OpenAPI.Clients.ApiResponse
"""
function run_inference(_api::ModelsApi, instance_id::String, infer_request::InferRequest; _mediaType=nothing)
    _ctx = _oacinternal_run_inference(_api, instance_id, infer_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function run_inference(_api::ModelsApi, response_stream::Channel, instance_id::String, infer_request::InferRequest; _mediaType=nothing)
    _ctx = _oacinternal_run_inference(_api, instance_id, infer_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_run_learning_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => LearnResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_run_learning(_api::ModelsApi, instance_id::String, learn_request::LearnRequest; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "POST", _returntypes_run_learning_ModelsApi, "/models/i/{instance_id}/learn", ["ApiKeyAuth", ], learn_request)
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? ["application/json", ] : [_mediaType])
    return _ctx
end

@doc raw"""Learn from previous observations

Learn from previous episodes for a specific model

Params:
- instance_id::String (required)
- learn_request::LearnRequest (required)

Return: LearnResponse, OpenAPI.Clients.ApiResponse
"""
function run_learning(_api::ModelsApi, instance_id::String, learn_request::LearnRequest; _mediaType=nothing)
    _ctx = _oacinternal_run_learning(_api, instance_id, learn_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function run_learning(_api::ModelsApi, response_stream::Channel, instance_id::String, learn_request::LearnRequest; _mediaType=nothing)
    _ctx = _oacinternal_run_learning(_api, instance_id, learn_request; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

const _returntypes_wipe_episode_ModelsApi = Dict{Regex,Type}(
    Regex("^" * replace("200", "x"=>".") * "\$") => SuccessResponse,
    Regex("^" * replace("401", "x"=>".") * "\$") => UnauthorizedResponse,
    Regex("^" * replace("404", "x"=>".") * "\$") => NotFoundResponse,
)

function _oacinternal_wipe_episode(_api::ModelsApi, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = OpenAPI.Clients.Ctx(_api.client, "POST", _returntypes_wipe_episode_ModelsApi, "/models/i/{instance_id}/episodes/{episode_name}/wipe", ["ApiKeyAuth", ])
    OpenAPI.Clients.set_param(_ctx.path, "instance_id", instance_id)  # type String
    OpenAPI.Clients.set_param(_ctx.path, "episode_name", episode_name)  # type String
    OpenAPI.Clients.set_header_accept(_ctx, ["application/json", ])
    OpenAPI.Clients.set_header_content_type(_ctx, (_mediaType === nothing) ? [] : [_mediaType])
    return _ctx
end

@doc raw"""Wipe all events from an episode

Wipe all events from a specific episode for a model

Params:
- instance_id::String (required)
- episode_name::String (required)

Return: SuccessResponse, OpenAPI.Clients.ApiResponse
"""
function wipe_episode(_api::ModelsApi, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = _oacinternal_wipe_episode(_api, instance_id, episode_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx)
end

function wipe_episode(_api::ModelsApi, response_stream::Channel, instance_id::String, episode_name::String; _mediaType=nothing)
    _ctx = _oacinternal_wipe_episode(_api, instance_id, episode_name; _mediaType=_mediaType)
    return OpenAPI.Clients.exec(_ctx, response_stream)
end

export attach_metadata_to_event
export create_episode
export create_model_instance
export delete_episode
export delete_model_instance
export get_available_model
export get_available_models
export get_episode_info
export get_episodes
export get_model_instance
export get_model_instance_parameters
export get_model_instance_state
export get_model_instances
export run_inference
export run_learning
export wipe_episode
