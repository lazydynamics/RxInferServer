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

function middleware_post_invoke_cors(res::HTTP.Response)
    foreach(RXINFER_SERVER_CORS_RES_HEADERS()) do (header, value)
        if !HTTP.hasheader(res, header)
            push!(res.headers, header => value)
        end
    end
    return res
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

function middleware_cors(handler::F) where {F}
    return function (req::HTTP.Request)
        if HTTP.method(req) == "OPTIONS"
            return RXINFER_SERVER_CORS_OPTIONS_RESPONSE()
        end
        return handler(req) |> middleware_post_invoke_cors
    end
end

const DEFAULT_DEV_TOKEN_ROLES = ["user", "admin", "test"]

"""
The development authentication token.
This can be configured using the `RXINFER_SERVER_DEV_TOKEN` environment variable.
Defaults to "dev-token" if not specified.
Set to "disabled" to disable development token authentication (production mode).
The development token has `$(DEFAULT_DEV_TOKEN_ROLES)` roles by default.

```julia
# Use a specific development token
ENV["RXINFER_SERVER_DEV_TOKEN"] = "my-custom-token"

# Disable development token (production mode)
ENV["RXINFER_SERVER_DEV_TOKEN"] = "disabled"
```

!!! warning 
    In production environments, you should always set `RXINFER_SERVER_DEV_TOKEN=disabled`.

See also: [`is_dev_token_enabled`](@ref), [`is_dev_token_disabled`](@ref), [`is_dev_token`](@ref)
"""
RXINFER_SERVER_DEV_TOKEN() = get(ENV, "RXINFER_SERVER_DEV_TOKEN", "dev-token")

"""
    is_dev_token_enabled()::Bool

Returns true if the development token is enabled.
Set the `RXINFER_SERVER_DEV_TOKEN` environment variable to `disabled` to disable the development token.
Any other value will enable the development token.

See also: [`is_dev_token_disabled`](@ref), [`is_dev_token`](@ref), [`RXINFER_SERVER_DEV_TOKEN`](@ref)
"""
is_dev_token_enabled() = RXINFER_SERVER_DEV_TOKEN() != "disabled"

"""
    is_dev_token_disabled()::Bool

Returns true if the development token is disabled.
Set the `RXINFER_SERVER_DEV_TOKEN` environment variable to `disabled` to disable the development token.
Any other value will enable the development token.

See also: [`is_dev_token_enabled`](@ref), [`is_dev_token`](@ref), [`RXINFER_SERVER_DEV_TOKEN`](@ref)
"""
is_dev_token_disabled() = RXINFER_SERVER_DEV_TOKEN() == "disabled"

"""
    is_dev_token(token::String)::Bool

Returns true if the token is the development token. Returns false if the development token is disabled.

See also: [`is_dev_token_enabled`](@ref), [`is_dev_token_disabled`](@ref), [`RXINFER_SERVER_DEV_TOKEN`](@ref)
"""
is_dev_token(token) = is_dev_token_enabled() && token == RXINFER_SERVER_DEV_TOKEN()

# List of URL paths that are exempt from authentication
const AUTH_EXEMPT_PATHS = [string(API_PATH_PREFIX, "/generate-token"), string(API_PATH_PREFIX, "/ping")]

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
function middleware_extract_token(req::HTTP.Request, cache = nothing)::Union{Nothing, Tuple{String, Vector{String}}}
    token = HTTP.header(req, "Authorization")
    if isnothing(token)
        return nothing
    end
    # Extract token after "Bearer " prefix
    if !startswith(token, "Bearer ")
        return nothing
    end
    token = replace(token, "Bearer " => "")

    # In development, accept the dev token (unless set to "disabled")
    if is_dev_token_enabled() && is_dev_token(token)
        return token, DEFAULT_DEV_TOKEN_ROLES
    end

    # Check if the token is in the cache set already
    cached_valid = isnothing(cache) ? false : haskey(cache, token)

    # If the token is in the cache set already, just return true 
    # and avoid calling the database
    if cached_valid
        return token, cache[token]
    end

    # If the token is not in the cache set already, check if it exists in the database
    collection = Database.collection("tokens")
    query      = Mongoc.BSON("token" => token)
    result     = Mongoc.find_one(collection, query)
    roles      = collect(split(result["role"], ","))

    if !isnothing(result) && !isnothing(cache)
        cache[token] = roles
        @debug "Cached token $(token) with roles $(roles)"
    end

    return !isnothing(result) ? (token, roles) : nothing
end

const UNAUTHORIZED_RESPONSE = middleware_post_invoke_cors(
    HTTP.Response(
        401,
        RxInferServerOpenAPI.ErrorResponse(
            error = "Unauthorized",
            message = ifelse(
                is_dev_token_enabled(),
                "The request requires authentication, generate a token using the /generate-token endpoint or use the development token `$(RXINFER_SERVER_DEV_TOKEN())`",
                "The request requires authentication, generate a token using the /generate-token endpoint"
            )
        )
    )
)

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

function middleware_check_token(handler::F) where {F}
    cache = Dict{String, Vector{String}}()
    return function (req::HTTP.Request)
        # First check if this request should bypass 
        # authentication entirely
        if should_bypass_auth(req)
            return handler(req)
        end

        extracted = middleware_extract_token(req, cache)

        if isnothing(extracted)
            return UNAUTHORIZED_RESPONSE
        end

        token, roles = extracted

        # Request is authenticated, proceed to the handler
        with(_current_token => token::String, _current_roles => roles) do
            return handler(req)
        end
    end
end
