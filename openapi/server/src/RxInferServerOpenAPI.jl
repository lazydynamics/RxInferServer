# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


@doc raw"""
Encapsulates generated server code for RxInferServerOpenAPI

The following server methods must be implemented:

- **generate_token**
    - *invocation:* POST /generate-token
    - *signature:* generate_token(req::HTTP.Request;) -> TokenResponse
- **create_model**
    - *invocation:* POST /models/create
    - *signature:* create_model(req::HTTP.Request, create_model_request::CreateModelRequest;) -> CreateModelResponse
- **delete_model**
    - *invocation:* DELETE /models/{model_id}/delete
    - *signature:* delete_model(req::HTTP.Request, model_id::String;) -> SuccessResponse
- **get_created_models_info**
    - *invocation:* GET /models/created/info
    - *signature:* get_created_models_info(req::HTTP.Request;) -> Vector{CreatedModelInfo}
- **get_model_details**
    - *invocation:* GET /models/{model_name}/details
    - *signature:* get_model_details(req::HTTP.Request, model_name::String;) -> ModelDetails
- **get_model_info**
    - *invocation:* GET /models/{model_id}/info
    - *signature:* get_model_info(req::HTTP.Request, model_id::String;) -> CreatedModelInfo
- **get_models**
    - *invocation:* GET /models
    - *signature:* get_models(req::HTTP.Request;) -> ModelList
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

const API_VERSION = "1.0.0"

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
