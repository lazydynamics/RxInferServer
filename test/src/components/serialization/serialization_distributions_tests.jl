@testitem "Distributions should throw an error if unknown preference is used" begin
    import RxInfer
    import RxInferServer.Serialization: to_json, JSONSerialization, UnsupportedPreferenceError

    @testset "distributions_data" begin
        s = JSONSerialization(distributions_data = UInt8(123))
        @test_throws UnsupportedPreferenceError to_json(s, RxInfer.NormalMeanVariance(1.0, 2.0))
    end

    @testset "distributions_repr" begin
        s = JSONSerialization(distributions_repr = UInt8(123))
        @test_throws UnsupportedPreferenceError to_json(s, RxInfer.NormalMeanVariance(1.0, 2.0))
    end
end

@testitem "DistributionsData.NamedParams" setup = [SerializationTestUtils] begin
    using RxInfer

    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: DistributionsData, JSONSerialization

    s = JSONSerialization(distributions_data = DistributionsData.NamedParams)

    for mean in [-1.0, 0.0, 1.0], variance in [2.0, 4.0]
        @test_json_serialization s NormalMeanVariance(mean, variance) => Dict(
            "type" => "Distribution{Univariate, Continuous}",
            "encoding" => "named_params",
            "tag" => "NormalMeanVariance",
            "data" => Dict("μ" => mean, "v" => variance)
        )

        @test_json_serialization s NormalMeanPrecision(mean, 1 / variance) => Dict(
            "type" => "Distribution{Univariate, Continuous}",
            "encoding" => "named_params",
            "tag" => "NormalMeanPrecision",
            "data" => Dict("μ" => mean, "w" => 1 / variance)
        )

        @test_json_serialization s MvNormalMeanCovariance([mean, mean], [variance 0; 0 variance]) => Dict(
            "type" => "AbstractMvNormal",
            "encoding" => "named_params",
            "tag" => "MvNormalMeanCovariance",
            "data" => Dict(
                "μ" => [mean, mean],
                "Σ" => Dict(
                    "type" => "mdarray",
                    "encoding" => "array_of_arrays",
                    "shape" => [2, 2],
                    "data" => [[variance, 0], [0, variance]]
                )
            )
        )

        @test_json_serialization s MvNormalMeanPrecision([mean, mean], [1 / variance, 1 / variance]) => Dict(
            "type" => "AbstractMvNormal",
            "encoding" => "named_params",
            "tag" => "MvNormalMeanPrecision",
            "data" => Dict(
                "μ" => [mean, mean],
                "Λ" => Dict(
                    "type" => "mdarray",
                    "encoding" => "array_of_arrays",
                    "shape" => [2, 2],
                    "data" => [[1 / variance, 0], [0, 1 / variance]]
                )
            )
        )
    end
end

@testitem "DistributionsData.Params" setup = [SerializationTestUtils] begin
    using RxInfer

    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: DistributionsData, JSONSerialization

    s = JSONSerialization(distributions_data = DistributionsData.Params)

    for mean in [-1.0, 0.0, 1.0], variance in [2.0, 4.0]
        @test_json_serialization s NormalMeanVariance(mean, variance) => Dict(
            "type" => "Distribution{Univariate, Continuous}",
            "encoding" => "params",
            "tag" => "NormalMeanVariance",
            "data" => [mean, variance]
        )

        @test_json_serialization s NormalMeanPrecision(mean, 1 / variance) => Dict(
            "type" => "Distribution{Univariate, Continuous}",
            "encoding" => "params",
            "tag" => "NormalMeanPrecision",
            "data" => [mean, 1 / variance]
        )

        @test_json_serialization s MvNormalMeanCovariance([mean, mean], [variance 0; 0 variance]) => Dict(
            "type" => "AbstractMvNormal",
            "encoding" => "params",
            "tag" => "MvNormalMeanCovariance",
            "data" => [
                [mean, mean],
                Dict(
                    "type" => "mdarray",
                    "encoding" => "array_of_arrays",
                    "shape" => [2, 2],
                    "data" => [[variance, 0], [0, variance]]
                )
            ]
        )

        @test_json_serialization s MvNormalMeanPrecision([mean, mean], [1 / variance, 1 / variance]) => Dict(
            "type" => "AbstractMvNormal",
            "encoding" => "params",
            "tag" => "MvNormalMeanPrecision",
            "data" => [
                [mean, mean],
                Dict(
                    "type" => "mdarray",
                    "encoding" => "array_of_arrays",
                    "shape" => [2, 2],
                    "data" => [[1 / variance, 0], [0, 1 / variance]]
                )
            ]
        )
    end
end
