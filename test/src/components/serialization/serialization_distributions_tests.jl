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

@testitem "DistributionsData.MeanCov" setup = [SerializationTestUtils] begin
    using RxInfer

    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: DistributionsData, JSONSerialization

    s = JSONSerialization(distributions_data = DistributionsData.MeanCov)

    @testset "Univariate distributions" begin
        for mean in [-1.0, 0.0, 1.0], variance in [2.0, 4.0]
            # NormalMeanVariance should return mean and variance directly
            @test_json_serialization s NormalMeanVariance(mean, variance) => Dict(
                "type" => "Distribution{Univariate, Continuous}",
                "encoding" => "mean_cov",
                "tag" => "NormalMeanVariance",
                "data" => Dict("mean" => mean, "cov" => variance)
            )

            # NormalMeanPrecision should convert precision to variance
            @test_json_serialization s NormalMeanPrecision(mean, 1 / variance) => Dict(
                "type" => "Distribution{Univariate, Continuous}",
                "encoding" => "mean_cov",
                "tag" => "NormalMeanPrecision",
                "data" => Dict("mean" => mean, "cov" => variance)
            )

            # Gamma should convert shape/rate to mean/variance
            shape = 2.0
            rate = shape / variance
            @test_json_serialization s GammaShapeRate(shape, rate) => Dict(
                "type" => "Distribution{Univariate, Continuous}",
                "encoding" => "mean_cov",
                "tag" => "GammaShapeRate",
                "data" => Dict("mean" => shape / rate, "cov" => shape / rate^2)
            )
        end
    end

    @testset "Multivariate distributions" begin
        for mean in [-1.0, 0.0, 1.0], variance in [2.0, 4.0]
            # MvNormalMeanCovariance should return mean and covariance directly
            μ = [mean, mean]
            Σ = [variance 0; 0 variance]
            @test_json_serialization s MvNormalMeanCovariance(μ, Σ) => Dict(
                "type" => "AbstractMvNormal",
                "encoding" => "mean_cov",
                "tag" => "MvNormalMeanCovariance",
                "data" => Dict(
                    "mean" => μ,
                    "cov" => Dict(
                        "type" => "mdarray",
                        "encoding" => "array_of_arrays",
                        "shape" => [2, 2],
                        "data" => [[variance, 0], [0, variance]]
                    )
                )
            )
        end
    end

    @testset "Mixed distributions" begin
        # Test with a mixture of distributions
        @test_json_serialization s [
            NormalMeanVariance(1.0, 2.0), MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0])
        ] => [
            Dict(
                "type" => "Distribution{Univariate, Continuous}",
                "encoding" => "mean_cov",
                "tag" => "NormalMeanVariance",
                "data" => Dict("mean" => 1.0, "cov" => 2.0)
            ),
            Dict(
                "type" => "AbstractMvNormal",
                "encoding" => "mean_cov",
                "tag" => "MvNormalMeanCovariance",
                "data" => Dict(
                    "mean" => [1.0, 2.0],
                    "cov" => Dict(
                        "type" => "mdarray",
                        "encoding" => "array_of_arrays",
                        "shape" => [2, 2],
                        "data" => [[3.0, 0.0], [0.0, 4.0]]
                    )
                )
            )
        ]
    end
end

