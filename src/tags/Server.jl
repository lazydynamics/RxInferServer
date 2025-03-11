using HTTP, Pkg

const SERVER_EDITION = get(ENV, "RXINFER_SERVER_EDITION", "CommunityEdition")

function get_server_info(req::HTTP.Request)::RxInferServerOpenAPI.ServerInfo
    # Somewhat hacky way to get the current context of Julia environment
    manifest = Pkg.Operations.Context().env.manifest

    rxinfer_version_entry = findfirst(x -> x.name == "RxInfer", manifest)
    rxinfer_version = !isnothing(rxinfer_version_entry) ? string(manifest[rxinfer_version_entry].version) : "unknown"

    server_version_entry = findfirst(x -> x.name == "RxInferServer", manifest)
    server_version = !isnothing(server_version_entry) ? string(manifest[server_version_entry].version) : "unknown"

    return RxInferServerOpenAPI.ServerInfo(
        rxinfer_version=rxinfer_version,
        server_version=server_version,
        server_edition=SERVER_EDITION,
        julia_version=string(VERSION)
    )
end