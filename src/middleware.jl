"""
The allowed origins for CORS requests.
This can be configured using the `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN` environment variable.
Defaults to "*" (all origins) if not specified.

```julia
# Set allowed origins
ENV["RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN"] = "https://mydomain.com"
```

See also: [`RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN`](@ref)
"""
RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN() = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN", "*")

"""
The allowed methods for CORS requests.
This can be configured using the `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS` environment variable.
Defaults to "GET, POST, PUT, DELETE, OPTIONS" if not specified.

```julia
# Set allowed methods
ENV["RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS"] = "GET, POST, PUT, DELETE, OPTIONS"
```

See also: [`RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS`](@ref)
"""
RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS() =
    get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS", "GET, POST, PUT, DELETE, OPTIONS")

"""
The allowed headers for CORS requests.
This can be configured using the `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS` environment variable.
Defaults to "Content-Type, Authorization" if not specified.

```julia
# Set allowed headers
ENV["RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS"] = "Content-Type, Authorization"
```

See also: [`RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS`](@ref)
"""
RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS() =
    get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS", "Content-Type, Authorization")

function RXINFER_SERVER_CORS_RES_HEADERS()
    return [
        "Access-Control-Allow-Origin" => RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN(),
        "Access-Control-Allow-Methods" => RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS(),
        "Access-Control-Allow-Headers" => RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS()
    ]
end

function RXINFER_SERVER_CORS_OPTIONS_RESPONSE()
    return HTTP.Response(200, RXINFER_SERVER_CORS_RES_HEADERS())
end

function cors404(req::HTTP.Request)
    if HTTP.method(req) == "OPTIONS"
        return RXINFER_SERVER_CORS_OPTIONS_RESPONSE()
    end

    return HTTP.Response(404)
end

function cors405(req::HTTP.Request)
    if HTTP.method(req) == "OPTIONS"
        return RXINFER_SERVER_CORS_OPTIONS_RESPONSE()
    end
    return HTTP.Response(405)
end

# This middleware is only used for the `OPTIONS` method
# The actual CORS functionality is handled in middleware_post_invoke_cors
# for the `HTTP.Response` object returned by the handler
function middleware_cors_options(handler::F) where {F}
    return function (req::HTTP.Request)
        if HTTP.method(req) == "OPTIONS"
            return RXINFER_SERVER_CORS_OPTIONS_RESPONSE()
        end
        return handler(req)
    end
end

function middleware_post_invoke_cors(res::HTTP.Response)
    foreach(RXINFER_SERVER_CORS_RES_HEADERS()) do (header, value)
        if !HTTP.hasheader(res, header)
            push!(res.headers, header => value)
        end
    end
    return res
end

"""
    RoutesHandler

A structure that is used to handle the routes.
It is used to inject extra post-processing logic into the routes, 
e.g. overriding the JSON serialization settings and the response codes.
"""
struct RoutesHandler end

@inline function Base.getproperty(::RoutesHandler, prop::Symbol)
    return let handler = @inline Base.getproperty(@__MODULE__, prop)
        (req::HTTP.Request, args...; kwargs...) -> postprocess_response(req, handler(req, args...; kwargs...))
    end
end

"""
    RequestPreferences(req::HTTP.Request)

A structure that is used to parse and store the request specific preferences from 
the `Prefer` header.
"""
Base.@kwdef struct RequestPreferences
    json_serialization::Serialization.JSONSerialization
    applied_preferences::HTTP.Headers
end

function RequestPreferences(req::HTTP.Request)
    applied_preferences = HTTP.Headers()

    preferences = HTTP.headers(req, "Prefer")
    preferences = Iterators.flatten(Iterators.map(p -> split(p, ","), preferences))

    preference_mdarray_repr = Serialization.MultiDimensionalArrayRepr.Dict
    preference_mdarray_data = Serialization.MultiDimensionalArrayData.ArrayOfArrays

    for preference in preferences
        splitpreference = split(preference, "=")
        length(splitpreference) == 2 || continue
        key, value = splitpreference
        if key == "mdarray_repr"
            preference_mdarray_repr = convert(Serialization.MultiDimensionalArrayRepr.T, value)
            push!(applied_preferences, HTTP.Header("Preference-Applied", preference))
        elseif key == "mdarray_data"
            preference_mdarray_data = convert(Serialization.MultiDimensionalArrayData.T, value)
            push!(applied_preferences, HTTP.Header("Preference-Applied", preference))
        end
    end

    json_serialization = Serialization.JSONSerialization(
        mdarray_repr = preference_mdarray_repr, mdarray_data = preference_mdarray_data
    )

    return RequestPreferences(json_serialization = json_serialization, applied_preferences = applied_preferences)
