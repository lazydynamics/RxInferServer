# This file was generated by the Julia OpenAPI Code Generator
# Do not modify this file directly. Modify the OpenAPI specification instead.


function generate_token_read(handler)
    function generate_token_read_handler(req::HTTP.Request)
        openapi_params = Dict{String,Any}()
        req.context[:openapi_params] = openapi_params

        return handler(req)
    end
end

function generate_token_validate(handler)
    function generate_token_validate_handler(req::HTTP.Request)
        openapi_params = req.context[:openapi_params]
        
        return handler(req)
    end
end

function generate_token_invoke(impl; post_invoke=nothing)
    function generate_token_invoke_handler(req::HTTP.Request)
        openapi_params = req.context[:openapi_params]
        ret = impl.generate_token(req::HTTP.Request;)
        resp = OpenAPI.Servers.server_response(ret)
        return (post_invoke === nothing) ? resp : post_invoke(req, resp)
    end
end


function registerAuthenticationApi(router::HTTP.Router, impl; path_prefix::String="", optional_middlewares...)
    HTTP.register!(router, "POST", path_prefix * "/token", OpenAPI.Servers.middleware(impl, generate_token_read, generate_token_validate, generate_token_invoke; optional_middlewares...))
    return router
end
