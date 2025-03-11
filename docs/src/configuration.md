# Configuration 

This section describes the configuration options for the RxInferServer.jl package.
`RxInferServer` exposes two different configuration mechanisms:

- Environment variables: for setting runtime settings, which do not require recompilation of the project
- Preferences: for setting preferences persistent across Julia sessions, which are usually compile-time settings, changes in these settings require recompilation of the project

## Environment Variables

This section describes the environment variables that can be set to configure the server.

#### Port Configuration

The server port can be configured using the `RXINFER_SERVER_PORT` environment variable:

```julia
# Set port via environment variable
ENV["RXINFER_SERVER_PORT"] = 9000
RxInferServer.serve()
```

#### CORS Configuration

The server supports CORS configuration. The following environment variables can be set to configure the CORS settings:

- `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN`: The allowed origins for CORS requests.
- `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS`: The allowed methods for CORS requests.
- `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS`: The allowed headers for CORS requests.

#### Server Edition

The server edition can be configured using the `RXINFER_SERVER_EDITION` environment variable:

```julia
ENV["RXINFER_SERVER_EDITION"] = "CommunityEdition"
```

This setting has no real effect on the server functionality, and is only used to identify the server edition.

## Preferences 

This section describes the preferences that can be set to configure the server. These settings persist across Julia sessions and require a restart of the server to take effect. You could also manually modify the `LocalPreferences.toml` file to change these settings.

#### Hot Reloading

The server supports hot reloading, which automatically updates endpoints when code changes are detected. This feature is enabled by default but can be disabled:

```julia
# Check current setting
RxInferServer.is_hot_reload_enabled()  # Returns true by default

# Disable hot reloading
RxInferServer.set_hot_reload(false)

# Enable hot reloading
RxInferServer.set_hot_reload(true)
```

```@docs
RxInferServer.is_hot_reload_enabled
RxInferServer.set_hot_reload
```