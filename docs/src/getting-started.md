# [Getting Started](@id getting-started)

## Installation

To begin using RxInferServer, first clone the repository:

```bash
git clone git@github.com:lazydynamics/RxInferServer.git
```

Navigate to the repository:

```bash
cd RxInferServer
```

## Makefile 

The repository includes a Makefile for convenience. To check the available commands, run:

```bash
make help
```

```@eval 
using Documenter
p = joinpath(@__DIR__, "..", "..", "Makefile")
io = IOBuffer()
run(pipeline(setenv(`make help -f $p`, "NO_COLOR" => "1"), stdout=io, stderr=io))
makehelpoutput = String(take!(io))
s = """
\`\`\`
$makehelpoutput
\`\`\`
"""
md = Documenter.Markdown.parse(s)
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

## Closing the Server

To close the server, type `q` and hit `ENTER`. Alternatively, you can use the `Ctrl-C` shortcut.

!!! note
    When running the server from script, e.g. `make serve`, Ctrl-C might not work properly. See [How do I catch CTRL-C in a script?](https://docs.julialang.org/en/v1/manual/faq/#catch-ctrl-c) for more information.

## API Reference

```@docs
RxInferServer.serve
```

## Where to go next?

Read more about the different configuration options in the [Configuration](@ref configuration) section or create your first model with the [Model management](@ref model-management-api) section.

If you want to contribute to the project, read more about the [Development](@ref developers-guide) section.