end

function postprocess_response(req, res)
    response_headers = HTTP.Headers()
    HTTP.setheader(response_headers, HTTP.Header("Content-Type", "application/json"))

    preferences = RequestPreferences(req)

    for header in preferences.applied_preferences
        push!(response_headers, header)
    end

    return HTTP.Response(200, response_headers; body = Serialization.to_json(preferences.json_serialization, res))
end

function postprocess_response(req, res::RxInferServerOpenAPI.UnauthorizedResponse)
    return HTTP.Response(401, res)
end

function postprocess_response(req, res::RxInferServerOpenAPI.NotFoundResponse)
    return HTTP.Response(404, res)
end

function postprocess_response(req, res::RxInferServerOpenAPI.ErrorResponse)
    return HTTP.Response(400, res)
end

"""
    DEFAULT_DEV_TOKEN

The default development token.
"""
const DEFAULT_DEV_TOKEN = "dev-token"

"""
    DEFAULT_DEV_TOKEN_ROLES

The default roles for the development token.
"""
const DEFAULT_DEV_TOKEN_ROLES = ["user"]

"""
An environment variable that can be used to enable development token authentication.
By default, the development token is disabled and the `RXINFER_SERVER_ENABLE_DEV_TOKEN` environment variable set to "false".
Set to "true" to enable development token authentication (do not use in production!).
Note that RxInferServer checks this environment variable only once before starting the server.

```julia
# Use a specific development token
ENV["RXINFER_SERVER_ENABLE_DEV_TOKEN"] = "true"

# Disable development token (production mode)
ENV["RXINFER_SERVER_ENABLE_DEV_TOKEN"] = "false"
```

If enabled use `$(DEFAULT_DEV_TOKEN)` as the development token.
The development token has `$(DEFAULT_DEV_TOKEN_ROLES)` roles by default.
This, however, can be overriden by appending a different comma-separated list of roles directly into
the development token after the `:` symbol. For example:

```julia
ENV["RXINFER_SERVER_ENABLE_DEV_TOKEN"] = "true"

# ...
# token used for making requests with extra roles
token = "$(DEFAULT_DEV_TOKEN):user,admin"
```

!!! warning 
    In production environments, you should always set `RXINFER_SERVER_ENABLE_DEV_TOKEN=false`.
    Failure to do so will make the development token available and usable by anyone,
    which leads to a huge potential security risk.

See also: [`check_dev_token`](@ref)
"""
RXINFER_SERVER_ENABLE_DEV_TOKEN() = lowercase(get(ENV, "RXINFER_SERVER_ENABLE_DEV_TOKEN", "false")) == "true"

"""
    check_dev_token(token::String)

Checks if the token provided is the development token.
Additionally, parses the token to extract the roles from the token.
Returns both the token and the roles if the token is the development token.
Returns nothing if the token is not the development token.

See also: [`RXINFER_SERVER_ENABLE_DEV_TOKEN`](@ref)
"""
function check_dev_token(token)
    RXINFER_SERVER_ENABLE_DEV_TOKEN() || return nothing

    splittoken = split(token, ":")

    if splittoken[1] == DEFAULT_DEV_TOKEN
        if length(splittoken) == 1
            # If token does not contain the `:` use the default roles
            return DEFAULT_DEV_TOKEN, DEFAULT_DEV_TOKEN_ROLES
        elseif length(splittoken) == 2
            # If token contains the `:` use the roles from the token
            roles = split(splittoken[2], ",")
            return DEFAULT_DEV_TOKEN, roles
        else
            return nothing
        end
    else
        return nothing
    end
end

# List of URL paths that are exempt from authentication
const AUTH_EXEMPT_PATHS = [string(API_PATH_PREFIX, "/token/generate"), string(API_PATH_PREFIX, "/ping")]

# Determine if a request should bypass authentication checks.
# Returns true if the request path is in the AUTH_EXEMPT_PATHS list.
function should_bypass_auth(req::HTTP.Request)::Bool
    request_path = HTTP.URI(req.target).path
    return request_path in AUTH_EXEMPT_PATHS
end