@testitem "DistributionsRepr" setup = [SerializationTestUtils] begin
    using RxInfer

    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: DistributionsData, DistributionsRepr, JSONSerialization

    base_transform = DistributionsData.NamedParams

    @testset "All" begin
        s = JSONSerialization(distributions_data = base_transform, distributions_repr = DistributionsRepr.Dict)

        @test_json_serialization s NormalMeanVariance(1.0, 2.0) => Dict(
            "type" => "Distribution{Univariate, Continuous}",
            "encoding" => "named_params",
            "tag" => "NormalMeanVariance",
            "data" => Dict("μ" => 1.0, "v" => 2.0)
        )

        @test_json_serialization s MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0]) => Dict(
            "type" => "AbstractMvNormal",
            "encoding" => "named_params",
            "tag" => "MvNormalMeanCovariance",
            "data" => Dict(
                "μ" => [1.0, 2.0],
                "Σ" => Dict(
                    "type" => "mdarray",
                    "encoding" => "array_of_arrays",
                    "shape" => [2, 2],
                    "data" => [[3.0, 0.0], [0.0, 4.0]]
                )
            )
        )
    end

    @testset "TypeAndTag" begin
        s = JSONSerialization(
            distributions_data = base_transform, distributions_repr = DistributionsRepr.DictTypeAndTag
        )

        @test_json_serialization s NormalMeanVariance(1.0, 2.0) => Dict(
            "type" => "Distribution{Univariate, Continuous}",
            "tag" => "NormalMeanVariance",
            "data" => Dict("μ" => 1.0, "v" => 2.0)
        )

        @test_json_serialization s MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0]) => Dict(
            "type" => "AbstractMvNormal",
            "tag" => "MvNormalMeanCovariance",
            "data" => Dict(
                "μ" => [1.0, 2.0],
                "Σ" => Dict(
                    "type" => "mdarray",
                    "encoding" => "array_of_arrays",
                    "shape" => [2, 2],
                    "data" => [[3.0, 0.0], [0.0, 4.0]]
                )
            )
        )
    end

    @testset "Tag" begin
        s = JSONSerialization(distributions_data = base_transform, distributions_repr = DistributionsRepr.DictTag)

        @test_json_serialization s NormalMeanVariance(1.0, 2.0) =>
            Dict("tag" => "NormalMeanVariance", "data" => Dict("μ" => 1.0, "v" => 2.0))

        @test_json_serialization s MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0]) => Dict(
            "tag" => "MvNormalMeanCovariance",
            "data" => Dict(
                "μ" => [1.0, 2.0],
                "Σ" => Dict(
                    "type" => "mdarray",
                    "encoding" => "array_of_arrays",
                    "shape" => [2, 2],
                    "data" => [[3.0, 0.0], [0.0, 4.0]]
                )
            )
        )
    end

    @testset "Data" begin
        s = JSONSerialization(distributions_data = base_transform, distributions_repr = DistributionsRepr.Data)

        @test_json_serialization s NormalMeanVariance(1.0, 2.0) => Dict("μ" => 1.0, "v" => 2.0)

        @test_json_serialization s MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0]) => Dict(
            "μ" => [1.0, 2.0],
            "Σ" => Dict(
                "type" => "mdarray",
                "encoding" => "array_of_arrays",
                "shape" => [2, 2],
                "data" => [[3.0, 0.0], [0.0, 4.0]]
            )
        )
    end
end

@testitem "It should be possible to convert a string preference of `distributions_repr` to an equivalent enum value" begin
    import RxInferServer.Serialization: DistributionsRepr

    @test DistributionsRepr.from_string("dict") == DistributionsRepr.Dict
    @test DistributionsRepr.from_string("dict_type_and_tag") == DistributionsRepr.DictTypeAndTag
    @test DistributionsRepr.from_string("dict_tag") == DistributionsRepr.DictTag
    @test DistributionsRepr.from_string("data") == DistributionsRepr.Data

    @test DistributionsRepr.from_string("unknown") == DistributionsRepr.Unknown
    @test DistributionsRepr.from_string("blahblah") == DistributionsRepr.Unknown
end

@testitem "to_string and from_string should be inverses of each other" begin
    import RxInferServer.Serialization: DistributionsData, DistributionsRepr

    for preference in DistributionsData.AvailableOptions
        @test DistributionsData.from_string(DistributionsData.to_string(preference)) == preference
    end

    for preference in DistributionsRepr.AvailableOptions
        @test DistributionsRepr.from_string(DistributionsRepr.to_string(preference)) == preference
    end
end

@testitem "Serialization should not throw an error if an unknown preference is used" begin
    using HTTP, JSON
    using RxInfer

    import RxInferServer.Serialization: UnsupportedPreferenceError

    req = HTTP.Request("POST", "test", HTTP.Headers(["Prefer" => "distributions_repr=blahblah"]))
    response = RxInferServer.postprocess_response(req, Dict("distribution" => NormalMeanVariance(1.0, 2.0)))
    @test response.status == 200
