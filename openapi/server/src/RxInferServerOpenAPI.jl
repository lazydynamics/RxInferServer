# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""
Encapsulates generated server code for RxInferServerOpenAPI

The following server methods must be implemented:

- **token_generate**
    - *invocation:* POST /token/generate
    - *signature:* token_generate(req::HTTP.Request;) -> TokenGenerateResponse
- **token_roles**
    - *invocation:* GET /token/roles
    - *signature:* token_roles(req::HTTP.Request;) -> TokenRolesResponse
- **attach_metadata_to_event**
    - *invocation:* POST /models/i/{instance_id}/episodes/{episode_name}/events/{event_id}/attach-metadata
    - *signature:* attach_metadata_to_event(req::HTTP.Request, instance_id::String, episode_name::String, event_id::Int64, attach_metadata_to_event_request::AttachMetadataToEventRequest;) -> SuccessResponse
- **create_episode**
    - *invocation:* POST /models/i/{instance_id}/episodes/{episode_name}/create
    - *signature:* create_episode(req::HTTP.Request, instance_id::String, episode_name::String;) -> EpisodeInfo
- **create_model_instance**
    - *invocation:* POST /models/create-instance
    - *signature:* create_model_instance(req::HTTP.Request, create_model_instance_request::CreateModelInstanceRequest;) -> CreateModelInstanceResponse
- **delete_episode**
    - *invocation:* DELETE /models/i/{instance_id}/episodes/{episode_name}/delete
    - *signature:* delete_episode(req::HTTP.Request, instance_id::String, episode_name::String;) -> SuccessResponse
- **delete_model_instance**
    - *invocation:* DELETE /models/i/{instance_id}
    - *signature:* delete_model_instance(req::HTTP.Request, instance_id::String;) -> SuccessResponse
- **get_available_model**
    - *invocation:* GET /models/available/{model_name}
    - *signature:* get_available_model(req::HTTP.Request, model_name::String;) -> AvailableModel
- **get_available_models**
    - *invocation:* GET /models/available
    - *signature:* get_available_models(req::HTTP.Request;) -> Vector{AvailableModel}
- **get_episode_info**
    - *invocation:* GET /models/i/{instance_id}/episodes/{episode_name}
    - *signature:* get_episode_info(req::HTTP.Request, instance_id::String, episode_name::String;) -> EpisodeInfo
- **get_episodes**
    - *invocation:* GET /models/i/{instance_id}/episodes
    - *signature:* get_episodes(req::HTTP.Request, instance_id::String;) -> Vector{EpisodeInfo}
- **get_model_instance**
    - *invocation:* GET /models/i/{instance_id}
    - *signature:* get_model_instance(req::HTTP.Request, instance_id::String;) -> ModelInstance
- **get_model_instance_state**
    - *invocation:* GET /models/i/{instance_id}/state
    - *signature:* get_model_instance_state(req::HTTP.Request, instance_id::String;) -> ModelInstanceState
- **get_model_instances**
    - *invocation:* GET /models/created-instances
    - *signature:* get_model_instances(req::HTTP.Request;) -> Vector{ModelInstance}
- **run_inference**
    - *invocation:* POST /models/i/{instance_id}/infer
    - *signature:* run_inference(req::HTTP.Request, instance_id::String, infer_request::InferRequest;) -> InferResponse
- **run_learning**
    - *invocation:* POST /models/i/{instance_id}/learn
    - *signature:* run_learning(req::HTTP.Request, instance_id::String, learn_request::LearnRequest;) -> LearnResponse
- **wipe_episode**
    - *invocation:* POST /models/i/{instance_id}/episodes/{episode_name}/wipe
    - *signature:* wipe_episode(req::HTTP.Request, instance_id::String, episode_name::String;) -> SuccessResponse
- **get_server_info**
    - *invocation:* GET /info
    - *signature:* get_server_info(req::HTTP.Request;) -> ServerInfo
- **ping_server**
    - *invocation:* GET /ping
    - *signature:* ping_server(req::HTTP.Request;) -> PingResponse
"""
module RxInferServerOpenAPI

using HTTP
using URIs
using Dates
using TimeZones
using OpenAPI
using OpenAPI.Servers

const API_VERSION = "0.0.1"

include("modelincludes.jl")

include("apis/api_AuthenticationApi.jl")
include("apis/api_ModelsApi.jl")
include("apis/api_ServerApi.jl")

"""
Register handlers for all APIs in this module in the supplied `Router` instance.

Paramerets:
- `router`: Router to register handlers in
- `impl`: module that implements the server methods

Optional parameters:
- `path_prefix`: prefix to be applied to all paths
- `optional_middlewares`: Register one or more optional middlewares to be applied to all requests.

Optional middlewares can be one or more of:
    - `init`: called before the request is processed
    - `pre_validation`: called after the request is parsed but before validation
    - `pre_invoke`: called after validation but before the handler is invoked
    - `post_invoke`: called after the handler is invoked but before the response is sent

The order in which middlewares are invoked are:
`init |> read |> pre_validation |> validate |> pre_invoke |> invoke |> post_invoke`
"""
function register(router::HTTP.Router, impl; path_prefix::String="", optional_middlewares...)
    registerAuthenticationApi(router, impl; path_prefix=path_prefix, optional_middlewares...)
    registerModelsApi(router, impl; path_prefix=path_prefix, optional_middlewares...)
    registerServerApi(router, impl; path_prefix=path_prefix, optional_middlewares...)
    return router
end

end # module RxInferServerOpenAPI
