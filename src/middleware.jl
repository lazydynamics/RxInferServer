const CORS_ACCESS_CONTROL_ALLOW_ORIGIN = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN", "*")
const CORS_ACCESS_CONTROL_ALLOW_METHODS = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS", "GET, POST, PUT, DELETE, OPTIONS")
const CORS_ACCESS_CONTROL_ALLOW_HEADERS = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS", "Content-Type, Authorization")
const DEV_TOKEN = get(ENV, "RXINFER_SERVER_DEV_TOKEN", "dev-token")

function middleware_post_invoke_cors(res::HTTP.Response)
    if !HTTP.hasheader(res, "Access-Control-Allow-Origin")
        push!(res.headers, "Access-Control-Allow-Origin" => CORS_ACCESS_CONTROL_ALLOW_ORIGIN)
    end
    if !HTTP.hasheader(res, "Access-Control-Allow-Methods")
        push!(res.headers, "Access-Control-Allow-Methods" => CORS_ACCESS_CONTROL_ALLOW_METHODS)
    end
    if !HTTP.hasheader(res, "Access-Control-Allow-Headers")
        push!(res.headers, "Access-Control-Allow-Headers" => CORS_ACCESS_CONTROL_ALLOW_HEADERS)
    end
    return res
end

function middleware_check_token(req::HTTP.Request)
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