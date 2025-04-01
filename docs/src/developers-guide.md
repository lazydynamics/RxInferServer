# [Developers guide](@id developers-guide)

This section describes the development process for the RxInferServer.jl project and how to setup the development environment.

## OpenAPI Specification and Code Generation

This repository includes an OpenAPI specification for the RxInferServer.jl API and tools to generate Julia server and client code from it.

## Prerequisites

- Docker and Docker Compose installed on your system
- Visual Studio Code (or your preferred code editor) for editing the OpenAPI specification

## Development environment with Docker

To start the development environment with Docker, from the root directory of the repository, run:

```bash
docker compose up -d --build --wait --wait-timeout 240
```

Or use the Makefile convenience command:

```bash
make docker-start
```

!!! note
    The very first startup will be slower as all Docker images are being pulled and volumes are being created. Subsequent startups will be faster.

To stop the Docker environment:

```bash
make docker-stop
```

Or alternatively, use VSCode extension "Docker" to start the containers. The VSCode extension also allows to check the logs and attach to the running containers. Read more about docker here: [Docker](https://docs.docker.com/get-started/).

The `docker-compose.yaml` currently has the following services:

- Swagger UI: a web interface for visualizing and testing the OpenAPI specification, the UI is available at `http://localhost:8080` and allows to test the API endpoints, the endpoints can also be tested in VSCode by opening `spec.yaml` directly and clicking on the "Try it" button
- MongoDB Atlas Local: a local MongoDB instance running on `localhost:27017` that mimics MongoDB Atlas functionality for development and testing purposes

## Starting the RxInferServer

Unlike the Docker services, RxInferServer now needs to be started manually. To start the server, run:

```bash
make serve
```

This command is a wrapper around:

```bash
julia --project -e 'using RxInferServer; serve()'
```

This will start the server on `localhost:8000` with hot-reloading enabled by default. Use the `LocalPreferences.toml` file to configure the server settings.

!!! note
    The very first startup will be slower as all Julia packages are being installed and precompiled. Subsequent startups will be faster as the system image is already built unless there is a significant change to the dependencies of the project or its source code in which case Julia will recompile the project again.

You can verify the server is running by accessing the health check endpoint:

```bash
curl -f localhost:8000/v1/ping
```

If the server is running correctly, this should return a successful response.

!!! note
    Server supports hot-reloading, which automatically updates endpoints when code changes are detected. This feature is enabled by default but can be disabled using preferences. See [Hot Reloading](@ref hot-reloading-configuration) for more details.

## Hot-Reloading

RxInferServer includes built-in hot-reloading that automatically applies code changes without requiring server restarts.

### Overview

The server uses two separate hot-reloading mechanisms:
- **Source Code Hot-Reloading**: Updates API endpoints and server code
- **Models Hot-Reloading**: Refreshes models when their files change

Both mechanisms monitor files for changes using `Revise.jl` and automatically apply updates when detected. Console logs with the `[HOT-RELOAD]` prefix indicate reloading activity.

### Controlling Hot-Reloading

Hot reloading can be controlled through the `RXINFER_SERVER_ENABLE_HOT_RELOAD` environment variable:

```bash
# Enable hot reloading (default is "false")
export RXINFER_SERVER_ENABLE_HOT_RELOAD="true"

# Start the server with hot reloading enabled
make serve
```

!!! note
    Hot reloading requires `Revise.jl` to be loaded in the current Julia session. If `Revise.jl` is not loaded, hot reloading will be disabled even if enabled through the environment variable.

### Best Practices and Troubleshooting

- Hot-reloading works best for typical code changes but complex structural changes may require server restart
- Disable hot-reloading in production environments by setting `RXINFER_SERVER_ENABLE_HOT_RELOAD="false"`
- If issues occur, check logs for `[HOT-RELOAD]` errors and verify files are in monitored directories
- When hot reloading is enabled but not working, ensure `Revise.jl` is loaded in your Julia session

See [Hot Reloading](@ref hot-reloading-configuration) for more details.

## Development Workflow with Makefile

The project includes a Makefile with various commands to streamline common development tasks. Here are some of the most useful commands:

```bash
# Start the Docker environment (Swagger UI and MongoDB)
make docker-start

# Stop the Docker environment
make docker-stop

# Start the RxInferServer, with debug logs enabled
make serve

# Run the test suite
make test

# Install dependencies
make deps

# Build documentation
make docs

# Generate OpenAPI client code
make generate-client

# Generate OpenAPI server code
make generate-server

# Generate both client and server code
make generate-all

# Format Julia code
make format

# Check code formatting without modifying files
make check-format
```

For a full list of available commands, run:

```bash
make help
```

## MongoDB in Development

The development environment includes a MongoDB Atlas Local instance that's accessible to the RxInferServer service. The connection is pre-configured and available through the environment variable `RXINFER_MONGODB_URL`.

### Connecting with MongoDB Compass

[MongoDB Compass](https://www.mongodb.com/products/compass) is a GUI for MongoDB that allows you to explore and manipulate your data visually. To connect to the development MongoDB instance:

1. Download and install [MongoDB Compass](https://www.mongodb.com/try/download/compass)
2. Open MongoDB Compass
3. Use the following connection string to connect to the local MongoDB instance:
   ```
   mongodb://localhost:27017
   ```
4. Click "Connect"

Note that when connecting from your host machine (outside the Docker network), you'll always use `localhost:27017` as the address (except when using the `RXINFER_MONGODB_URL` environment variable). This is because the Docker port mapping makes the database accessible at this address on your host machine.

When running in the Docker development environment, the connection URL will automatically point to the MongoDB container (`mongodb://database:27017`).

## Editing the OpenAPI Specification

Edit the `openapi/spec.yaml` file directly in VSCode or your preferred code editor. The OpenAPI specification uses the YAML format and follows the [OpenAPI 3](https://swagger.io/specification/) standard.

Some useful VS Code extensions for working with OpenAPI specifications include:
- "OpenAPI (Swagger) Editor" by 42Crunch
- "YAML" by Red Hat
- "Docker" by Microsoft

### Accessing Swagger UI

Open your browser and navigate to: http://localhost:8080

The Swagger UI will automatically load the `openapi/spec.yaml` file, allowing you to visualize and test your API without leaving your browser. Alternatively, you can test the API endpoints in VSCode by opening `spec.yaml` directly and clicking on the "Try it" button.

## Testing Authenticated Endpoints

The API uses standard Bearer token authentication with the `Authorization` header. Here's how to test authenticated endpoints:

1. **Get a token**:
   - Navigate to the `/generate-token` endpoint
   - Click "Try it out" followed by "Execute"
   - Copy the token from the response
   - **For development**: You can use the predefined dev token (`dev-token`) configured in the environment variable `RXINFER_SERVER_DEV_TOKEN`

2. **Set up authentication**:
   - Click the "Authorize" button (padlock icon) at the top of Swagger UI
   - Enter your token in the value field (without "Bearer" prefix)
   - For local development, you can enter `dev-token`
   - Click "Authorize" and "Close"
   - The client will send requests with `Authorization: Bearer your-token-here`

3. **Test protected endpoints**:
   - All subsequent requests will include the authorization header
   - The token remains active until you log out or close the browser
   - By default, all endpoints except `/generate-token` and `/ping` require authentication

See [Configuration](@ref configuration) for more details on setting up authentication for development and production.

## Generating Code from OpenAPI Specification

You can generate both server and client code from the OpenAPI specification using the provided scripts and Makefile commands.

### Generating Code with Makefile

The project includes several convenient Makefile commands for code generation:

```bash
# Generate only the client code
make generate-client

# Generate only the server code
make generate-server

# Generate both client and server code in one go
make generate-all
```

These commands use the underlying combined script to perform the code generation with appropriate settings.

### Using the Generation Script Directly

You can also run the generation script directly with various options:

```bash
# Generate both client and server code (default)
./openapi/generate.sh all

# Generate only client code
./openapi/generate.sh client

# Generate only server code
./openapi/generate.sh server

# Generate to a custom output directory
OPENAPI_OUTPUT_DIR="/path/to/output" ./openapi/generate.sh all
```

The script checks if Docker is running, then uses the OpenAPI Generator Docker image to generate Julia code based on the OpenAPI specification.

### Customizing Output Location

By default, generated code is placed in the `openapi/client` and `openapi/server` directories. You can customize this by setting the `OPENAPI_OUTPUT_DIR` environment variable:

```bash
# Example: Generate code to a different directory
OPENAPI_OUTPUT_DIR="/path/to/custom/directory" ./openapi/generate.sh all
```

The script will create `client` and `server` subdirectories under the specified path.

!!! note
    After the re-generation of the server code, the initial startup time will be longer due to initial compilation of the generated code.

## Working with the Generated Code

### Server Code

The generated server code will be placed in the `openapi/server` directory as a separate Julia module and should never be modified directly. The `RxInferServer.jl` package will automatically load the generated code when the package is loaded. 

The generated code does not contain the actual implementation of the endpoints. The actual implementation is located in the `src/tags` directory for each tag specified in the OpenAPI specification. You can also manually open the `openapi/server/src/RxInferServerOpenAPI.jl` file to view which endpoints must be implemented. An example generated output might look like this:

```julia 
@doc raw"""
Encapsulates generated server code for RxInferServerOpenAPI

The following server methods must be implemented:

- **get_server_info**
    - *invocation:* GET /info
    - *signature:* get_server_info(req::HTTP.Request;) -> ServerInfo
"""
module RxInferServerOpenAPI

# ... a lot of auto generated code ...

end
```

This tells you that you need to implement the `get_server_info` function that must return a `ServerInfo` object as defined in the `openapi/spec.yaml` file.
You however, can also return other types of objects, for example `ErrorResponse` or `UnauthorizedResponse`. Those will be converted to the appropriate HTTP response codes by the server.

### Implementing API Endpoints

To implement a new API endpoint, you'll need to create a handler function that processes HTTP requests and returns appropriate responses. Each endpoint function should match the signature defined in the OpenAPI specification. You'll need to implement these functions with your business logic. Endpoints typically involve parsing request parameters, performing operations (like database queries), and formatting responses according to the API specification. For authenticated endpoints, you can use [`RxInferServer.current_token()`](@ref) and [`RxInferServer.current_roles()`](@ref) to access authentication information. 

#### Using the `@expect` macro

The `@expect` macro is a helper macro that allows you to handle errors and return a default value from a function when an unexpected value is encountered.

```@docs
RxInferServer.@expect
```

### Client Code

The generated client code will be placed in the `openapi/client` directory as a separate Julia module. This client code can be used to interact with the RxInfer API from Julia applications. The client provides Julia functions that correspond to each API endpoint defined in the OpenAPI specification.

## Customizing the OpenAPI Specification

Edit the `openapi/spec.yaml` file directly in your code editor to customize your API specification. 

!!! warning "Important"
    After making ANY changes to the OpenAPI specification, you MUST regenerate both the server and client code by running the generation scripts again or using the Makefile command `make generate-all`.

See [Generating Code from OpenAPI Specification](#generating-code-from-openapi-specification) for more details.

Failing to regenerate the code after changes to the OpenAPI specification will result in inconsistencies between your API specification and the actual server implementation. The code is not being re-generated automatically for two primary reasons:
- It might be somewhat slow for a lot of endpoints
- It most likely will cause `Revise` errors with redefined structures 

### Additional Resources

- [OpenAPI Specification](https://swagger.io/specification/)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Julia Server Template](https://openapi-generator.tech/docs/generators/julia-server)
- [Julia Client Template](https://openapi-generator.tech/docs/generators/julia)

## Working with Authorization in Endpoints

Most endpoints in RxInferServer require authentication. The middleware automatically handles token validation, but your endpoint implementation often needs to access the current user's token or roles for authorization decisions.

```@docs
RxInferServer.is_authorized
RxInferServer.current_token
RxInferServer.current_roles
```

### Using `current_token()` and `current_roles()`

RxInferServer provides two helper functions for accessing the authenticated user's information:

- `current_token()`: Returns the authenticated user's token string
- `current_roles()`: Returns a vector of role strings assigned to the current user

Here's how to implement an endpoint that requires authorization:

```julia
function get_protected_resource(req::HTTP.Request)::HTTP.Response
    # The middleware has already verified that the request is authenticated
    
    # If you need the token for any reason (e.g., logging, user-specific resources)
    token = current_token()
    
    # If you need to check roles for authorization
    roles = current_roles()
    
    # Example: Filter resources based on user roles
    if "admin" in roles
        # Return admin-level resources
    else
        # Return regular user resources
    end
    
    return HTTP.Response(200, your_response_data)
end
```

### Example: Role-Based Resource Filtering

Here's a real example from the `get_models` endpoint that filters models based on user roles:

```julia
function get_models(req::HTTP.Request)::HTTP.Response
    # Get models from storage
    models = Models.get_models()

    # Get current user's roles
    roles = current_roles()

    # Filter models by checking if any of the model's roles
    # match any of the user's roles
    filtered_models = filter(models) do model
        return any(r -> r in roles, model.roles)
    end

    # rest of the implementation...
end
```

!!! note
    These functions will throw an error if called in a non-authenticated context. Always ensure they are only called in endpoints protected by the authentication middleware.

## API Reference 

### Server Lifecycle Management

RxInferServer uses a `ServerState` struct to manage the server's lifecycle and state. This is created automatically when the server is instantiated with the [`RxInferServer.serve`](@ref) function. This structure is used internally to keep track of the server's status and manage the server's lifecycle. The most notable use case is for the hot-reloading mechanism to check if the server is running and/or has encountered an error. The hot-reloading tasks also track the server pid file to trigger the hot-reloading tasks when the server is instantiated or shuts down.

```@docs
RxInferServer.ServerState
RxInferServer.RoutesHandler
RxInferServer.is_server_running
RxInferServer.set_server_running
RxInferServer.is_server_errored
RxInferServer.set_server_errored
RxInferServer.notify_instantiated
RxInferServer.wait_instantiated
RxInferServer.pid_server_event
```