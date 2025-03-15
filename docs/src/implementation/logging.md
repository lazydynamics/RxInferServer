# [Logging System](@id logging-system)

The RxInfer Server uses a logging system that divides logs by functional groups and stores them in separate files.

## Architecture

The logging functionality is encapsulated in the `Logging` module (`src/logging.jl`), which:

- Uses a `TeeLogger` to output logs to multiple destinations simultaneously
- Groups logs by their functional component
- Maintains separate log files for each tag/group (e.g., `Server.log`, `Authentification.log`)

## Usage

The `Logging.with_logger` function is the primary API:

```julia
Logging.with_logger() do
    @info "This message will be logged to both terminal and files"
end
```

### Log Groups

Log groups are automatically derived from the file basename. For example:
- Messages from `src/tags/Server.jl` belong to the `:Server` group
- Messages from `src/tags/Authentification.jl` belong to the `:Authentification` group

The system routes logs to the appropriate files based on these groups without requiring explicit group specification.

## Configuration

For logging configuration options, see [Logging Configuration](@ref logging-configuration) in the main configuration documentation.

## API Reference

```@docs
RxInferServer.Logging.with_logger
RxInferServer.Logging.filter_by_group
```

## Adding New OpenAPI Tags

When adding new tags to the OpenAPI schema:

1. Create a new file in the `src/tags/` directory (e.g., `NewTag.jl`)
2. Add a corresponding logger in the `Logging.with_logger` function:

```julia
# In src/logging.jl:
MiniLoggers.MiniLogger(; io = joinpath(RXINFER_SERVER_LOGS_LOCATION, "NewTag.log"), kwargs_logger...) |> filter_by_group(:NewTag)
```

This ensures logs from the new tag will be properly captured in a dedicated log file. 