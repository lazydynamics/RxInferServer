# !!! do not wrap this file in a separate module !!!

# NOTE: Hot reload functionality is only available when Revise is loaded
# in the current Julia session. See the `ext/HotReloadExt/HotReloadExt.jl` 
# module for the actual implementation. 
# This file only contains the public-facing API for the hot reload functionality.

using UUIDs

"""
    RXINFER_SERVER_ENABLE_HOT_RELOAD()

Whether to enable hot reloading or not.
This can be configured using the `RXINFER_SERVER_ENABLE_HOT_RELOAD` environment variable.
Defaults to `"true"` if not specified, but `Revise.jl` must be loaded in the current Julia session
for this functionality to work. If the setting is set to `"true"`, but `Revise.jl` is not loaded,
the server will not hot reload the source code and models when the source code changes and print a warning instead.
Set to `"false"` to disable hot reloading even if `Revise.jl` is loaded.

```julia
using Revise

# Check current setting
ENV["RXINFER_SERVER_ENABLE_HOT_RELOAD"] = "true"

RxInferServer.serve()
```

See also: [`RxInferServer.is_hot_reload_enabled`](@ref)
"""
RXINFER_SERVER_ENABLE_HOT_RELOAD() = get(ENV, "RXINFER_SERVER_ENABLE_HOT_RELOAD", "false")

"""
    is_hot_reload_enabled()

Check if hot reloading is enabled.

```julia
# Check current setting
RxInferServer.is_hot_reload_enabled() 
```

See also: [`RxInferServer.RXINFER_SERVER_ENABLE_HOT_RELOAD`](@ref)
"""
function is_hot_reload_enabled()
    return lowercase(RXINFER_SERVER_ENABLE_HOT_RELOAD()) == "true"
end

function is_revise_loaded()
    return haskey(Base.loaded_modules, Base.PkgId(UUID("295af30f-e4ad-537b-8983-00126c2a3abe"), "Revise"))
end

function hot_reloading_banner_hint()
    if is_hot_reload_enabled() && is_revise_loaded()
        return "Hot reloading is enabled and Revise.jl is loaded in the current Julia session."
    elseif is_hot_reload_enabled() && !is_revise_loaded()
        return "Hot reloading is requested, but Revise.jl is not loaded in the current Julia session. Run `using Revise` before starting the server to enable hot reloading."
    elseif !is_hot_reload_enabled()
        return "Hot reloading is disabled."
    end
end

# Creates a task that hot reloads the server when the source code changes
# Basically only one vaiable option for Julia is Revise.jl, see `ext/HotReloadExt/HotReloadExt.jl` for the actual implementation
function hot_reload_task(
    f::F, label::Symbol, state::ServerState, files, modules; all = false, postpone = true
) where {F}
    if !is_hot_reload_enabled()
        @info "Hot reloading is disabled" label _id = :hot_reload
        return nothing
    end
    if !is_revise_loaded()
        @warn "Hot reloading is enabled, but Revise.jl is not loaded in the current Julia session. Run `using Revise` before starting the server to enable hot reloading." label _id =
            :hot_reload
        return nothing
    end
    # Add the server pid file to the list of files to watch for changes
    # This is intended to trigger a hot reload when the server pid file is changed
    files_with_pid_file = vcat(files, [state.pid_file])
    return hot_reload_task(Val(:Revise), f, label, state, files_with_pid_file, modules; all = all, postpone = postpone)
end

# This is intentionally not implemented and is supposed to be overwritten by the actual implementation 
#   - Revise.jl implementation in `ext/HotReloadExt/HotReloadExt.jl`
function hot_reload_task(
    hot_reload_backend, f::F, label::Symbol, state::ServerState, files, modules; all = false, postpone = true
) where {F}
    @warn "Hot reloading is not supported for the given hot reload backend: $hot_reload_backend" label _id = :hot_reload
    return nothing
end

# Hot reload task for the source code, it tracks changes in the 
# - RxInferServerOpenAPI
# - The current module, which is the module of the server 
# !!! do not wrap this file in a separate module !!!
function hot_reload_task_source_code(state::ServerState)
    return hot_reload_task(:source_code, state, [], [RxInferServerOpenAPI, @__MODULE__]; all = true) do
        io = IOBuffer()
        # The register function prints a lot of annoying warnings with routes being replaced
        # But this is the actual purpose of the hot reload task, so we suppress the warnings
        Logging.with_simple_logger(io) do
            RxInferServerOpenAPI.register(
                state.router,
                state.handler;
                path_prefix = API_PATH_PREFIX,
                pre_validation = middleware_pre_validation,
                post_invoke = middleware_post_invoke
            )
        end
        if occursin("replacing existing registered route", String(take!(io)))
            @warn "[HOT-RELOAD] Successfully replaced existing registered route" _id = :hot_reload
        end
    end
end

function hot_reload_task_models(state::ServerState)
    locations = Models.RXINFER_SERVER_MODELS_LOCATIONS()

    if Models.RXINFER_SERVER_LOAD_TEST_MODELS()
        locations = vcat(locations, [Models.RXINFER_SERVER_TEST_MODELS_LOCATION()])
    end

    hot_reload_models_locations = [
        joinpath(root, file) for location in locations for (root, _, files) in walkdir(location) if isdir(location) for
        file in files
    ]
    return hot_reload_task(:models, state, hot_reload_models_locations, []; all = false) do
        Models.reload!(Models.get_models_dispatcher())
        @warn "[HOT-RELOAD] Models have been reloaded" _id = :hot_reload
    end
end
