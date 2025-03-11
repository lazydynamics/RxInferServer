# Development

This section describes the development process for the RxInferServer.jl project and how to setup the development environment.

## OpenAPI Specification and Code Generation

This repository includes an OpenAPI specification for the RxInferServer.jl API and tools to generate Julia server code from it.

### Prerequisites

- Docker and Docker Compose installed on your system
- Visual Studio Code (or your preferred code editor) for editing the OpenAPI specification

### Development environment with Docker

To start the development environment with Docker, from the root directory of the repository, run:

```bash
docker-compose up -d
```

Or alternatively, use VSCode extension "Docker" to start the server. The VSCode extension also allows to check the logs and attach to the running container. Read more about docker here: [Docker](https://docs.docker.com/get-started/).

The `docker-compose.yaml` currently has the following services:

- RxInferServer: the server implementation running in the background on `localhost:8000` with hot-reloading enabled by default, use `LocalPreferences.toml` file to configure the server
- Swagger UI: a web interface for visualizing and testing the OpenAPI specification, the UI is available at `http://localhost:8080` and allows to test the API endpoints, the endpoints can also be tested in VSCode by opening `spec.yaml` directly and clicking on the "Try it" button
- OpenAPI Generator: a tool to generate server code from OpenAPI specifications, normally is in idle state, but should be running in order to generate the server code from the OpenAPI specification with the `./generate-server.sh` script

### Editing the OpenAPI Specification

Edit the `openapi/spec.yaml` file directly in VSCode or your preferred code editor. The OpenAPI specification uses the YAML format and follows the [OpenAPI 3](https://swagger.io/specification/) standard.

Some useful VS Code extensions for working with OpenAPI specifications include:
- "OpenAPI (Swagger) Editor" by 42Crunch
- "YAML" by Red Hat
- "Docker" by Microsoft

### Accessing Swagger UI

Open your browser and navigate to: http://localhost:8080

The Swagger UI will automatically load the `openapi/spec.yaml` file, allowing you to visualize and test your API without leaving your browser. Alternatively, you can test the API endpoints in VSCode by opening `spec.yaml` directly and clicking on the "Try it" button.

### Generating Server Code

To generate Julia server code from the OpenAPI specification, run:

```bash
./generate-server.sh
```

This script will:
1. Check if Docker is running
2. Ensure the Docker Compose services are up
3. Run the OpenAPI Generator with appropriate parameters
4. Generate Julia server code in the `openapi/server` directory

### Working with the Generated Code

The generated code will be placed in the `openapi/server` directory as a separate Julia module and should never be modified directly. The `RxInferServer.jl` package will automatically load the generated code when the package is loaded. 

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

### Customizing the OpenAPI Specification

Edit the `openapi/spec.yaml` file directly in your code editor to customize your API specification. 

!!! warning "Important"
    After making ANY changes to the OpenAPI specification, you MUST regenerate the server code by running the generation script again:

```bash
./generate-server.sh
```

Failing to regenerate the code after changes to the OpenAPI specification will result in inconsistencies between your API specification and the actual server implementation. The code is not being re-generated automatically for two primary reasons:
- It might be somewhat slow for a lot of endpoints
- It most likely will cause `Revise` errors with redefined structures 

### Additional Resources

- [OpenAPI Specification](https://swagger.io/specification/)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Julia Server Template](https://openapi-generator.tech/docs/generators/julia-server)