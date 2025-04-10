# [Getting Started](@id getting-started)

RxInferServer is a web server that provides a REST API for running Bayesian inference using the [RxInfer.jl](https://github.com/ReactiveBayes/RxInfer.jl) package. It allows users to define probabilistic models, upload data, and run inference through HTTP requests. This guide will walk you through the installation process and shows how to start the server.

## Installation

To begin using RxInferServer, first clone the repository:

```bash
git clone git@github.com:lazydynamics/RxInferServer.git
```

and navigate to the repository's directory by running:

```bash
cd RxInferServer
```

!!! note
    While the server is technically implemented as a Julia package, it relies on locally auto-generated code from the OpenAPI specification. This makes it more challenging (though not impossible) to use it as a direct dependency in another Julia project. For the same reason, the server is not registered as a Julia package and cannot be installed using Pkg.jl. Please refer to the Pkg.jl documentation for more information on working with such packages.

## Makefile 

The repository includes a Makefile for convenience. To check the available commands, run:

```bash
make help
```

## Database setup

The server requires a database to store model and inference related information. Read more about the database in the [Database](@ref database) section. For development purposes, the server can be started with `make docker` command which will automatically start the database in a docker container

```bash
make docker
```

## Starting the Server

To start the development version of the server, run:

```
make serve
```

This will automatically start Julia and call the [`RxInferServer.serve`](@ref) function with default settings. Read more about available options in the [Configuration](@ref configuration) section.

It is also possible to manually start the server from the Julia REPL:

```bash
julia --project
```

```julia-repl
julia> using RxInferServer

julia> ENV["RXINFER_SERVER_ENABLE_HOT_RELOAD"] = "true"

julia> RxInferServer.serve()
```

Note that the [`RxInferServer.serve`](@ref) is a blocking function and will keep the REPL busy. To start the server in the background, you can use the `@async` or `Threads.@spawn` macros. Read more about the `@async` and `Threads.@spawn` macros in the [Julia Documentation](https://docs.julialang.org/en/v1/manual/parallel-computing/).

## Configuration 

To change the configuration of the server, you can set the environment variables before starting the server. Read more about the configuration in the [Configuration](@ref configuration) section. Alternatively, you can change the configuration using the [`.env` files](@ref environment-configuration-with-env-files).

## Closing the Server

To close the server, type `q` and hit `ENTER`. Alternatively, you can use the `Ctrl-C` shortcut.

!!! note
    When running the server from script, e.g. `make serve`, Ctrl-C might not work properly. See [How do I catch CTRL-C in a script?](https://docs.julialang.org/en/v1/manual/faq/#catch-ctrl-c) for more information.

## API Reference

```@docs
RxInferServer.serve
```

## Where to go next?

- Read more about the different configuration options in the [Configuration](@ref configuration) section
- Create your first model with the [Model management](@ref model-management-api) section
- For detailed information about how to create and add your own models to the server, check out the [How to Add a Model](@ref manual-how-to-add-a-model) manual
- If you want to contribute to the project, read more about the [Development](@ref developers-guide) section