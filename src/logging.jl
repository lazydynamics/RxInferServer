module Logging

import Base.Logging
import MiniLoggers, LoggingExtras
import Dates

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
const RXINFER_SERVER_LOGS_LOCATION = get(ENV, "RXINFER_SERVER_LOGS_LOCATION", ".server-logs")

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
    with_logger(f)

Sets up the logging system and executes the provided function with the configured logger.
Creates a TeeLogger that writes to:
1. Terminal with human-readable formatting
2. A main log file (.log) with all messages
3. Separate files for each functional group (Server.log, Authentification.log, etc.)

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
    # Ensure the logging directory exists
    if !isdir(RXINFER_SERVER_LOGS_LOCATION)
        mkpath(RXINFER_SERVER_LOGS_LOCATION)
    end

    # Configure logger format and options
    format_logger = "{[{timestamp}] {level}:func}: {message} {{module}@{basename}:{line}:light_black}"
    kwargs_logger = (
        format = format_logger,              # see above
        dtformat = dateformat"mm-dd HH:MM:SS", # do not print year
        errlevel = Logging.AboveMaxLevel,      # to include errors in the log file
        append = true,                       # append to the log file, don't overwrite
        message_mode = :notransformations      # do not transform the message
    )
    
    # Create a TeeLogger that writes to terminal and files
    server_logger = LoggingExtras.TeeLogger(
        # The terminal logger is a MiniLogger that formats the log message in a human-readable way
        MiniLoggers.MiniLogger(; kwargs_logger...),

        # The file loggers are EarlyFilteredLoggers that filter the log messages by group
        # and write them to a series of files in the RXINFER_SERVER_LOGS_LOCATION directory
        # - .log is the default log file with all messages
        # - *Name*.log is a file for each group of messages, clustered for each individual tag in the tags/ folder
        MiniLoggers.MiniLogger(; io = joinpath(RXINFER_SERVER_LOGS_LOCATION, ".log"), kwargs_logger...),
        MiniLoggers.MiniLogger(; io = joinpath(RXINFER_SERVER_LOGS_LOCATION, "Server.log"), kwargs_logger...) |> filter_by_group(:Server),
        MiniLoggers.MiniLogger(; io = joinpath(RXINFER_SERVER_LOGS_LOCATION, "Authentification.log"), kwargs_logger...) |> filter_by_group(:Authentification)
    )
    
    # Execute the provided function with the configured logger
    Base.Logging.with_logger(server_logger) do
        return f()
    end
end

end # module Logging 