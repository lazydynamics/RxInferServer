module Logging

using Dates

import Logging as BaseLogging
import MiniLoggers, LoggingExtras

"""
The directory where server logs will be stored.
This can be configured using the `RXINFER_SERVER_LOGS_LOCATION` environment variable.
Defaults to ".server-logs" in the current working directory if not specified.
The server automatically creates this directory if it doesn't exist.

The logging system uses:
- Terminal output with formatted, human-readable logs
- File-based logging with separate files for different functional groups

```julia
# Set logs directory via environment variable
ENV["RXINFER_SERVER_LOGS_LOCATION"] = "/path/to/logs"
RxInferServer.serve()
```
"""
RXINFER_SERVER_LOGS_LOCATION() = get(ENV, "RXINFER_SERVER_LOGS_LOCATION", ".server-logs")

"""
Whether to enable debug logging.
This can be configured using the `RXINFER_SERVER_ENABLE_DEBUG_LOGGING` environment variable.
Defaults to `"false"` if not specified. Note that this is a string variable, not a boolean.
If enabled, writes to `debug.log` in the RXINFER_SERVER_LOGS_LOCATION directory.
Note that the debug logs are overwritten each time the server is restarted.

```julia
ENV["RXINFER_SERVER_ENABLE_DEBUG_LOGGING"] = "true"
RxInferServer.serve()
```
"""
RXINFER_SERVER_ENABLE_DEBUG_LOGGING() = get(ENV, "RXINFER_SERVER_ENABLE_DEBUG_LOGGING", "false")

"""
Returns `true` if debug logging is enabled, `false` otherwise.
"""
is_debug_logging_enabled() = RXINFER_SERVER_ENABLE_DEBUG_LOGGING() == "true"

"""
    filter_by_group(group)

Creates a logger filter function that only allows log messages with the specified group tag.
Used to separate logs into different files by their functionality/module.

# Arguments
- `group`: The symbol representing a log group (e.g., `:Server`, `:Authentification`)

# Returns
- A function that takes a logger and returns an EarlyFilteredLogger that filters by the specified group
"""
function filter_by_group(group)
    return function (logger)
        return LoggingExtras.EarlyFilteredLogger(logger) do log
            return log.group == group
        end
    end
end

"""
    filter_by_module(_module)

Creates a logger filter function that only allows log messages from the specified module.
Used to separate logs by their source module.

# Arguments
- `_module`: The module name to filter by (e.g., `"RxInferServer"`), must be a string

# Returns
- A function that takes a logger and returns an EarlyFilteredLogger that filters by the specified module
"""
function filter_by_module(_module)
    return function (logger)
        return LoggingExtras.EarlyFilteredLogger(logger) do log
            return string(log._module) == string(_module)
        end
    end
end

"""
    with_logger(f)

Sets up the logging system and executes the provided function with the configured logger.
Creates a TeeLogger that writes to:
1. Terminal with human-readable formatting
2. A main log file (.log) with all messages
3. Separate files for each functional group (Server.log, Authentification.log, etc.)
4. A debug log file (debug.log) if debug logging is enabled, see [`RxInferServer.Logging.RXINFER_SERVER_ENABLE_DEBUG_LOGGING`](@ref)
# Arguments
- `f`: The function to execute with the configured logger

# Examples
```julia
Logging.with_logger() do
    @info "This message will be logged to both terminal and files"
end
```

# Returns
- The return value of the provided function
"""
function with_logger(f::F) where {F}
    logs_location = RXINFER_SERVER_LOGS_LOCATION()

    # Ensure the logging directory exists
    if !isdir(logs_location)
        mkpath(logs_location)
    end

    # Configure logger format and options
    format_logger = "{[{timestamp}] {level}:func}: {message} {{module}@{basename}:{line}:light_black}"
    kwargs_logger = (
        format = format_logger,                # see above
        dtformat = dateformat"mm-dd HH:MM:SS", # do not print year
        errlevel = BaseLogging.AboveMaxLevel,  # to include errors in the log file
        append = true,                         # append to the log file, don't overwrite
        message_mode = :notransformations      # do not transform the message
    )

    # Create a TeeLogger that writes to terminal and files
    server_loggers = [
        # The terminal logger is a MiniLogger that formats the log message in a human-readable way
        MiniLoggers.MiniLogger(; kwargs_logger...),

        # The file loggers are EarlyFilteredLoggers that filter the log messages by group
        # and write them to a series of files in the `RXINFER_SERVER_LOGS_LOCATION` directory
        # - .log is the default log file with all messages
        # - *Name*.log is a file for each group of messages, clustered for each individual tag in the tags/ folder
        MiniLoggers.MiniLogger(; io = joinpath(logs_location, ".log"), kwargs_logger...),
        MiniLoggers.MiniLogger(; io = joinpath(logs_location, "Server.log"), kwargs_logger...) |> filter_by_group(:Server),
        MiniLoggers.MiniLogger(; io = joinpath(logs_location, "Authentification.log"), kwargs_logger...) |> filter_by_group(:Authentification),
        MiniLoggers.MiniLogger(; io = joinpath(logs_location, "Models.log"), kwargs_logger...) |> filter_by_group(:Models)
    ]

    # If debug logging is enabled, add a debug logger that writes to the terminal
    if is_debug_logging_enabled()
        # Do not append to the debug log file, overwrite it each time the server is restarted
        debug_kwargs = merge(kwargs_logger, (append = false, minlevel = BaseLogging.Debug))
        debug_logger = MiniLoggers.MiniLogger(; io = joinpath(logs_location, "debug.log"), debug_kwargs...) |> filter_by_module("RxInferServer")
        push!(server_loggers, debug_logger)
    end

    # `TeeLogger` does not accept an array of loggers, so we need to convert it to a tuple
    server_logger = LoggingExtras.TeeLogger(Tuple(server_loggers))

    # Execute the provided function with the configured logger
    BaseLogging.with_logger(server_logger) do
        if is_debug_logging_enabled()
            @info "Debug logging is enabled, extra logs will be written to `$(joinpath(logs_location, "debug.log"))`"
        end
        return f()
    end
end

"""
    with_simple_logger(f, io::IO)

Sets up the logging system and executes the provided function with the configured logger.
Creates a SimpleLogger that writes to the specified IO stream.

# Arguments
- `f`: The function to execute with the configured logger
- `io`: The IO stream to write the logs to

# Returns
- The return value of the provided function
"""
function with_simple_logger(f::F, io::IO) where {F}
    return BaseLogging.with_logger(BaseLogging.SimpleLogger(io)) do
        return f()
    end
end

end # module Logging 