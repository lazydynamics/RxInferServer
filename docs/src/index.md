```@meta
CurrentModule = RxInferServer
```

# RxInferServer

Documentation for [RxInferServer](https://github.com/lazydynamics/RxInferServer.jl).

!!! warning
    The implementation is work in progress and the API is not yet stable and may undergo significant changes. Use at your own risk.

## Overview

RxInferServer provides a REST API server for [RxInfer.jl](https://github.com/biaslab/RxInfer.jl), enabling remote access to inference capabilities through HTTP endpoints. The server is built on top of HTTP.jl and follows OpenAPI specifications.

## API Documentation

The RxInferServer API is documented using the OpenAPI specification. You can explore the API in the following ways:

1. Interact with the stable version of the API using the [Swagger UI](https://petstore.swagger.io/?url=https://server.rxinfer.com/stable/openapi/spec.yaml)
2. Interact with the latest version of the API using the [Swagger UI](https://petstore.swagger.io/?url=https://server.rxinfer.com/dev/openapi/spec.yaml)

The Swagger UI provides an interactive interface to explore the API endpoints, make test requests, and view response formats. It's a helpful tool for developers integrating with the RxInferServer API.

## Development and implementation details

See the [Development](@ref developers-guide) section for more details on the development process and implementation details.

```@index
```

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the LICENSE file for details.

For companies and organizations that require different licensing terms, alternative licensing options are available from [Lazy Dynamics](https://www.lazydynamics.com). Please [contact](mailto:info@lazydynamics.com) Lazy Dynamics for more information about licensing options that may better suit your specific needs and use cases.