end

@testitem "Documentation examples for distribution serialization" setup = [TestUtils] begin
    using HTTP, JSON
    using RxInfer
    using RxInferServer.Serialization: DistributionsData, DistributionsRepr, JSONSerialization

    function get_univariate_distribution(preference)
        d = Dict("distribution" => NormalMeanVariance(1.0, 2.0))
        req = HTTP.Request("POST", "test", HTTP.Headers(["Prefer" => preference]))
        response = RxInferServer.postprocess_response(req, d["distribution"])
        return JSON.parse(String(response.body))
    end

    function get_multivariate_distribution(preference)
        d = Dict("distribution" => MvNormalMeanCovariance([1.0, 2.0], [3.0 0.0; 0.0 4.0]))
        req = HTTP.Request("POST", "test", HTTP.Headers(["Prefer" => preference]))
        response = RxInferServer.postprocess_response(req, d["distribution"])
        return JSON.parse(String(response.body))
    end

    @testset "Distribution representation format examples" begin
        @testset "dict representation" begin
            result = get_univariate_distribution("distributions_repr=dict")
            @test result["type"] == "Distribution{Univariate, Continuous}"
            @test result["encoding"] == "named_params"
            @test result["tag"] == "NormalMeanVariance"
            @test result["data"]["μ"] == 1.0
            @test result["data"]["v"] == 2.0

            result = get_multivariate_distribution("distributions_repr=dict")
            @test result["type"] == "AbstractMvNormal"
            @test result["encoding"] == "named_params"
            @test result["tag"] == "MvNormalMeanCovariance"
            @test result["data"]["μ"] == [1.0, 2.0]
            @test result["data"]["Σ"]["type"] == "mdarray"
            @test result["data"]["Σ"]["shape"] == [2, 2]
            @test result["data"]["Σ"]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end

        @testset "dict_type_and_tag representation" begin
            result = get_univariate_distribution("distributions_repr=dict_type_and_tag")
            @test result["type"] == "Distribution{Univariate, Continuous}"
            @test !haskey(result, "encoding")
            @test result["tag"] == "NormalMeanVariance"
            @test result["data"]["μ"] == 1.0
            @test result["data"]["v"] == 2.0

            result = get_multivariate_distribution("distributions_repr=dict_type_and_tag")
            @test result["type"] == "AbstractMvNormal"
            @test !haskey(result, "encoding")
            @test result["tag"] == "MvNormalMeanCovariance"
            @test result["data"]["μ"] == [1.0, 2.0]
            @test result["data"]["Σ"]["type"] == "mdarray"
            @test result["data"]["Σ"]["shape"] == [2, 2]
            @test result["data"]["Σ"]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end

        @testset "dict_tag representation" begin
            result = get_univariate_distribution("distributions_repr=dict_tag")
            @test !haskey(result, "type")
            @test !haskey(result, "encoding")
            @test result["tag"] == "NormalMeanVariance"
            @test result["data"]["μ"] == 1.0
            @test result["data"]["v"] == 2.0

            result = get_multivariate_distribution("distributions_repr=dict_tag")
            @test !haskey(result, "type")
            @test !haskey(result, "encoding")
            @test result["tag"] == "MvNormalMeanCovariance"
            @test result["data"]["μ"] == [1.0, 2.0]
            @test result["data"]["Σ"]["type"] == "mdarray"
            @test result["data"]["Σ"]["shape"] == [2, 2]
            @test result["data"]["Σ"]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end

        @testset "data representation" begin
            result = get_univariate_distribution("distributions_repr=data")
            @test !haskey(result, "type")
            @test !haskey(result, "encoding")
            @test !haskey(result, "tag")
            @test result["μ"] == 1.0
            @test result["v"] == 2.0

            result = get_multivariate_distribution("distributions_repr=data")
            @test !haskey(result, "type")
            @test !haskey(result, "encoding")
            @test !haskey(result, "tag")
            @test result["μ"] == [1.0, 2.0]
            @test result["Σ"]["type"] == "mdarray"
            @test result["Σ"]["shape"] == [2, 2]
            @test result["Σ"]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end
    end

    @testset "Distribution data encoding examples" begin
        @testset "named_params encoding" begin
            result = get_univariate_distribution("distributions_data=named_params")
            @test result["type"] == "Distribution{Univariate, Continuous}"
            @test result["encoding"] == "named_params"
            @test result["tag"] == "NormalMeanVariance"
            @test result["data"]["μ"] == 1.0
            @test result["data"]["v"] == 2.0

            result = get_multivariate_distribution("distributions_data=named_params")
            @test result["type"] == "AbstractMvNormal"
            @test result["encoding"] == "named_params"
            @test result["tag"] == "MvNormalMeanCovariance"
            @test result["data"]["μ"] == [1.0, 2.0]
            @test result["data"]["Σ"]["type"] == "mdarray"
            @test result["data"]["Σ"]["shape"] == [2, 2]
            @test result["data"]["Σ"]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end

        @testset "params encoding" begin
            result = get_univariate_distribution("distributions_data=params")
            @test result["type"] == "Distribution{Univariate, Continuous}"
            @test result["encoding"] == "params"
            @test result["tag"] == "NormalMeanVariance"
            @test result["data"] == [1.0, 2.0]

            result = get_multivariate_distribution("distributions_data=params")
            @test result["type"] == "AbstractMvNormal"
            @test result["encoding"] == "params"
            @test result["tag"] == "MvNormalMeanCovariance"
            @test result["data"][1] == [1.0, 2.0]
            @test result["data"][2]["type"] == "mdarray"
            @test result["data"][2]["shape"] == [2, 2]
            @test result["data"][2]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end

        @testset "mean_cov encoding" begin
            result = get_univariate_distribution("distributions_data=mean_cov")
            @test result["type"] == "Distribution{Univariate, Continuous}"
            @test result["encoding"] == "mean_cov"
            @test result["tag"] == "NormalMeanVariance"
            @test result["data"]["mean"] == 1.0
            @test result["data"]["cov"] == 2.0

            result = get_multivariate_distribution("distributions_data=mean_cov")
            @test result["type"] == "AbstractMvNormal"
            @test result["encoding"] == "mean_cov"
            @test result["tag"] == "MvNormalMeanCovariance"
            @test result["data"]["mean"] == [1.0, 2.0]
            @test result["data"]["cov"]["type"] == "mdarray"
            @test result["data"]["cov"]["shape"] == [2, 2]
            @test result["data"]["cov"]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end

        @testset "none encoding" begin
            result = get_univariate_distribution("distributions_data=none")
            @test result["type"] == "Distribution{Univariate, Continuous}"
            @test result["encoding"] == "none"
            @test result["tag"] == "NormalMeanVariance"
            @test isnothing(result["data"])

            result = get_multivariate_distribution("distributions_data=none")
            @test result["type"] == "AbstractMvNormal"
            @test result["encoding"] == "none"
            @test result["tag"] == "MvNormalMeanCovariance"
            @test isnothing(result["data"])
        end
    end

    @testset "Combined preferences examples" begin
        @testset "mean_cov with data representation" begin
            result = get_univariate_distribution("distributions_repr=data,distributions_data=mean_cov")
            @test !haskey(result, "type")
            @test !haskey(result, "encoding")
            @test !haskey(result, "tag")
            @test result["mean"] == 1.0
            @test result["cov"] == 2.0

            result = get_multivariate_distribution("distributions_repr=data,distributions_data=mean_cov")
            @test !haskey(result, "type")
            @test !haskey(result, "encoding")
            @test !haskey(result, "tag")
            @test result["mean"] == [1.0, 2.0]
            @test result["cov"]["type"] == "mdarray"
            @test result["cov"]["shape"] == [2, 2]
            @test result["cov"]["data"] == [[3.0, 0.0], [0.0, 4.0]]
        end

        @testset "mean_cov with diagonal covariance" begin
            result = get_multivariate_distribution(
                "distributions_repr=data,distributions_data=mean_cov,mdarray_repr=data,mdarray_data=diagonal"
            )
            @test result["mean"] == [1.0, 2.0]
            @test result["cov"] == [3.0, 4.0]
        end
    end
end
