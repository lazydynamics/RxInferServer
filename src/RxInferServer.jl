module RxInferServer

# Core dependencies for API server, hot reloading, and preferences
using RxInfer
using HTTP, Sockets, JSON, RxInferServerOpenAPI
using Revise, Preferences, Dates, Pkg

include("database.jl")
include("logging.jl")

# This is NOT a file with model definitions, but a file that functions to
# load models from the `RXINFER_SERVER_MODELS_LOCATION` directory
include("models/models.jl")

# API configuration, this is not configurable and baked into the current implementation
const API_PATH_PREFIX = "/v1"

"""
The port on which the RxInfer server will run. 
This can be configured using the `RXINFER_SERVER_PORT` environment variable.
Defaults to 8000 if not specified.

```julia
# Set port via environment variable
ENV["RXINFER_SERVER_PORT"] = 9000
RxInferServer.serve()
```
"""
RXINFER_SERVER_PORT() = parse(Int, get(ENV, "RXINFER_SERVER_PORT", "8000"))

include("middleware.jl")

function middleware_pre_validation(handler::F) where {F}
    return handler |> middleware_check_token |> middleware_cors
end

include("tags/Server.jl")
include("tags/Authentification.jl")
include("tags/Models.jl")

"""
The preference key used to store the hot reload setting.
Used with Preferences.jl to persist the hot reload setting across Julia sessions.
Do not use this value directly, use [`RxInferServer.set_hot_reload`](@ref) and [`RxInferServer.is_hot_reload_enabled`](@ref) instead.
"""
const HOT_RELOAD_PREF_KEY = "enable_hot_reload"

"""
    set_hot_reload(enable::Bool)

Enable or disable hot reloading for the server.
This setting is stored in the package preferences and persists across Julia sessions.

```julia
# Disable hot reloading
RxInferServer.set_hot_reload(false)

# Enable hot reloading
RxInferServer.set_hot_reload(true)
```

See also: [`RxInferServer.is_hot_reload_enabled`](@ref)
"""
function set_hot_reload(enable::Bool)
    @set_preferences!(HOT_RELOAD_PREF_KEY => enable)
    @info "Hot reloading set to: $enable. This setting will take effect on server restart."
    return enable
end

"""
    is_hot_reload_enabled()

Check if hot reloading is enabled.

```julia
# Check current setting
RxInferServer.is_hot_reload_enabled() 
```

See also: [`RxInferServer.set_hot_reload`](@ref)
"""
function is_hot_reload_enabled()
    return @load_preference(HOT_RELOAD_PREF_KEY, true)
end

