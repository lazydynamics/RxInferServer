# Getting Started

## Installation

Clone the repository and add the package to your Julia environment:

```julia
using Pkg
Pkg.add("RxInferServer")
```

Refer to Julia documentation for more information on how to add packages to your Julia environment: [Julia Documentation](https://docs.julialang.org/en/v1/).

## Starting the Server

```@docs
RxInferServer.serve
```

To start the server with default settings:

```julia
using RxInferServer

# This will block until stopped manually
RxInferServer.serve()
```

!!! note
    When running the server from script, e.g. `make serve`, Ctrl-C might not work properly. See [How do I catch CTRL-C in a script?](https://docs.julialang.org/en/v1/manual/faq/#catch-ctrl-c) for more information.

To start the server in the background:

```julia
@async RxInferServer.serve()

# or 

Threads.@spawn RxInferServer.serve()
```

Read more about the `@async` and `Threads.@spawn` macros in the [Julia Documentation](https://docs.julialang.org/en/v1/manual/parallel-computing/).

### Where to go next?

Read more about the different configuration options in the [Configuration](@ref configuration) section.

If you want to contribute to the project, read more about the [Development](@ref development) section.