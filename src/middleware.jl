const CORS_ACCESS_CONTROL_ALLOW_ORIGIN = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN", "*")
const CORS_ACCESS_CONTROL_ALLOW_METHODS = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS", "GET, POST, PUT, DELETE, OPTIONS")
const CORS_ACCESS_CONTROL_ALLOW_HEADERS = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS", "Content-Type, Authorization")

const CORS_RES_HEADERS = [
    "Access-Control-Allow-Origin" => CORS_ACCESS_CONTROL_ALLOW_ORIGIN,
    "Access-Control-Allow-Methods" => CORS_ACCESS_CONTROL_ALLOW_METHODS,
    "Access-Control-Allow-Headers" => CORS_ACCESS_CONTROL_ALLOW_HEADERS
]

function middleware_post_invoke_cors(res::HTTP.Response)
    foreach(CORS_RES_HEADERS) do (header, value)
        if !HTTP.hasheader(res, header)
            push!(res.headers, header => value)
        end
    end
    return res
end

const CORS_OPTIONS_RESPONSE = HTTP.Response(200, CORS_RES_HEADERS)

function cors404(req::HTTP.Request)
    if HTTP.method(req) == "OPTIONS"
        return CORS_OPTIONS_RESPONSE
    end
    return HTTP.Response(404)
end

function cors405(req::HTTP.Request)
    if HTTP.method(req) == "OPTIONS"
        return CORS_OPTIONS_RESPONSE
    end
    return HTTP.Response(405)
end

function middleware_cors(handler::F) where {F}
    return function (req::HTTP.Request)
        if HTTP.method(req) == "OPTIONS"
            return CORS_OPTIONS_RESPONSE
        end
        return handler(req) |> middleware_post_invoke_cors
    end
end

const DEV_TOKEN = get(ENV, "RXINFER_SERVER_DEV_TOKEN", "dev-token")

# List of URL paths that are exempt from authentication
const AUTH_EXEMPT_PATHS = [
    string(API_PATH_PREFIX, "/token")
]

"""
    should_bypass_auth(req::HTTP.Request)::Bool

Determine if a request should bypass authentication checks.
Returns true if the request path is in the AUTH_EXEMPT_PATHS list.
"""
function should_bypass_auth(req::HTTP.Request)::Bool
    request_path = HTTP.URI(req.target).path
    return request_path in AUTH_EXEMPT_PATHS
end

function middleware_check_token(req::HTTP.Request)::Bool
    token = HTTP.header(req, "Authorization")
    if isnothing(token)
        return false
    end
    # Extract token after "Bearer " prefix
    if !startswith(token, "Bearer ")
        return false
    end
    token = token[8:end]

    # In development, accept the dev token (unless set to "disabled")
    if DEV_TOKEN != "disabled" && token == DEV_TOKEN
        return true
    end

    # Add your production token validation logic here
    # For now, always return false until production validation is implemented
    return false
end

const UNAUTHORIZED_RESPONSE = middleware_post_invoke_cors(
    HTTP.Response(401, RxInferServerOpenAPI.UnauthorizedResponse(
        message=ifelse(
            DEV_TOKEN != "disabled",
            "The request requires authentication, generate a token using the /token endpoint or use the development token `$(DEV_TOKEN)`",
            "The request requires authentication, generate a token using the /token endpoint"
        )
    ))
)

function middleware_check_token(handler::F) where {F}
    return function (req::HTTP.Request)
        # First check if this request should bypass 
        # authentication entirely
        if should_bypass_auth(req)
            return handler(req)
        end

        if !middleware_check_token(req)
            return UNAUTHORIZED_RESPONSE
        end

        # Request is authenticated, proceed to the handler
        return handler(req)
    end
end