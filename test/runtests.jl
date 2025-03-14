using Aqua, TestItemRunner, RxInferServer
using HTTP, Dates

Aqua.test_all(RxInferServer; ambiguities = false, piracies = false, deps_compat = (; check_extras = false, check_weakdeps = true))

# Check if the server is running by pinging it with timeout
function wait_for_server(; host = "localhost", port = 8000, timeout_seconds = 600, retry_interval = 5)
    @info "Waiting for server to start..."
    endpoint = "http://$(host):$(port)/v1/ping"
    start_time = now()
    server_started = false

    while (now() - start_time) < Second(timeout_seconds)
        try
            response = HTTP.get(endpoint, status_exception = false)
            if response.status == 200
                @info "Server started successfully!"
                server_started = true
                break
            end
        catch e
            # This is expected if the server isn't ready yet
            @info "Server not ready yet, retrying in $(retry_interval) seconds..."
        end
        sleep(retry_interval)
    end

    if !server_started
        error("Server failed to start within the timeout period ($(timeout_seconds)s)")
    end

    return server_started
end

# Verify that the server is running before proceeding with tests
wait_for_server()

TestItemRunner.@run_package_tests()
