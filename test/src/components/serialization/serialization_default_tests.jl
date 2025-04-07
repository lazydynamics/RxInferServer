@testitem "RxInferServer JSON serialization should work for OpenAPI data-types" setup = [SerializationTestUtils] begin
    import .SerializationTestUtils: to_from_json, @test_json_serialization
    using Dates, TimeZones

    @testset "string" begin
        @test_json_serialization "test"
        @test_json_serialization "test2"
    end

    @testset "string / datetime" begin
        @test_json_serialization DateTime("2016-04-13T00:00:00") => "2016-04-13T00:00:00"
        @test_json_serialization ZonedDateTime(DateTime("2016-04-13T00:00:00"), tz"UTC") => "2016-04-13T00:00:00+00:00"
        @test_json_serialization ZonedDateTime(2021, 1, 1, 0, 0, 0, 0, tz"UTC") => "2021-01-01T00:00:00+00:00"
    end

    @testset "number" begin
        @test_json_serialization 1.0
        @test_json_serialization 2.0
    end

    @testset "integer" begin
        @test_json_serialization 1
        @test_json_serialization 2
    end

    @testset "boolean" begin
        @test_json_serialization true
        @test_json_serialization false
    end

    @testset "array" begin
        @test_json_serialization [1, 2, 3]
        @test_json_serialization [1.0, 2.0, 3.0]
        @test_json_serialization [[1], [2], [3]]
        @test_json_serialization [[[1]], [[2]], [[3]]]
        @test_json_serialization ["a", "b", "c"]
        @test_json_serialization [[1, 2, 3], [4, 5, 6]]
        @test_json_serialization [[[1]], [[2]], [[3]]]
        @test_json_serialization (1, 2, 3) => [1, 2, 3]
    end

    @testset "object" begin
        @test_json_serialization Dict("a" => 1, "b" => 2, "c" => 3)
        @test_json_serialization Dict(:a => 1, :b => 2) => Dict("a" => 1, "b" => 2)
        @test_json_serialization (a = 1, b = 2) => Dict("a" => 1, "b" => 2)
    end

    @testset "missing" begin
        @test_json_serialization missing => nothing
        @test_json_serialization nothing => nothing
    end
end