# Extract the token from the request and return it and the roles
# Returns nothing if the token is not found or if the token is invalid
# `cache` must be a Dict{String, Vector{String}} 
#   - the token is automatically valid if it is present in the cache
#   - the roles are added to the cache if the token is valid
function middleware_extract_token(
    req::HTTP.Request, cache = nothing, dev_token_enabled = false
)::Union{Nothing, Tuple{String, Vector{String}}}
    token = HTTP.header(req, "Authorization")
    if isnothing(token)
        return nothing
    end
    # Extract token after "Bearer " prefix
    if !startswith(token, "Bearer ")
        return nothing
    end
    token = replace(token, "Bearer " => "")

    # In development mode, first check agains the dev token
    if dev_token_enabled
        dev = check_dev_token(token)
        if !isnothing(dev)
            devtoken, devroles = dev
            return devtoken, devroles
        end
    end

    # Check if the token is in the cache set already
    cached_valid = isnothing(cache) ? false : haskey(cache, token)

    # If the token is in the cache set already, just return true 
    # and avoid calling the database
    if cached_valid
        return token, cache[token]
    end

    # If the token is not in the cache set already, check if it exists in the database
    @debug "Checking if token `$(token)` exists in the database"
    collection = Database.collection("tokens")
    query      = Mongoc.BSON("token" => token)
    result     = Mongoc.find_one(collection, query)

    if isnothing(result)
        @debug "Token `$(token)` does not exist in the database"
        return nothing
    end

    roles = result["roles"]

    if !isnothing(result) && !isnothing(cache)
        cache[token] = roles
        @debug "Cached token $(token) with roles $(roles)"
    end

    return !isnothing(result) ? (token, roles) : nothing
end

using Base.ScopedValues

const _current_token = ScopedValue{String}()
const _current_roles = ScopedValue{Vector{String}}()

"""
    is_authorized()::Bool

Checks if the current request is authenticated.
Returns `true` if a token is available in the current scope, `false` otherwise.

See also: [`current_token`](@ref), [`current_roles`](@ref)
"""
function is_authorized()::Bool
    token = Base.ScopedValues.get(_current_token)
    return !isnothing(token)
end

"""
    current_token()::String

Returns the current authenticated user's token string.
This function should only be called within endpoints that require authentication.

See also: [`is_authorized`](@ref), [`current_roles`](@ref)
"""
function current_token()
    token = Base.ScopedValues.get(_current_token)
    return @something token error(
        "Current token is not set. Call `is_authorized()` to check if the request is authorized."
    )
end

"""
    current_roles()::Vector{String}

Returns the roles assigned to the current authenticated user as a vector of strings.
This function should only be called within endpoints that require authentication.

See also: [`is_authorized`](@ref), [`current_token`](@ref)
"""
function current_roles()
    roles = Base.ScopedValues.get(_current_roles)
    return @something roles error(
        "Current roles are not set. Call `is_authorized()` to check if the request is authorized."
    )
end

struct MiddlewareCheckToken{H, C, U}
    handler::H
    cache::C
    dev_token_enabled::Bool
    unauthorized::U
end

function middleware_check_token(handler::H) where {H}
    cache = Dict{String, Vector{String}}()
    dev_token_enabled = RXINFER_SERVER_ENABLE_DEV_TOKEN()

    # small optimization to avoid creating a new object 
    # for the unauthorized responses multiple times
    unauthorized = middleware_post_invoke_cors(
        HTTP.Response(
            401,
            RxInferServerOpenAPI.UnauthorizedResponse(
                error = "Unauthorized",
                message = ifelse(
                    dev_token_enabled,
                    "The request requires authentication, generate a token using the /generate-token endpoint or use the development token `$(DEFAULT_DEV_TOKEN)`",
                    "The request requires authentication, generate a token using the /generate-token endpoint"
                )
            )
        )
    )

    return MiddlewareCheckToken(handler, cache, dev_token_enabled, unauthorized)
end

function (m::MiddlewareCheckToken)(req::HTTP.Request)
    # First check if this request should bypass 
    # authentication entirely
    should_bypass_auth(req) && return m.handler(req)

    extracted = middleware_extract_token(req, m.cache, m.dev_token_enabled)

    # If the token is not found, return the unauthorized response
    isnothing(extracted) && return m.unauthorized

    # Otherwise, the token is considered valid
    token, roles = extracted

    # Request is authenticated, proceed to the handler
    with(_current_token => token::String, _current_roles => roles) do
        return m.handler(req)
    end
end
