module RxInferServer

# Core dependencies for API server, hot reloading, and preferences
using RxInfer
using HTTP, Sockets, JSON, RxInferServerOpenAPI
using Revise, Preferences, Dates, Pkg

include("database.jl")

# API configuration
const API_PATH_PREFIX = "/v1"
const PORT = parse(Int, get(ENV, "RXINFER_SERVER_PORT", "8000"))

include("middleware.jl")

function middleware_pre_validation(handler::F) where {F}
    return handler |> middleware_check_token |> middleware_cors
end

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

import Logging, MiniLoggers, LoggingExtras

function LoggerFilterByGroup(group)
    return function (logger)
        return LoggingExtras.EarlyFilteredLogger(logger) do log
            return log.group == group
        end
    end
end

# Logging configuration, logs are written to the terminal and to a series of files
const SERVER_LOGS_LOCATION = get(ENV, "RXINFER_SERVER_LOGS_LOCATION", ".server-logs")

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
    # Prepare logging folder if it doesn't exist
    if !isdir(SERVER_LOGS_LOCATION)
        mkpath(SERVER_LOGS_LOCATION)
    end

    # We create a TeeLogger that writes to the terminal and to a series of files
    format_logger = "{[{timestamp}] {level}:func}: {message} {{module}@{basename}:{line}:light_black}"
    kwargs_logger = (
        format   = format_logger,              # see above
        dtformat = dateformat"mm-dd HH:MM:SS", # do not print year
        errlevel = Logging.AboveMaxLevel,      # to include errors in the log file
        append   = true,                       # append to the log file, don't overwrite
        message_mode = :notransformations      # do not transform the message
    )
    server_logger = LoggingExtras.TeeLogger(
        # The terminal logger is a MiniLogger that formats the log message in a human-readable way
        MiniLoggers.MiniLogger(; kwargs_logger...),

        # The file loggers are EarlyFilteredLoggers that filter the log messages by group
        # and write them to a series of files in the SERVER_LOGS_LOCATION directory
        # - .log is the default log file with all messages
        # - *Name*.log is a file for each group of messages, clustered for each individual tag in the tags/ folder
        MiniLoggers.MiniLogger(; io = joinpath(SERVER_LOGS_LOCATION, ".log"), kwargs_logger...),
        MiniLoggers.MiniLogger(; io = joinpath(SERVER_LOGS_LOCATION, "Server.log"), kwargs_logger...) |> LoggerFilterByGroup(:Server),
        MiniLoggers.MiniLogger(; io = joinpath(SERVER_LOGS_LOCATION, "Authentification.log"), kwargs_logger...) |> LoggerFilterByGroup(:Authentification)
    )

    if show_banner
        println("""


                ██████╗ ██╗  ██╗██╗███╗   ██╗███████╗███████╗██████╗ 
                ██╔══██╗╚██╗██╔╝██║████╗  ██║██╔════╝██╔════╝██╔══██╗
                ██████╔╝ ╚███╔╝ ██║██╔██╗ ██║█████╗  █████╗  ██████╔╝
                ██╔══██╗ ██╔██╗ ██║██║╚██╗██║██╔══╝  ██╔══╝  ██╔══██╗
                ██║  ██║██╔╝ ██╗██║██║ ╚████║██║     ███████╗██║  ██║
                ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝╚═╝  ╚═╝
                
                Welcome to RxInfer Server! (version: $(pkgversion(RxInferServer)))
                
                API Documentation: https://api.rxinfer.com
                RxInfer Documentation: https://docs.rxinfer.com
    
                Logs are collected in `$SERVER_LOGS_LOCATION`
                
                Type 'q' or 'quit' and hit ENTER to quit the server
                $(isinteractive() ? "Alternatively use Ctrl-C to quit." : "(Running in non-interactive mode, Ctrl-C may not work properly)")

        """)
    end

    Logging.with_logger(server_logger) do

        # Initialize HTTP router for handling API endpoints
        router = HTTP.Router(cors404, cors405)
        server_running = Threads.Atomic{Bool}(true)

        # Create temp file to track server state and trigger file watchers
        server_pid_file = tempname()
        open(server_pid_file, "w") do f
            print(f, "server started at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
        end

        # Register all API endpoints defined in OpenAPI spec
        RxInferServerOpenAPI.register(router, @__MODULE__; path_prefix = API_PATH_PREFIX, pre_validation = middleware_pre_validation)

        # Conditionally start hot reloading based on preference
        hot_reload = if is_hot_reload_enabled()
            @info "Hot reload is enabled. Starting hot reload task..."
            Threads.@spawn begin
                while server_running[]
                    try
                        @info "Starting hot reload..."
                        # Watch for changes in server code and automatically update endpoints
                        Revise.entr([server_pid_file], [RxInferServerOpenAPI, @__MODULE__]; postpone = true) do
                            @info "Hot reloading server..."
                            if server_running[]
                                io = IOBuffer()
                                Logging.with_logger(Logging.SimpleLogger(io)) do
                                    RxInferServerOpenAPI.register(router, @__MODULE__; path_prefix = API_PATH_PREFIX, pre_validation = middleware_pre_validation)
                                end
                                if occursin("replacing existing registered route", String(take!(io)))
                                    @info "Successfully replaced existing registered route"
                                end
                            else
                                throw(InterruptException())
                            end
                        end
                    catch e
                        if server_running[]
                            @error "Hot reload task encountered an error: $e"
                        else
                            @info "Exiting hot reload task..."
                        end
                    end
                end
            end
        else
            @info "Hot reload is disabled. Use `RxInferServer.set_hot_reload(true)` and restart Julia to enable it."
            nothing
        end

        @info "Starting server on port $PORT"

        server = Sockets.listen(ip"0.0.0.0", PORT)

        # Start HTTP server on port `PORT`
        server_task = Threads.@spawn begin
            try
                Database.with_connection() do
                    HTTP.serve($router, ip"0.0.0.0", PORT, server = $server)
                end
            catch e
                @error "Server task encountered an error: $e"
            end
        end

        function shutdown()
            @info "Initiating graceful shutdown..."

            server_running[] = false

            close(server)

            # Update server state file to trigger file watcher
            # This would also trigger the hot reload task
            # Which checks the `server_running` variable and exits if it is false
            open(server_pid_file, "w") do f
                println(f, "server stopped at $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"));")
            end

            # Wait for hot reload task to complete if it was running
            if !isnothing(hot_reload)
                @info "Waiting for hot reload task to stop..."
                wait(hot_reload)
            end

            # Wait for the server task to complete
            wait(server_task)

            @info "Server shutdown complete."

            exit(0)
        end

        # If the server is not running in an interactive session, 
        # we need to register the shutdown function to be called when the program exits
        # see https://docs.julialang.org/en/v1/manual/faq/#catch-ctrl-c
        if !isinteractive()
            Base.atexit(shutdown)
        end

        # Running a loop to wait for the user to quit the server
        try
            while server_running[]
                yield()
                input = readline()
                if input == "q" || input == "quit"
                    throw(InterruptException())
                end
                @warn "Unknown command: $input. Use 'q' or 'quit' and hit ENTER to quit."
            end
        catch e
            if e isa InterruptException
                shutdown()
            else
                @error "Server encountered an error: $e"
            end
        end
    end
end

module OldImplementation
include("old_impl/model.jl")
include("old_impl/serve.jl")
end

end
