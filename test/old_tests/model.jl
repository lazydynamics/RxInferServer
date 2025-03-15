@testitem "Server Creation" begin
    using HTTP
    using RxInferServer
    using RxInferServer.OldImplementation

    server = RxInferModelServer(8081)
    @test server.port == 8081
    @test server.server === nothing
    @test server.router isa HTTP.Router
end

@testitem "Adding Endpoints" begin
    using HTTP
    using RxInferServer
    using RxInferServer.OldImplementation

    server = RxInferModelServer(8082)

    # Test adding a GET endpoint
    handler(req) = HTTP.Response(200, "OK")
    add(handler, server, "/test")

    # Test adding a POST endpoint
    post_handler(req) = HTTP.Response(201, "Created")
    add(post_handler, server, "/post-test", method = "POST")

    # Start server to test endpoints
    @async start(server)
    sleep(1)  # Give server time to start

    try
        # Test GET endpoint
        response = HTTP.get("http://localhost:8082/test")
        @test response.status == 200
        @test String(response.body) == "OK"

        # Test POST endpoint
        response = HTTP.post("http://localhost:8082/post-test")
        @test response.status == 201
        @test String(response.body) == "Created"

        # Test wrong method on GET endpoint
        @test_throws HTTP.ExceptionRequest.StatusError HTTP.post("http://localhost:8082/test")

        # Test wrong method on POST endpoint
        @test_throws HTTP.ExceptionRequest.StatusError HTTP.get("http://localhost:8082/post-test")

        # Test non-existent endpoint
        @test_throws HTTP.ExceptionRequest.StatusError HTTP.get("http://localhost:8082/nonexistent")
    finally
        stop(server)
    end
end

@testitem "Server Lifecycle" begin
    using HTTP
    using RxInferServer
    using RxInferServer.OldImplementation
    server = RxInferModelServer(8083)

    # Add a test endpoint
    add(server, "/hello") do req
        return HTTP.Response(200, "Hello, World!")
    end

    # Start the server
    @async start(server)
    sleep(1)  # Give the server time to start

    # Test if server is running
    @test server.server !== nothing

    try
        # Test the endpoint
        response = HTTP.get("http://localhost:8083/hello")
        @test response.status == 200
        @test String(response.body) == "Hello, World!"

        # Test non-existent endpoint
        @test_throws HTTP.ExceptionRequest.StatusError HTTP.get("http://localhost:8083/nonexistent")

        # Test starting an already running server
        start(server)  # Should print "Server is already running"
        @test server.server !== nothing
    finally
        # Test stopping the server
        stop(server)
        @test server.server === nothing

        # Test stopping an already stopped server
        stop(server)  # Should handle this gracefully
        @test server.server === nothing
    end
end

