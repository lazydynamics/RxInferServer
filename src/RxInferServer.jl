module RxInferServer

# Core dependencies for API server, hot reloading, and preferences
using RxInfer
using HTTP, Sockets, RxInferServerOpenAPI
using Revise, Preferences, Dates

include("tags/Server.jl")

# API configuration
const path_prefix = "/v1"
const HOT_RELOAD_PREF_KEY = "enable_hot_reload"
const PORT = parse(Int, get(ENV, "RXINFER_SERVER_PORT", "8000"))

"""
    set_hot_reload(enable::Bool)

Enable or disable hot reloading for the server.
This setting is stored in the package preferences and persists across Julia sessions.
"""
function set_hot_reload(enable::Bool)
    @set_preferences!(HOT_RELOAD_PREF_KEY => enable)
    @info "Hot reloading set to: $enable. This setting will take effect on server restart."
    return enable
end

"""
    is_hot_reload_enabled()

Check if hot reloading is enabled.
"""
function is_hot_reload_enabled()
    return @load_preference(HOT_RELOAD_PREF_KEY, true)
end

const CORS_ACCESS_CONTROL_ALLOW_ORIGIN = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN", "*")
const CORS_ACCESS_CONTROL_ALLOW_METHODS = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS", "GET, POST, PUT, DELETE, OPTIONS")
const CORS_ACCESS_CONTROL_ALLOW_HEADERS = get(ENV, "RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS", "Content-Type, Authorization")

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

function middleware_post_invoke(req::HTTP.Request, res::HTTP.Response)
    return res |> middleware_post_invoke_cors
end

"""
    serve() -> HTTP.Server

Start the RxInfer API server with the configured settings.

# Description
Initializes and starts an HTTP server that exposes RxInfer functionality through a REST API.
The server uses the OpenAPI specification defined in RxInferServerOpenAPI to register endpoints.

This is a blocking operation that runs until interrupted (e.g., with Ctrl+C).

# Features
- Configurable port via the `RXINFER_SERVER_PORT` environment variable (default: 8000)
- Hot reloading support that can be enabled/disabled via preferences
- Graceful shutdown with proper resource cleanup when interrupted

# Returns
- An `HTTP.Server` instance that is actively serving requests

# Examples
```julia
using RxInferServer

# Start the server with default settings (blocks until interrupted)
RxInferServer.serve()

# To run in a separate task if you need to continue using the REPL
@async RxInferServer.serve()
```

# See Also
- [`RxInferServer.set_hot_reload`](@ref): Enable or disable hot reloading
- [`RxInferServer.is_hot_reload_enabled`](@ref): Check if hot reloading is enabled
"""
function serve()
    # Initialize HTTP router for handling API endpoints
    router = HTTP.Router()
    server_running = Ref(true)

    # Create temp file to track server state and trigger file watchers
    server_pid_file = tempname()
    open(server_pid_file, "w") do f
        print(f, "server started at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
    end

    # Register all API endpoints defined in OpenAPI spec
    RxInferServerOpenAPI.register(
        router, @__MODULE__;
        path_prefix=path_prefix,
        post_invoke=middleware_post_invoke
    )

    # Conditionally start hot reloading based on preference
    hot_reload = if is_hot_reload_enabled()
        @info "Hot reload is enabled. Starting hot reload task..."
        Threads.@spawn begin
            run_hot_reload_loop = true
            while run_hot_reload_loop
                try
                    @info "Starting hot reload..."
                    # Watch for changes in server code and automatically update endpoints
                    Revise.entr([server_pid_file], [RxInferServerOpenAPI, @__MODULE__]; postpone=true) do
                        @info "Hot reloading server..."
                        if server_running[]
                            RxInferServerOpenAPI.register(
                                router, @__MODULE__;
                                path_prefix=path_prefix,
                                post_invoke=middleware_post_invoke
                            )
                        else
                            @info "Exiting hot reload task..."
                            throw(InterruptException())
                        end
                    end
                catch e
                    if e isa InterruptException
                        run_hot_reload_loop = false
                        @info "Hot reload task exited."
                    else
                        @error "Hot reload task encountered an error: $e"
                    end
                end
            end
        end
    else
        @info "Hot reload is disabled. Use RxInferServer.set_hot_reload(true) to enable it."
        nothing
    end

    # Define shutdown procedure to clean up resources
    function on_shutdown()
        @info "Shutting down server..."

        server_running[] = false

        # Update server state file to trigger file watcher
        # This would also trigger the hot reload task
        # Which checks the `server_running` variable and exits if it is false
        open(server_pid_file, "w") do f
            println(f, "server stopped at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
        end

        # Wait for hot reload task to complete if it was running
        if !isnothing(hot_reload)
            @info "Closing hot reload task..."
            wait(hot_reload)
        end
    end

    # Start HTTP server on port `PORT`
    server = HTTP.serve(router, ip"0.0.0.0", PORT, on_shutdown=on_shutdown)
    return server
end

end
