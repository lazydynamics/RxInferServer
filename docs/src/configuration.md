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

#### MongoDB Configuration

The MongoDB connection can be configured using the following environment variables:

- `RXINFER_MONGODB_URL`: Sets the MongoDB connection URL
- `RXINFER_MONGODB_DATABASE`: Sets the MongoDB database name (defaults to "rxinferserver")

```julia
# Set MongoDB connection URL via environment variable
ENV["RXINFER_MONGODB_URL"] = "mongodb://localhost:27017"
# Set MongoDB database name
ENV["RXINFER_MONGODB_DATABASE"] = "rxinferserver"
RxInferServer.serve()
```

The default connection URL for the Docker development environment is `mongodb://database:27017`, which connects to the MongoDB Atlas Local instance running in the Docker Compose environment. When deploying to production, you should set this to your actual MongoDB Atlas connection string or other MongoDB instance.

##### Using MongoDB Compass

If you're using [MongoDB Compass](https://www.mongodb.com/products/compass) to connect to and manage your MongoDB database during development:

1. Always connect to `localhost:27017` from your host machine (except when using the `RXINFER_MONGODB_URL` environment variable)
2. This is because Docker maps the container's port 27017 to your host's port 27017
3. No authentication is required for the development database by default

For production MongoDB Atlas connections in Compass, you would use the standard Atlas connection string format.

#### CORS Configuration

The server supports CORS configuration. The following environment variables can be set to configure the CORS settings:

- `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN`: The allowed origins for CORS requests.
- `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS`: The allowed methods for CORS requests.
- `RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS`: The allowed headers for CORS requests.

#### Authentication Configuration

The server implements standard Bearer token authentication using the HTTP `Authorization` header. All endpoints except `/token` require authentication by default.

Authentication for development can be configured through the `RXINFER_SERVER_DEV_TOKEN` environment variable:

- Default value: `dev-token` (allows authentication with this value during development)
- Special values:
  - `disabled`: Disables the development token, requiring proper production tokens for all authentication
  
```julia
# Use a specific development token
ENV["RXINFER_SERVER_DEV_TOKEN"] = "my-custom-token"

# Disable development token (production mode)
ENV["RXINFER_SERVER_DEV_TOKEN"] = "disabled"
```

When implementing client applications, you must include the token in the `Authorization` header with the `Bearer` prefix:

```
Authorization: Bearer your-token-here
```

For development and testing, you can use the configured development token (default is `dev-token`):

```
Authorization: Bearer dev-token
```

```@docs
RxInferServer.is_dev_token_enabled
RxInferServer.is_dev_token_disabled
RxInferServer.is_dev_token
```

!!! note
    In production environments, you should set `RXINFER_SERVER_DEV_TOKEN=disabled` and implement proper token validation logic.

#### Server Edition

The server edition can be configured using the `RXINFER_SERVER_EDITION` environment variable:

```julia
ENV["RXINFER_SERVER_EDITION"] = "CommunityEdition"
```

This setting is used to identify the server edition in the server information endpoint and has no functional impact on server behavior. The default value is "CommunityEdition".

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