@testitem "Serving RxInfer Model - Basic Functionality" begin
    using HTTP
    using RxInferServer
    using RxInfer
    using StableRNGs
    using Distributions
    using JSON3
    using RxInferServer.OldImplementation

    # Define a simple coin toss model
    @model function coin_model(y, a, b)
        θ ~ Beta(a, b)
        for i in eachindex(y)
            y[i] ~ Bernoulli(θ)
        end
    end

    # Generate some synthetic data
    rng = StableRNG(42)
    n = 100
    θ_real = 0.75
    dataset = float.(rand(rng, Bernoulli(θ_real), n))

    # Define constraints and initialization
    constraints = @constraints begin
        q(θ, y) = q(θ)q(y)
    end

    init = @initialization begin
        q(θ) = Beta(1.0, 1.0)
    end

    # Create server
    server = RxInferModelServer(8084)

    # Add endpoints with different settings
    add_model(
        server, "/coin-single", coin_model(a = 4.0, b = 8.0), [:θ], constraints = constraints, initialization = init
    )

    add_model(
        server,
        "/coin-history",
        coin_model(a = 4.0, b = 8.0),
        [:θ],
        constraints = constraints,
        initialization = init,
        returnvars = (θ = KeepEach(),),
        iterations = 30
    )

    # Start server
    @async start(server)
    sleep(1)  # Give server time to start

    try
        # Test single distribution response with default settings
        response = HTTP.post(
            "http://localhost:8084/coin-single",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("data" => Dict("y" => dataset)))
        )

        @test response.status == 200
        result = JSON3.read(response.body)
        # Check response format
        @test haskey(result, "posteriors")
        @test haskey(result["posteriors"], "θ")
        @test result["posteriors"]["θ"] == Dict(:α => 76.0, :β => 36.0)
        @test length(result["posteriors"]["θ"]) == 2  # Beta has 2 parameters

        # Reconstruct distribution and verify
        post = result["posteriors"]["θ"]
        α, β = post[:α], post[:β]
        reconstructed_dist = Beta(α, β)
        # @test mean(reconstructed_dist) ≈ θ_real atol = 0.1

        # Test with custom inference parameters in request
        response_custom = HTTP.post(
            "http://localhost:8084/coin-single",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("data" => Dict("y" => dataset), "iterations" => 50, "free_energy" => true))
        )
        @test response_custom.status == 200
        result_custom = JSON3.read(response_custom.body)
        @test haskey(result_custom, "free_energy")
        free_energy = collect(result_custom["free_energy"])
        @test typeof(free_energy) <: Array{Float64, 1}
        @test length(free_energy) == 50

        # Test history response
        response_history = HTTP.post(
            "http://localhost:8084/coin-history",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("data" => Dict("y" => dataset)))
        )

        @test response_history.status == 200
        result_history = JSON3.read(response_history.body)

        # Check history format
        @test haskey(result_history, "posteriors")
        @test haskey(result_history["posteriors"], "θ")
        posteriors = collect(result_history["posteriors"]["θ"])
        @test length(posteriors) > 1  # Should have multiple iterations
        @test haskey(posteriors[1], "α")
        @test haskey(posteriors[1], "β")

        # Test error handling
        # Missing data field
        @test_throws HTTP.ExceptionRequest.StatusError HTTP.post(
            "http://localhost:8084/coin-single",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("invalid" => "data"))
        )

        # Malformed JSON
        @test_throws HTTP.ExceptionRequest.StatusError HTTP.post(
            "http://localhost:8084/coin-single", ["Content-Type" => "application/json"], "invalid json"
        )

        # Wrong data type
        @test_throws HTTP.ExceptionRequest.StatusError HTTP.post(
            "http://localhost:8084/coin-single",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("data" => Dict("y" => "not an array")))
        )
    finally
        stop(server)
    end
end

