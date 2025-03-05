using RxInferServer
using Documenter
using DocumenterMermaid

DocMeta.setdocmeta!(RxInferServer, :DocTestSetup, :(using RxInferServer); recursive=true)

makedocs(;
    modules=[RxInferServer],
    authors="Lazy Dynamics <info@lazydynamics.com>",
    sitename="RxInferServer.jl",
    format=Documenter.HTML(;
        canonical="https://lazydynamics.github.io/RxInferServer.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Design proposal" => "api/design-proposal.md",
    ],
)

deploydocs(;
    repo="github.com/lazydynamics/RxInferServer.jl",
    devbranch="main",
)
