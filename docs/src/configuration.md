# [Configuration](@id configuration)

This section describes the configuration options for the RxInferServer.jl package.
All configuration is done through environment variables, which can be set before starting the server.
These settings are runtime configurations that do not require recompilation of the project.

# [Environment Configuration with .env files](@id environment-configuration-with-env-files)

The server supports loading environment variables from `.env` files. The specific files loaded depend on the server environment setting:

```@docs
RxInferServer.RXINFER_SERVER_ENV
RxInferServer.RXINFER_SERVER_ENV_PWD
RxInferServer.RXINFER_SERVER_ENV_OVERRIDE
```

# [Port Configuration](@id port-configuration)

The server port can be configured using the following environment variable:

```@docs
RxInferServer.RXINFER_SERVER_PORT
```

# [Models Configuration](@id models-configuration)

The server supports models configuration. The following environment variables can be set to configure the models:

```@docs
RxInferServer.Models.RXINFER_SERVER_MODELS_LOCATIONS
```

# [Logging Configuration](@id logging-configuration)

The server implements a comprehensive logging system that writes logs both to the terminal and to files. Logs are organized by functional groups (e.g., Server, Authentication) and stored in separate files. The configurable options include:

```@docs
RxInferServer.Logging.RXINFER_SERVER_LOGS_LOCATION
RxInferServer.Logging.RXINFER_SERVER_ENABLE_DEBUG_LOGGING
RxInferServer.Logging.is_debug_logging_enabled
```

!!! note
    For production deployments, consider setting a persistent, absolute path for your log files to ensure they are preserved and easily accessible for monitoring and debugging.

!!! note
    `make serve` command runs the server with debug logging enabled.

# [MongoDB Configuration](@id mongodb-configuration)

The MongoDB connection can be configured using the following environment variables:

```@docs
RxInferServer.Database.RXINFER_SERVER_MONGODB_URL
RxInferServer.Database.RXINFER_SERVER_MONGODB_DATABASE
```

The default connection URL for the Docker development environment is `mongodb://database:27017`, which connects to the MongoDB Atlas Local instance running in the Docker Compose environment. When deploying to production, you should set this to your actual MongoDB Atlas connection string or other MongoDB instance.

## Using MongoDB Compass

If you're using [MongoDB Compass](https://www.mongodb.com/products/compass) to connect to and manage your MongoDB database during development:

1. Always connect to `localhost:27017` from your host machine (except when using the [`RxInferServer.Database.RXINFER_SERVER_MONGODB_URL`](@ref) environment variable)
2. This is because Docker maps the container's port 27017 to your host's port 27017
3. No authentication is required for the development database by default

For production MongoDB Atlas connections in Compass, you would use the standard Atlas connection string format.

# [CORS Configuration](@id cors-configuration)

The server supports CORS configuration. The following environment variables can be set to configure the CORS settings:

```@docs
RxInferServer.RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_ORIGIN
RxInferServer.RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_METHODS
RxInferServer.RXINFER_SERVER_CORS_ACCESS_CONTROL_ALLOW_HEADERS
```

# [Authentication Configuration](@id authentication-configuration)

The server implements standard Bearer token authentication using the HTTP `Authorization` header. Most of the endpoints except for `/generate-token` and `/ping` require authentication by default.

Authentication for development can be configured through the environment variable:

```@docs
RxInferServer.RXINFER_SERVER_DEV_TOKEN
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

# [Server Edition](@id server-edition-configuration)

The server edition can be configured using the following environment variable:

```@docs
RxInferServer.RXINFER_SERVER_EDITION
```

# [Other Configuration](@id other-configuration)

```@docs
RxInferServer.RXINFER_SERVER_SHOW_BANNER
RxInferServer.RXINFER_SERVER_LISTEN_KEYBOARD
```


# [Hot Reloading](@id hot-reloading-configuration)

The server supports hot reloading, which automatically updates endpoints when code changes are detected. 
This feature is controlled by the following environment variable:

```@docs
RxInferServer.RXINFER_SERVER_ENABLE_HOT_RELOAD
RxInferServer.is_hot_reload_enabled
```

Hot reloading consists of two separate mechanisms:
- **Source Code Hot-Reloading**: Updates API endpoints and server code when changes are detected
- **Models Hot-Reloading**: Refreshes models when their files change

Both mechanisms monitor files for changes using `Revise.jl` and automatically apply updates when detected. Console logs with the `[HOT-RELOAD]` prefix indicate reloading activity.

!!! note
    Hot reloading requires `Revise.jl` to be loaded in the current Julia session. If `Revise.jl` is not loaded, hot reloading will be disabled even if enabled through the environment variable.

!!! warning
    Hot reloading should be disabled in production environments as it can impact performance and may cause unexpected behavior.