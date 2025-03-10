# RxInferServer.jl

> [!NOTE]  
> This is a work in progress and the API is not yet stable and may undergo significant changes. Use at your own risk.

A Julia package that provides RESTful HTTP server functionality for deploying [RxInfer.jl](https://github.com/biaslab/RxInfer.jl) probabilistic models as web services.

## Installation

```julia
using Pkg
Pkg.add("RxInferServer")
```

## Planned features

- Deploy RxInfer models as HTTP endpoints
- Create multiple instances of the same model
- Run inference, planning and learning in parallel
- Configurable inference parameters (iterations, free energy computation)
- Flexible data input and output formats
- Data layout verification (e.g. missing data, etc.)
- Extensive statistics and diagnostics
- Support for model history and posterior distribution tracking

## OpenAPI Specification and Code Generation

This repository includes an OpenAPI specification for the RxInferServer.jl API and tools to generate Julia server code from it.

### Prerequisites

- Docker and Docker Compose installed on your system

### Getting Started

From the root directory of the repository, run:

```bash
docker-compose up -d
```

This will start:
- Swagger Editor: a web-based editor for OpenAPI specifications
- OpenAPI Generator: a tool to generate server code from OpenAPI specifications

### Accessing the Swagger Editor

Open your browser and navigate to: http://localhost:8080

The editor will automatically load the `openapi/openapi.yaml` file from this directory.

### Generating Server Code

To generate Julia server code from the OpenAPI specification, run:

```bash
./generate-server.sh
```

This script will:
1. Check if Docker is running
2. Ensure the Docker Compose services are up
3. Run the OpenAPI Generator with appropriate parameters
4. Generate Julia server code in the `generated` directory

### Working with the Generated Code

The generated code will be placed in the `generated` directory. You can integrate this code with your existing RxInferServer.jl implementation.

### Customizing the OpenAPI Specification

Edit the `openapi/openapi.yaml` file either directly or through the Swagger Editor to customize your API specification. 

**Important:** After making ANY changes to the OpenAPI specification, you MUST regenerate the server code by running the generation script again:

```bash
./generate-server.sh
```

Changes to the OpenAPI specification are NOT automatically reflected in the server code. Failing to regenerate the code will result in inconsistencies between your API specification and the actual server implementation.

### Additional Resources

- [OpenAPI Specification](https://swagger.io/specification/)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Julia Server Template](https://openapi-generator.tech/docs/generators/julia-server)

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the LICENSE file for details.

For companies and organizations that require different licensing terms, commercial licenses are available from [Lazy Dynamics](https://www.lazydynamics.com). Please [contact](mailto:info@lazydynamics.com) Lazy Dynamics for more information about commercial licensing options that may better suit your specific needs and use cases.
