module RxInferServer

# Core dependencies for API server

include("openapi/server/src/RxInferServerOpenAPI.jl")
include("openapi/client/src/RxInferClientOpenAPI.jl")

using .RxInferServerOpenAPI
using .RxInferClientOpenAPI

using RxInfer
using HTTP, Sockets, JSON
using Dates, Pkg, Serialization, ScopedValues

include("macro.jl")
include("dotenv.jl")
include("components/database.jl")
include("components/logging.jl")

# RxInferServer uses its own serialization implementation, 
# which is different from the default one provided by JSON.jl
include("components/serialization/serialization.jl")

# This is NOT a file with model definitions, but a file that functions to
# load models from the `RXINFER_SERVER_MODELS_LOCATION` directory
include("components/models/models.jl")

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
    return handler |> middleware_check_token |> middleware_cors_options
end

function middleware_post_invoke(req::HTTP.Request, res)
    return res |> middleware_post_invoke_cors
end

include("tags/Server.jl")
include("tags/Authentification.jl")
include("tags/Models.jl")

"""
    ServerState

A structure that keeps track of the server state, including whether it is running or has errored.
Used internally to check server status and manage server lifecycle events.

# Fields
- `is_running::Threads.Atomic{Bool}`: Atomic boolean indicating if server is currently running
- `is_errored::Threads.Atomic{Bool}`: Atomic boolean indicating if server has encountered an error
- `event_instantiated::Base.Threads.Event`: Event triggered when server is instantiated
- `pid_file::String`: File path used to trigger the hot reload task
- `router::HTTP.Router`: The HTTP router handling server requests
- `handler::H`: The handler for the routes, defaults to `RxInferServer.RoutesHandler()`
- `ip::Sockets.IPv4`: IP address the server binds to
- `port::Int`: Port number the server listens on
"""
Base.@kwdef struct ServerState{R, H}
    is_running::Threads.Atomic{Bool} = Threads.Atomic{Bool}(false)
    is_errored::Threads.Atomic{Bool} = Threads.Atomic{Bool}(false)
    event_instantiated::Base.Threads.Event = Base.Threads.Event()
    pid_file::String = tempname() # this is a file that is used to trigger the hot reload task

    router::R = HTTP.Router(cors404, cors405)
    handler::H = RoutesHandler()
    ip::Sockets.IPv4 = ip"0.0.0.0"
    port::Int = RXINFER_SERVER_PORT()
end

