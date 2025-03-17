module HotReloadExt

using Revise, RxInferServer

function RxInferServer.hot_reload_task(
    ::Val{:Revise}, f::F, label::Symbol, state::RxInferServer.ServerState, files, modules; all = false, postpone = true
) where {F}
    return Threads.@spawn begin
        RxInferServer.wait_instantiated(state)
        # If the server is not running, do not start the hot reload task
        # This might happen for example if the server failed to start, due to database connection issues
        if RxInferServer.is_server_running(state)
            @warn "[HOT-RELOAD] Starting hot reload task for" label _id = :hot_reload
            number_of_concecutive_failures = 0
            max_number_of_concecutive_failures = 10
            while (
                RxInferServer.is_server_running(state) &&
                number_of_concecutive_failures < max_number_of_concecutive_failures
            )
                try
                    # Watch for changes in server code and automatically update endpoints
                    Revise.entr(files, modules; all = all, postpone = postpone) do
                        if RxInferServer.is_server_running(state)
                            f()
                        else
                            throw(InterruptException())
                        end
                    end
                    number_of_concecutive_failures = 0
                catch e
                    if RxInferServer.is_server_running(state)
                        @error "[HOT-RELOAD] Hot reload task encountered an error: $e" label _id = :hot_reload
                    else
                        @warn "[HOT-RELOAD] Exiting hot reload task for" label _id = :hot_reload
                    end
                    number_of_concecutive_failures += 1
                end
            end
            if number_of_concecutive_failures >= max_number_of_concecutive_failures
                @error "[HOT-RELOAD] Hot reload task failed $max_number_of_concecutive_failures times in a row. Exiting..." label _id =
                    :hot_reload
            end
        end
    end
end

end