"""
    serve(; kwargs...) -> HTTP.Server

Start the RxInfer API server with the configured settings.

# Description
Initializes and starts an HTTP server that exposes RxInfer functionality through a REST API.
The server uses the OpenAPI specification defined in RxInferServerOpenAPI to register endpoints.

This is a blocking operation that runs until interrupted (e.g., with Ctrl+C).

# Features
- Configurable port via the `RXINFER_SERVER_PORT` environment variable (default: 8000)
- Hot reloading support that can be enabled/disabled via preferences
- Graceful shutdown with proper resource cleanup when interrupted

# Keyword Arguments
- `show_banner::Bool = true`: Whether to print the welcome banner

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
function serve(; show_banner::Bool = true)
    if show_banner
        banner = """


                ██████╗ ██╗  ██╗██╗███╗   ██╗███████╗███████╗██████╗ 
                ██╔══██╗╚██╗██╔╝██║████╗  ██║██╔════╝██╔════╝██╔══██╗
                ██████╔╝ ╚███╔╝ ██║██╔██╗ ██║█████╗  █████╗  ██████╔╝
                ██╔══██╗ ██╔██╗ ██║██║╚██╗██║██╔══╝  ██╔══╝  ██╔══██╗
                ██║  ██║██╔╝ ██╗██║██║ ╚████║██║     ███████╗██║  ██║
                ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝╚═╝  ╚═╝
                
                Welcome to RxInfer Server! (version: $(pkgversion(RxInferServer)))
                
                API Documentation: https://api.rxinfer.com
                RxInfer Documentation: https://docs.rxinfer.com

                Logs are collected in `$(Logging.RXINFER_SERVER_LOGS_LOCATION())`
                $(Logging.is_debug_logging_enabled() ? "Debug level logs are collected in `$(Logging.RXINFER_SERVER_LOGS_LOCATION())/debug.log`" : "")
                
                Type 'q' or 'quit' and hit ENTER to quit the server
                $(isinteractive() ? "Alternatively use Ctrl-C to quit." : "(Running in non-interactive mode, Ctrl-C may not work properly)")

        """
        println(banner)
    end

    Logging.with_logger() do
        # Initialize HTTP router for handling API endpoints
        router = HTTP.Router(cors404, cors405)
        server_running = Threads.Atomic{Bool}(true)
        server_errored = Threads.Atomic{Bool}(false)
        server_instantiated = Base.Threads.Event()

        # Create temp file to track server state and trigger file watchers
        server_pid_file = tempname()
        open(server_pid_file, "w") do f
            print(f, "server started at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
        end

        Models.with_models() do
            # Register all API endpoints defined in OpenAPI spec
            RxInferServerOpenAPI.register(router, @__MODULE__; path_prefix = API_PATH_PREFIX, pre_validation = middleware_pre_validation)

            if !is_hot_reload_enabled()
                @info "Hot reload is disabled. Use `RxInferServer.set_hot_reload(true)` and restart Julia to enable it."
            else
                @info "Hot reload is enabled. Use `RxInferServer.set_hot_reload(false)` and restart Julia to disable it."
            end

            function hot_reload_task(f::F, name::String, files, modules; all = false, postpone = true) where {F}
                if !is_hot_reload_enabled()
                    return nothing
                end
                return Threads.@spawn begin
                    wait(server_instantiated)
                    # If the server is not running, do not start the hot reload task
                    # This might happen for example if the server failed to start, due to database connection issues
                    if server_running[]
                        @info "[HOT-RELOAD] Starting hot reload task for the $(name)..." _id = :hot_reload
                        while server_running[]
                            try
                                # Watch for changes in server code and automatically update endpoints
                                Revise.entr(files, modules; all = all, postpone = postpone) do
                                    if server_running[]
                                        f()
                                    else
                                        throw(InterruptException())
                                    end
                                end
                            catch e
                                if server_running[]
                                    @error "[HOT-RELOAD] Hot reload task for the $(name) encountered an error: $e" _id = :hot_reload
                                else
                                    @info "[HOT-RELOAD] Exiting hot reload task for the $(name)..." _id = :hot_reload
                                end
                            end
                        end
                    end
                end
            end

            # Conditionally start hot reloading of the source code based on preference
            # There is a separate task for hot reloading models defined below
            hot_reload_source_code = hot_reload_task("source code", [server_pid_file], [RxInferServerOpenAPI, @__MODULE__]; all = true) do
                io = IOBuffer()
                # The register function prints a lot of annoying warnings with routes being replaced
                # But this is the actual purpose of the hot reload task, so we suppress the warnings
                Logging.with_simple_logger(io) do
                    RxInferServerOpenAPI.register(router, @__MODULE__; path_prefix = API_PATH_PREFIX, pre_validation = middleware_pre_validation)
                end
                if occursin("replacing existing registered route", String(take!(io)))
                    @warn "[HOT-RELOAD] Successfully replaced existing registered route" _id = :hot_reload
                end
            end

            # We instantiate a separate task for hot reloading models
            # Because it is slower than the source code hot reloading and does not need to be done all the time
            # Collect server pid file and all files from model locations recursively
            hot_reload_models_locations = vcat(
                [server_pid_file],
                [joinpath(root, file) for location in Models.RXINFER_SERVER_MODELS_LOCATIONS() for (root, _, files) in walkdir(location) if isdir(location) for file in files]
            )
            hot_reload_models = hot_reload_task("models", hot_reload_models_locations, []; all = false) do
                Models.reload!(Models.get_models_dispatcher())
                @warn "[HOT-RELOAD] Models have been reloaded" _id = :hot_reload
            end

            server_ip = ip"0.0.0.0"
            server_port = RXINFER_SERVER_PORT()

            @info "Starting server on port `$(server_port)`"

            server = Sockets.listen(server_ip, server_port)

            # Start HTTP server on port `RXINFER_SERVER_PORT`
            server_task = Threads.@spawn begin
                try
                    Database.with_connection() do
                        # Start the HTTP server in non-blocking mode in order to trigger the `server_instantiated` event
                        s = HTTP.serve!($router, server_ip, server_port, server = $server)
                        # Notify the main thread that the server has been instantiated
                        notify(server_instantiated)
                        # Wait for the server to be closed from the main thread
                        wait(s)
                    end
                catch e
                    @error "Server task encountered an error: $e"
                    server_running[] = false
                    server_errored[] = true
                    notify(server_instantiated)
                end
            end

            function shutdown()
                # Atomic operation to set the server running flag to false
                # Returns the old value of the flag, e.g. true if the server was actually running
                if Base.Threads.atomic_xchg!(server_running, false)
                    @info "Initiating graceful shutdown..."

                    close(server)

                    # Update server state file to trigger file watcher
                    # This would also trigger the hot reload task
                    # Which checks the `server_running` variable and exits if it is false
                    open(server_pid_file, "w") do f
                        println(f, "server stopped at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
                    end

                    # Wait for hot reload task to complete if it was running
                    if !isnothing(hot_reload)
                        @info "Waiting for hot reload tasks to stop..."
                        wait(hot_reload_source_code)
                        wait(hot_reload_models)
                    end

                    # Wait for the server task to complete
                    wait(server_task)

                    @info "Server shutdown complete."
                end
            end

            # If the server is not running in an interactive session, 
            # we need to register the shutdown function to be called when the program exits
            # see https://docs.julialang.org/en/v1/manual/faq/#catch-ctrl-c
            if !isinteractive()
                Base.atexit(shutdown)
            end

            yield()

            # Running a loop to wait for the user to quit the server
            try
                wait(server_instantiated)
                while server_running[] && !istaskdone(server_task) && !istaskfailed(server_task)
                    input = readline()
                    if input == "q" || input == "quit"
                        throw(InterruptException())
                    end
                    @warn "Unknown command: $input. Use 'q' or 'quit' and hit ENTER to quit."
                end
            catch e
            end

            shutdown()

            if server_errored[]
                exit(1)
            end
        end
    end
end

module OldImplementation
include("old_impl/model.jl")
include("old_impl/serve.jl")
end

end
