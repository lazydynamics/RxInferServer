@testitem "DeployableRxInferModel - Coin Toss" begin
    using RxInfer
    using RxInferServer
    using StableRNGs
    using Distributions

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

    # Create deployable model
    deployable = DeployableRxInferModel(
        coin_model(a=4.0, b=8.0),
        constraints,
        init
    )

    # Test NamedTuple interface
    result_dict = deployable((y=dataset,), [:θ])
    @test haskey(result_dict, "posteriors")
    @test haskey(result_dict["posteriors"], :θ)

    post = result_dict["posteriors"][:θ]

    @test mean(post) ≈ θ_real atol = 0.1

    # Test kwargs interface
    result_kwargs = deployable(data=(y=dataset,), output=[:θ])
    @test haskey(result_kwargs, "posteriors")
    @test haskey(result_kwargs["posteriors"], :θ)
    post_θ = result_kwargs["posteriors"][:θ]
    @test mean(post_θ) ≈ θ_real atol = 0.1

    # Test error handling for missing output specification
    @test_throws ArgumentError deployable(data=(y=dataset,))
end

@testitem "DeployableRxInferModel - Missing Data Handling" begin
    using RxInfer
    using RxInferServer
    using StableRNGs
    using Distributions

    # Define a simple smoothing model that can handle missing data
    @model function smoothing_model(x0, y)
        P ~ Gamma(shape=0.001, scale=0.001)
        x_prior ~ Normal(mean=mean(x0), var=var(x0))

        local x
        x_prev = x_prior

        for i in 1:length(y)
            x[i] ~ Normal(mean=x_prev, precision=1.0)
            y[i] ~ Normal(mean=x[i], precision=P)
            x_prev = x[i]
        end
    end

    # Generate data with missing values
    rng = StableRNG(42)
    n = 50
    real_signal = map(e -> sin(0.05 * e), 1:n)
    noisy_data = real_signal + randn(rng, n)
    missing_data = Vector{Union{Float64,Missing}}(noisy_data)
    missing_data[20:25] .= missing

    # Define constraints and initialization
    constraints = @constraints begin
        q(x_prior, x, y, P) = q(x_prior, x)q(P)q(y)
    end

    init = @initialization begin
        q(P) = Gamma(0.001, 0.001)
    end

    x0_prior = NormalMeanVariance(0.0, 1000.0)

    # Create deployable model
    deployable = DeployableRxInferModel(
        smoothing_model(x0=x0_prior),
        constraints,
        init
    )

    # Test handling of missing data
    result = deployable((y=missing_data,), [:x])
    @test haskey(result, "posteriors")
    @test haskey(result["posteriors"], :x)
    x_posts = result["posteriors"][:x]
    @test length(x_posts) == n

    # Check that we get estimates even for missing data points
    for i in 20:25
        post = x_posts[i]
        @test !isnan(mean(post))
    end
end

@testitem "DeployableRxInferModel - Inference Parameters" begin
    using RxInfer
    using RxInferServer
    using StableRNGs
    using Distributions

    # Define a simple model where iterations matter
    @model function nonlinear_model(x)
        μ ~ NormalMeanVariance(0.0, 10.0)
        σ ~ InverseGamma(1.0, 1.0)
        for i in eachindex(x)
            x[i] ~ NormalMeanVariance(μ, σ)
        end
    end

    # Generate synthetic data
    rng = StableRNG(42)
    n = 1000
    μ_real = 2.0
    σ_real = 1.0
    data = randn(rng, n) .* sqrt(σ_real) .+ μ_real

    # Create deployable model
    deployable = DeployableRxInferModel(
        nonlinear_model(),
        @constraints(q(μ, σ, x) = q(μ)q(σ)q(x)),
        @initialization begin
            q(μ) = NormalMeanVariance(0.0, 10.0)
            q(σ) = InverseGamma(1.0, 1.0)
        end
    )

    # Test with different numbers of iterations
    result_few = deployable(data=(x=data,), output=[:μ], iterations=1)
    result_many = deployable(data=(x=data,), output=[:μ], iterations=50)

    # More iterations should give better estimate
    error_few = abs(mean(last(result_few["posteriors"][:μ])) - μ_real)
    error_many = abs(mean(last(result_many["posteriors"][:μ])) - μ_real)
    @test error_many < error_few

    # Test free energy computation
    result_with_fe = deployable(
        (x=data,),
        [:μ, :σ],
        iterations=10,
        free_energy=true
    )
    @test haskey(result_with_fe, "posteriors")
    @test haskey(result_with_fe, "free_energy")
    @test haskey(result_with_fe["posteriors"], :μ)
    @test haskey(result_with_fe["posteriors"], :σ)
    @test typeof(collect(result_with_fe["free_energy"])) <: Vector{Real}

    # Test both interfaces with inference parameters
    result_nt = deployable(
        (x=data,),
        [:μ],
        iterations=20,
        free_energy=true
    )
    result_kwargs = deployable(
        data=(x=data,),
        output=[:μ],
        iterations=20,
        free_energy=true
    )
    @test mean(last(result_nt["posteriors"][:μ])) ≈ mean(last(result_kwargs["posteriors"][:μ])) atol = 1e-10

    # Test with returnvars
    result_with_history = deployable(
        data=(x=data,),
        output=[:μ],
        iterations=10,
        returnvars=(μ=KeepEach(), σ=KeepEach())
    )
    @test haskey(result_with_history, "posteriors")
    @test haskey(result_with_history["posteriors"], :μ)
    @test length(result_with_history["posteriors"][:μ]) == 10  # One for each iteration
end
