using HTTP
using RxInfer
using JSON3

export RxInferModelServer, add, start, stop, add_model

"""
    RxInferModelServer

A modular web server that allows dynamic addition of endpoints, particularly for serving RxInfer models.
"""
mutable struct RxInferModelServer
    router::HTTP.Router
    server::Union{Nothing,HTTP.Server}
    port::Int

    function RxInferModelServer(port::Int=8080)
        new(HTTP.Router(), nothing, port)
    end
end

"""
    add_model(server::RxInferModelServer, path::String, model_spec::GraphPPL.ModelGenerator, output_vars::Vector{Symbol}; 
             method::String="POST", kwargs...)

Add a new endpoint that serves a RxInfer model.

# Arguments
- `server`: The web server instance
- `path`: The endpoint path (e.g., "/model")
- `model_spec`: The RxInfer model specification
- `output_vars`: Variables to return in the response
- `method`: The HTTP method (default: "POST")
- `kwargs...`: Additional keyword arguments including:
  - `constraints`: Model constraints (optional)
  - `initialization`: Model initialization (optional)
  - Default inference parameters (e.g., iterations, free_energy)
"""
function add_model(server::RxInferModelServer, path::String, model_spec::GraphPPL.ModelGenerator, output_vars::Vector{Symbol};
    method::String="POST", kwargs...)

    # Extract model configuration from kwargs
    model_kwargs = Dict{Symbol,Any}()
    inference_kwargs = Dict{Symbol,Any}()

    for (k, v) in kwargs
        if k in (:constraints, :initialization)
            model_kwargs[k] = v
        else
            inference_kwargs[k] = v
        end
    end

    # Create deployable model with optional constraints and initialization
    deployable = DeployableRxInferModel(
        model_spec,
        get(model_kwargs, :constraints, nothing),
        get(model_kwargs, :initialization, nothing)
    )

    function handler(req::HTTP.Request)
        # Parse the JSON request body
        body = JSON3.read(req.body)

        # Extract data and any inference parameters from request
        if !haskey(body, :data)
            return HTTP.Response(400, JSON3.write(Dict(
                "error" => "Missing data field",
                "message" => "Request body must contain a 'data' field"
            )))
        end
        # Convert data to NamedTuple
        data = (; (k => v for (k, v) in pairs(body.data))...)

        # Merge default inference kwargs with request-specific ones
        request_kwargs = Dict{Symbol,Any}()

        # Add any inference kwargs from the request body that aren't in defaults
        for k in propertynames(body)
            if k != :data  # Skip the data field
                request_kwargs[k] = getproperty(body, k)
            end
        end

        # Override with default inference kwargs if not specified in request
        for (k, v) in inference_kwargs
            if !haskey(request_kwargs, k)
                request_kwargs[k] = v
            end
        end

        # Run inference
        try

            request_kwargs = NamedTuple{Tuple(Symbol.(keys(request_kwargs)))}(values(request_kwargs))
            result = deployable(; data=data, output=output_vars, request_kwargs...)

            return HTTP.Response(200, JSON3.write(result))
        catch e
            return HTTP.Response(400, JSON3.write(Dict(
                "error" => "Inference failed",
                "message" => sprint(showerror, e)
            )))
        end
    end

    add(handler, server, path, method=method)
end

"""
    add(handler::Function, server::RxInferModelServer, path::String; method::String="GET")

Add a new endpoint to the web server.

# Arguments
- `handler`: The function to handle the request
- `server`: The web server instance
- `path`: The endpoint path (e.g., "/hello")
- `method`: The HTTP method (default: "GET")
"""
function add(handler::Function, server::RxInferModelServer, path::String; method::String="GET")
    HTTP.register!(server.router, method, path, handler)
end

"""
    start(server::RxInferModelServer)

Start the web server on the specified port.
"""
function start(server::RxInferModelServer)
    if server.server === nothing
        server.server = HTTP.serve!(server.router, "0.0.0.0", server.port)
        println("Server started on port $(server.port)")
    else
        println("Server is already running")
    end
end

"""
    stop(server::RxInferModelServer)

Stop the web server.
"""
function stop(server::RxInferModelServer)
    if server.server !== nothing
        close(server.server)
        server.server = nothing
        println("Server stopped")
    end
end