"""
    pid_server_event(server::ServerState, event::String)

Logs an event to the server's PID file.
This is used, for example, to trigger the hot reload task when the server is instantiated or shuts down.
"""
function pid_server_event(server::ServerState, event::String)
    open(server.pid_file, "a") do f
        println(f, "$event at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
    end
end

"""
    is_server_running(server::ServerState) -> Bool

Check if the server is currently running.

See also: [`RxInferServer.set_server_running`](@ref)
"""
function is_server_running(server::ServerState)
    return server.is_running[]
end

"""
    set_server_running(server::ServerState, running::Bool)

Set the server running flag to the given value.

See also: [`RxInferServer.is_server_running`](@ref)
"""
function set_server_running(server::ServerState, running::Bool)
    server.is_running[] = running
end

"""
    is_server_errored(server::ServerState) -> Bool

Check if the server has encountered an error.

See also: [`RxInferServer.set_server_errored`](@ref)
"""
function is_server_errored(server::ServerState)
    return server.is_errored[]
end

"""
    set_server_errored(server::ServerState, errored::Bool)

Set the server errored flag to the given value.

See also: [`RxInferServer.is_server_errored`](@ref)
"""
function set_server_errored(server::ServerState, errored::Bool)
    server.is_errored[] = errored
end

"""
    notify_instantiated(server::ServerState)

Notify threads which are waiting for the server to be instantiated.

See also: [`RxInferServer.wait_instantiated`](@ref)
"""
function notify_instantiated(server::ServerState)
    notify(server.event_instantiated)
end

"""
    wait_instantiated(server::ServerState)

Wait for the server to be instantiated.

See also: [`RxInferServer.notify_instantiated`](@ref)
"""
function wait_instantiated(server::ServerState)
    return wait(server.event_instantiated)
end

# Hot reloading functionality 
# Available only when Revise.jl is loaded in the current Julia session
include("hotreload.jl")

"""
Whether to show the welcome banner.
This can be configured using the `RXINFER_SERVER_SHOW_BANNER` environment variable.
Defaults to `"true"` if not specified.

```julia
ENV["RXINFER_SERVER_SHOW_BANNER"] = "false"
RxInferServer.serve()
```
"""
RXINFER_SERVER_SHOW_BANNER() = get(ENV, "RXINFER_SERVER_SHOW_BANNER", "true") == "true"

"""
Whether to listen for keyboard input to quit the server.
This can be configured using the `RXINFER_SERVER_LISTEN_KEYBOARD` environment variable.
Defaults to `"true"` if not specified. Defaults to `"false"` if "CI" environment variable is set to "true".

```julia
ENV["RXINFER_SERVER_LISTEN_KEYBOARD"] = "false"
RxInferServer.serve()
```
"""
RXINFER_SERVER_LISTEN_KEYBOARD() =
    get(ENV, "RXINFER_SERVER_LISTEN_KEYBOARD", "true") == "true" && get(ENV, "CI", nothing) != "true"

"""
    serve() -> HTTP.Server

Start the RxInfer API server with the configured settings.
Official documentation is available at https://server.rxinfer.com/

# Description
Initializes and starts an HTTP server that exposes RxInfer functionality through a REST API.
The server uses the OpenAPI specification defined in `RxInferServerOpenAPI` module to register endpoints.

# Features
- Configurable port via the `RXINFER_SERVER_PORT` environment variable (default: 8000)
- Graceful shutdown with proper resource cleanup when interrupted
- Loads the .env files based on the `RXINFER_SERVER_ENV` environment variable
- When `Revise.jl` is loaded in the current Julia session, and the `RXINFER_SERVER_ENABLE_HOT_RELOAD` environment variable is set to `"true"`, 
  the server will hot reload the source code and models when the source code changes.

This is a blocking operation that runs until interrupted (e.g., with Ctrl+C).
To gracefully shut down the server, type the `q` or `quit` and press ENTER in the REPL.
Note that `Ctrl+C` cannot be catched reliably when running in a non-interactive session.

# Examples
```julia
using RxInferServer

# Start the server with default settings (blocks until interrupted)
RxInferServer.serve()
```

# See Also
- [`RxInferServer.RXINFER_SERVER_ENV`](@ref): The environment on which the RxInfer server will run, determines which .env files are loaded
- [`RxInferServer.RXINFER_SERVER_PORT`](@ref): The port on which the RxInfer server will run
- [`RxInferServer.RXINFER_SERVER_ENABLE_HOT_RELOAD`](@ref): Check if hot reloading is enabled
- [`RxInferServer.RXINFER_SERVER_SHOW_BANNER`](@ref): Whether to show the welcome banner
- [`RxInferServer.RXINFER_SERVER_LISTEN_KEYBOARD`](@ref): Whether to listen for keyboard input to quit the server
"""
function serve()
    # Load the .env files
    dotenv_loaded = load_dotenv()

    # Initialize server state
    server = ServerState()

    if RXINFER_SERVER_SHOW_BANNER()
        banner = """


                ██████╗ ██╗  ██╗██╗███╗   ██╗███████╗███████╗██████╗ 
                ██╔══██╗╚██╗██╔╝██║████╗  ██║██╔════╝██╔════╝██╔══██╗
                ██████╔╝ ╚███╔╝ ██║██╔██╗ ██║█████╗  █████╗  ██████╔╝
                ██╔══██╗ ██╔██╗ ██║██║╚██╗██║██╔══╝  ██╔══╝  ██╔══██╗
                ██║  ██║██╔╝ ██╗██║██║ ╚████║██║     ███████╗██║  ██║
                ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝╚═╝  ╚═╝
                
                Welcome to RxInfer Server! (version: $(pkgversion(RxInferServer)))
                Listening on $(server.ip):$(server.port)
                
                • Documentation
                  API: https://server.rxinfer.com
                  RxInfer: https://docs.rxinfer.com

                • Environment: $(join(dotenv_loaded, ", "))
                  $(RXINFER_SERVER_ENABLE_DEV_TOKEN() ? "Development token is enabled (! do not use in production !)" : "Development token is disabled")

                • Logs are collected in `$(Logging.RXINFER_SERVER_LOGS_LOCATION())` directory
                  $(Logging.RXINFER_SERVER_ENABLE_DEBUG_LOGGING() ? "Debug logging is enabled and collected in `$(Logging.RXINFER_SERVER_LOGS_LOCATION())/debug.log`" : "Debug logging is disabled")

                • $(Models.loaded_models_banner_hint())
                  
                • $(hot_reloading_banner_hint())
                  
                $(RXINFER_SERVER_LISTEN_KEYBOARD() ? "Type 'q' or 'quit' and hit ENTER to quit the server" : "Server is not listening for keyboard input")
                $(isinteractive() ? "Alternatively use Ctrl-C to quit." : "(Running in non-interactive mode, Ctrl-C may not work properly)")

        """
        println(banner)
    end

    Logging.with_logger() do

        # Log the server start event in the server pid file
        # Note that this is not a log file, but a file to trigger file watchers
        pid_server_event(server, "server is starting")

        Models.with_models() do
            # Register all API endpoints defined in OpenAPI spec
            RxInferServerOpenAPI.register(
                server.router,
                server.handler;
                path_prefix = API_PATH_PREFIX,
                pre_validation = middleware_pre_validation,
                post_invoke = middleware_post_invoke
            )

            socket = Sockets.listen(server.ip, server.port)

            # Start HTTP server on port `RXINFER_SERVER_PORT`
            server_task = Threads.@spawn begin
                try
                    Database.with_connection(verbose = true) do
                        # Start the HTTP server in non-blocking mode in order to trigger the `server_instantiated` event
                        s = HTTP.serve!(server.router, server.ip, server.port, server = socket)
                        # Flip the server running flag to true
                        set_server_running(server, true)
                        # Notify the main thread that the server has been instantiated
                        notify_instantiated(server)
                        # Wait for the server to be closed from the main thread
                        wait(s)
                    end
                catch e
                    @error "Server task encountered an error" exception = (e, catch_backtrace())
                    set_server_running(server, false)
                    set_server_errored(server, true)
                    notify_instantiated(server)
                end
            end

            # Hot reloading of the source code, see `hotreload.jl` for more details
            # There is a separate task for hot reloading models defined below
            hot_reload_source_code = hot_reload_task_source_code(server)

            # We instantiate a separate task for hot reloading models
            # Because it is slower than the source code hot reloading and does not need to be done all the time
            hot_reload_models = hot_reload_task_models(server)

            function shutdown()
                # Atomic operation to set the server running flag to false
                # Returns the old value of the flag, e.g. true if the server was actually running
                if Base.Threads.atomic_xchg!(server.is_running, false)
                    @info "Initiating graceful shutdown..."

                    close(socket)

                    # Update server state file to trigger file watcher for hot reloading task 
                    # We do it again though before waiting for each hot reload task to complete
                    pid_server_event(server, "server is shutting down")

                    # Wait for hot reload task to complete if it was running
                    if is_hot_reload_enabled()
                        pid_server_event(server, "attempting to stop hot reload tasks")

                        if !isnothing(hot_reload_source_code)
                            pid_server_event(server, "stopping hot reload for source code")
                            wait(hot_reload_source_code)
                        end

                        if !isnothing(hot_reload_models)
                            pid_server_event(server, "stopping hot reload for models")
                            wait(hot_reload_models)
                        end
                    end

                    # Wait for the server task to complete
                    wait(server_task)
                    pid_server_event(server, "server has been stopped")

                    unload_dotenv(dotenv_loaded)

                    @info "Server shutdown complete."
                end
            end

            # If the server is not running in an interactive session, 
            # we need to register the shutdown function to be called when the program exits
            # see https://docs.julialang.org/en/v1/manual/faq/#catch-ctrl-c
            if !isinteractive()
                Base.atexit() do
                    shutdown()
                    if is_server_errored(server)
                        exit(1)
                    else
                        exit(0)
                    end
                end
            end

            # Yield to child tasks to allow them to start
            yield()

            # Running a loop to wait for the user to quit the server
            try
                wait_instantiated(server)
                while is_server_running(server) && !istaskdone(server_task) && !istaskfailed(server_task)
                    if RXINFER_SERVER_LISTEN_KEYBOARD()
                        input = readline()
                        if input == "q" || input == "quit"
                            throw(InterruptException())
                        end
                        @warn "Unknown command: $input. Use 'q' or 'quit' and hit ENTER to quit."
                    else
                        @info "Server is not listening for keyboard input."
                        wait(server_task)
                    end
                end
            catch e
            end

            shutdown()

            if is_server_errored(server)
                error("Server task encountered an error")
            end
        end
    end
end

end
