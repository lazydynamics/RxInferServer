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
RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS() = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS", "GET, POST, PUT, DELETE, OPTIONS")

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
RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS() = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS", "Content-Type, Authorization")

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

"""
The development authentication token.
This can be configured using the `RXINFER_SERVER_DEV_TOKEN` environment variable.
Defaults to "dev-token" if not specified.
Set to "disabled" to disable development token authentication (production mode).

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

function middleware_extract_token(req::HTTP.Request, cache = nothing)::Tuple{Union{Nothing, String}, Bool}
    token = HTTP.header(req, "Authorization")
    if isnothing(token)
        return nothing, false
    end
    # Extract token after "Bearer " prefix
    if !startswith(token, "Bearer ")
        return nothing, false
    end
    token = replace(token, "Bearer " => "")

    # In development, accept the dev token (unless set to "disabled")
    if is_dev_token_enabled() && is_dev_token(token)
        return token, true
    end

    # Check if the token is in the cache set already
    cached_valid = isnothing(cache) ? false : token ∈ cache

    # If the token is in the cache set already, just return true 
    # and avoid calling the database
    if cached_valid
        return token, true
    end

    # If the token is not in the cache set already, check if it exists in the database
    collection = Database.collection("tokens")
    query      = Mongoc.BSON("token" => token)
    result     = Mongoc.find_one(collection, query)

    if !isnothing(result) && !isnothing(cache)
        push!(cache, token)
    end

    return !isnothing(result) ? (token, true) : (nothing, false)
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

const _current_token = ScopedValue{Union{Nothing, String}}(nothing)

is_authorized()::Bool = !isnothing(_current_token[])
current_token()::String = _current_token[]::String

function middleware_check_token(handler::F) where {F}
    cache = Set{String}()
    return function (req::HTTP.Request)
        # First check if this request should bypass 
        # authentication entirely
        if should_bypass_auth(req)
            return handler(req)
        end

        token, is_valid = middleware_extract_token(req, cache)

        if !is_valid
            return UNAUTHORIZED_RESPONSE
        end

        # Request is authenticated, proceed to the handler
        with(_current_token => token::String) do
            return handler(req)
        end
    end
end
