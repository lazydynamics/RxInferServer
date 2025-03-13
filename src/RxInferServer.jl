module RxInferServer

# Core dependencies for API server, hot reloading, and preferences
using RxInfer
using HTTP, Sockets, JSON, RxInferServerOpenAPI
using Revise, Preferences, Dates

include("database.jl")

# API configuration
const API_PATH_PREFIX = "/v1"
const PORT = parse(Int, get(ENV, "RXINFER_SERVER_PORT", "8000"))

include("tags/Server.jl")
include("tags/Authentification.jl")

const HOT_RELOAD_PREF_KEY = "enable_hot_reload"

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

include("middleware.jl")

function middleware_pre_validation(handler::F) where {F}
    return handler |> middleware_check_token |> middleware_cors
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
    router = HTTP.Router(cors404, cors405)
    server_running = Ref(true)

    # Create temp file to track server state and trigger file watchers
    server_pid_file = tempname()
    open(server_pid_file, "w") do f
        print(f, "server started at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
    end

    # Register all API endpoints defined in OpenAPI spec
    RxInferServerOpenAPI.register(router, @__MODULE__; path_prefix = API_PATH_PREFIX, pre_validation = middleware_pre_validation)

    # Conditionally start hot reloading based on preference
    hot_reload = if is_hot_reload_enabled()
        @info "[$(Dates.format(now(), "HH:MM:SS"))] Hot reload is enabled. Starting hot reload task..."
        Threads.@spawn begin
            run_hot_reload_loop = true
            while run_hot_reload_loop
                try
                    @info "[$(Dates.format(now(), "HH:MM:SS"))] Starting hot reload..."
                    # Watch for changes in server code and automatically update endpoints
                    Revise.entr([server_pid_file], [RxInferServerOpenAPI, @__MODULE__]; postpone = true) do
                        @info "[$(Dates.format(now(), "HH:MM:SS"))] Hot reloading server..."
                        if server_running[]
                            RxInferServerOpenAPI.register(router, @__MODULE__; path_prefix = API_PATH_PREFIX, pre_validation = middleware_pre_validation)
                        else
                            @info "[$(Dates.format(now(), "HH:MM:SS"))] Exiting hot reload task..."
                            throw(InterruptException())
                        end
                    end
                catch e
                    if e isa InterruptException
                        run_hot_reload_loop = false
                        @info "[$(Dates.format(now(), "HH:MM:SS"))] Hot reload task exited."
                    else
                        @error "[$(Dates.format(now(), "HH:MM:SS"))] Hot reload task encountered an error: $e"
                    end
                end
            end
        end
    else
        @info "[$(Dates.format(now(), "HH:MM:SS"))] Hot reload is disabled. Use RxInferServer.set_hot_reload(true) to enable it."
        nothing
    end

    # Define shutdown procedure to clean up resources
    function on_shutdown()
        @info "[$(Dates.format(now(), "HH:MM:SS"))] Shutting down server..."

        server_running[] = false

        # Update server state file to trigger file watcher
        # This would also trigger the hot reload task
        # Which checks the `server_running` variable and exits if it is false
        open(server_pid_file, "w") do f
            println(f, "server stopped at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
        end

        # Wait for hot reload task to complete if it was running
        if !isnothing(hot_reload)
            @info "[$(Dates.format(now(), "HH:MM:SS"))] Closing hot reload task..."
            wait(hot_reload)
        end
    end

    # Start HTTP server on port `PORT`
    Database.with_connection() do
        HTTP.serve(router, ip"0.0.0.0", PORT, on_shutdown = on_shutdown)
    end
end

import RxInferClientOpenAPI

const Client = RxInferClientOpenAPI.OpenAPI.Clients.Client
const ServerApi = RxInferClientOpenAPI.ServerApi
const AuthenticationApi = RxInferClientOpenAPI.AuthenticationApi

module OldImplementation
include("old_impl/model.jl")
include("old_impl/serve.jl")
end

end