@testitem "Serving RxInfer Model - Multiple Endpoints" begin
    using HTTP
    using RxInferServer
    using RxInfer
    using StableRNGs
    using Distributions
    using JSON3
    using RxInferServer.OldImplementation

    # Define two different models
    @model function coin_model(y, a, b)
        θ ~ Beta(a, b)
        for i in eachindex(y)
            y[i] ~ Bernoulli(θ)
        end
    end

    @model function normal_model(x)
        μ ~ NormalMeanVariance(0.0, 10.0)
        σ ~ InverseGamma(1.0, 1.0)
        for i in eachindex(x)
            x[i] ~ NormalMeanVariance(μ, σ)
        end
    end

    # Create server with both models
    server = RxInferModelServer(8085)

    # Add coin model endpoint
    add_model(
        server,
        "/coin",
        coin_model(a = 1.0, b = 1.0),
        [:θ],
        constraints = @constraints(q(θ, y) = q(θ)q(y)),
        initialization = @initialization(q(θ) = Beta(1.0, 1.0))
    )

    constraints = @constraints begin
        q(μ, σ, x) = q(μ)q(σ)q(x)
    end

    init = @initialization begin
        q(μ) = NormalMeanVariance(0.0, 10.0)
        q(σ) = InverseGamma(1.0, 1.0)
    end

    # Add normal model endpoint with free energy computation
    add_model(
        server,
        "/normal",
        normal_model(),
        [:μ, :σ],
        constraints = constraints,
        initialization = init,
        free_energy = true,
        iterations = 100,
        returnvars = (μ = KeepLast(), σ = KeepLast())
    )

    @async start(server)
    sleep(1)

    try
        # Test coin model
        rng = StableRNG(42)
        coin_data = float.(rand(rng, Bernoulli(0.7), 100))
        coin_response = HTTP.post(
            "http://localhost:8085/coin",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("data" => Dict("y" => coin_data)))
        )
        @test coin_response.status == 200
        coin_result = JSON3.read(coin_response.body)
        @test haskey(coin_result, "posteriors")
        @test haskey(coin_result["posteriors"], "θ")
        post = coin_result["posteriors"]["θ"]
        α, β = post[:α], post[:β]
        @test mean(Beta(α, β)) ≈ 0.7 atol = 0.1

        # Test normal model with free energy
        normal_data = randn(rng, 1000) .* 2.0 .+ 1.0  # μ=1.0, σ=2.0
        normal_response = HTTP.post(
            "http://localhost:8085/normal",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("data" => Dict("x" => normal_data)))
        )
        @test normal_response.status == 200
        normal_result = JSON3.read(normal_response.body)

        # Check posteriors
        @test haskey(normal_result, "posteriors")
        @test haskey(normal_result["posteriors"], "μ")
        @test haskey(normal_result["posteriors"], "σ")

        # Check free energy
        @test haskey(normal_result, "free_energy")
        free_energy = collect(normal_result["free_energy"])
        @test typeof(free_energy) <: Array{Float64, 1}

        # Verify μ parameters
        μ_post = normal_result["posteriors"]["μ"]
        @test haskey(μ_post, "xi")
        @test haskey(μ_post, "w")
        μ_dist = NormalWeightedMeanPrecision(μ_post["xi"], μ_post["w"])
        @test mean(μ_dist) ≈ 1.0 atol = 0.5

        # Verify σ parameters
        σ_post = normal_result["posteriors"]["σ"]
        @test haskey(σ_post, "invd")
        @test haskey(σ_post, "θ")
        σ_dist = InverseGamma(σ_post["invd"]["α"], σ_post["θ"])
        @test mean(σ_dist) ≈ 2.0 atol = 3.0
    finally
        stop(server)
    end
end

@testitem "Factorize keyword tests" begin
    using HTTP
    using JSON3
    using RxInfer
    using RxInferServer
    using StableRNGs
    using Distributions
    using RxInferServer.OldImplementation

    @model function coin_model(y, a, b)
        θ ~ Beta(a, b)
        for i in eachindex(y)
            y[i] ~ Bernoulli(θ)
        end
    end

    # Create server
    server = RxInferModelServer(8086)

    # Add coin model endpoint
    add_model(
        server,
        "/coin",
        coin_model(a = 1.0, b = 1.0),
        [:θ],
        constraints = @constraints(q(θ, y) = q(θ)q(y)),
        initialization = @initialization(q(θ) = Beta(1.0, 1.0)),
        factorize = (y = true,)
    )

    @async start(server)
    sleep(1)

    try
        # Test coin model
        rng = StableRNG(42)
        coin_data = float.(rand(rng, Bernoulli(0.7), 100))
        coin_response = HTTP.post(
            "http://localhost:8086/coin",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("data" => Dict("y" => coin_data)))
        )
        @test coin_response.status == 200
        coin_result = JSON3.read(coin_response.body)
        @test haskey(coin_result, "posteriors")
        @test haskey(coin_result["posteriors"], "θ")
        post = coin_result["posteriors"]["θ"]
    finally
        stop(server)
    end
end
