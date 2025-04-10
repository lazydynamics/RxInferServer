```@meta
CurrentModule = RxInferServer
```

# Welcome to RxInferServer

!!! warning
    The implementation is work in progress and the API is not yet stable and may undergo significant changes. Use at your own risk.

**RxInferServer** is a Julia package that provides an implementation of a REST API server for [RxInfer.jl](https://github.com/biaslab/RxInfer.jl), enabling remote access to inference capabilities through HTTP endpoints. The server is built on top of HTTP.jl and follows OpenAPI specifications. Read more about the OpenAPI specification [here](@ref openapi).

!!! note
    While the server is technically implemented as a Julia package, it relies on locally auto-generated code from the OpenAPI specification. This makes it more challenging (though not impossible) to use it as a direct dependency in another Julia project. For the same reason, the server is not registered as a Julia package and cannot be installed using Pkg.jl. Please refer to the Pkg.jl documentation for more information on working with such packages.

## Getting started

- See the [Getting started](@ref getting-started) section to learn how to use the server.
- See the [Configuration](@ref configuration) section to learn how to configure the server.
- See the [How to Add a Model](@ref manual-how-to-add-a-model) manual to learn how to create and add your own models.
- See the [Developers guide](@ref developers-guide) section for more details on the development process and implementation details.
- See the [OpenAPI documentation](@ref openapi) section for more details on the OpenAPI specification and the generated server and client code.

## [License](@id license)

This project is licensed under the GNU Affero General Public License v3.0 - see the LICENSE in the repository for details. For companies and organizations that require different licensing terms, alternative licensing options are available from [Lazy Dynamics](https://www.lazydynamics.com). Please [contact](mailto:info@lazydynamics.com) Lazy Dynamics for more information about licensing options that may better suit your specific needs and use cases.

## Index

```@index
```