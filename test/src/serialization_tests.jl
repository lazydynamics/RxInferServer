@testitem "RxInferServer JSON serialization should not work for custom types" begin
    import RxInferServer.Serialization: to_json, JSONSerialization, UnsupportedTypeSerializationError

    struct CustomTypeToTriggerSerializationError end

    @testset "custom type" begin
        @test_throws UnsupportedTypeSerializationError to_json(
            JSONSerialization(), CustomTypeToTriggerSerializationError()
        )
    end
end

@testitem "UnsupportedTypeSerializationError should have a helpful message" begin
    import RxInferServer.Serialization: UnsupportedTypeSerializationError

    @test occursin(
        "serialization of type IOBuffer is not supported",
        sprint(showerror, UnsupportedTypeSerializationError(IOBuffer))
    )
    @test occursin(
        "serialization of type BigFloat is not supported",
        sprint(showerror, UnsupportedTypeSerializationError(BigFloat))
    )
end

@testmodule SerializationTestUtils begin
    using Test

    import RxInferServer.Serialization: to_json, from_json, JSONSerialization

    to_from_json(value) = from_json(to_json(JSONSerialization(), value))
    to_from_json(s::JSONSerialization, value) = from_json(to_json(s, value))

    # The use for this macro is something like this 
    # @test_json_serialization JSONSerialization() 1       # same as 1 => 1
    # @test_json_serialization JSONSerialization() 1 => 1
    # @test_json_serialization JSONSerialization(mdarray_data = MultiDimensionalArrayData.ArrayOfArrays) [1 2; 3 4] => Dict("type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [2, 2], "data" => [[1, 3], [2, 4]])
    macro test_json_serialization(serialization, value_expected)
        return __test_json_serialization(serialization, value_expected)
    end

    macro test_json_serialization(value_expected)
        return __test_json_serialization(JSONSerialization(), value_expected)
    end

    function __test_json_serialization(serialization, value_expected)
        (input, expected) =
            if isa(value_expected, Expr) && value_expected.head == :call && value_expected.args[1] == :(=>)
                (value_expected.args[2], value_expected.args[3])
            else
                (value_expected, value_expected)
            end

        # This function tests JSON serialization and deserialization for various nested data structures
        # It verifies that the input value can be serialized to JSON and deserialized back to the original value
        # For complex cases, it also tests that the input can be transformed to an expected different value
        ret = quote
            @test SerializationTestUtils.to_from_json($serialization, $input) == $expected
            @test SerializationTestUtils.to_from_json($serialization, [$input]) == [$expected]
            @test SerializationTestUtils.to_from_json($serialization, [[$input]]) == [[$expected]]
            @test SerializationTestUtils.to_from_json($serialization, [[$input, $input]]) == [[$expected, $expected]]
            @test SerializationTestUtils.to_from_json($serialization, [Dict("a" => $input)]) == [Dict("a" => $expected)]
            @test SerializationTestUtils.to_from_json($serialization, [$input, Dict("a" => $input)]) ==
                [$expected, Dict("a" => $expected)]
            @test SerializationTestUtils.to_from_json($serialization, Dict("wrapper" => $input)) ==
                Dict("wrapper" => $expected)
            @test SerializationTestUtils.to_from_json($serialization, Dict("a" => $input, "b" => $input)) ==
                Dict("a" => $expected, "b" => $expected)
            @test SerializationTestUtils.to_from_json($serialization, Dict("wrapper" => Dict("wrapper" => $input))) == Dict("wrapper" => Dict("wrapper" => $expected))
            @test SerializationTestUtils.to_from_json($serialization, Dict("wrapper" => [$input])) ==
                Dict("wrapper" => [$expected])
            @test SerializationTestUtils.to_from_json($serialization, Dict("wrapper" => [[$input]])) ==
                Dict("wrapper" => [[$expected]])
        end

        return esc(ret)
    end
end

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

@testitem "Unknown preference should have a helpful message" begin
    import RxInferServer.Serialization: UnsupportedPreferenceError

    using EnumX

    @enumx SomePreference begin
        Preference1 = 0
        Preference2 = 1
    end

    for scope in (:mdarray_transform, :some_other_preference), preference in (3, 4, 124)
        errmsg = sprint(showerror, UnsupportedPreferenceError(scope, SomePreference, preference))

        @test occursin("unknown preference value `$(preference)` for `$(scope)`", errmsg)
        @test occursin("Available preferences are: Preference1=0 Preference2=1", errmsg)
    end
end

@testitem "Multi-dimensional arrays should throw an error if unknown preference is used" begin
    import RxInferServer.Serialization: to_json, JSONSerialization, UnsupportedPreferenceError

    @testset "mdarray_data" begin
        s = JSONSerialization(mdarray_data = UInt8(123))
        @test_throws UnsupportedPreferenceError to_json(s, [1 2; 3 4])
    end

    @testset "mdarray_repr" begin
        s = JSONSerialization(mdarray_repr = UInt8(123))
        @test_throws UnsupportedPreferenceError to_json(s, [1 2; 3 4])
    end
end

@testitem "MultiDimensionalArrayData.ArrayOfArrays" setup = [SerializationTestUtils] begin
    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization

    s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.ArrayOfArrays)

    @test_json_serialization s [1 2; 3 4] =>
        Dict("type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [2, 2], "data" => [[1, 2], [3, 4]])

    @test_json_serialization s [1 3; 2 4] =>
        Dict("type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [2, 2], "data" => [[1, 3], [2, 4]])

    @test_json_serialization s [1 2 3; 4 5 6] =>
        Dict("type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [2, 3], "data" => [[1, 2, 3], [4, 5, 6]])

    @test_json_serialization s [1 2 3; 4 5 6; 7 8 9] => Dict(
        "type" => "mdarray",
        "encoding" => "array_of_arrays",
        "shape" => [3, 3],
        "data" => [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    )

    @test_json_serialization s [1 2; 3 4; 5 6] => Dict(
        "type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [3, 2], "data" => [[1, 2], [3, 4], [5, 6]]
    )

    @test_json_serialization s [1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 16] => Dict(
        "type" => "mdarray",
        "encoding" => "array_of_arrays",
        "shape" => [4, 4],
        "data" => [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]]
    )

    @test_json_serialization s [1 2 3 4] =>
        Dict("type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [1, 4], "data" => [[1, 2, 3, 4]])
    @test_json_serialization s [1 2 3 4]' =>
        Dict("type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [4, 1], "data" => [[1], [2], [3], [4]])

    @test_json_serialization s [1 3 5; 2 4 6;;; 7 9 11; 8 10 12] => Dict(
        "type" => "mdarray",
        "encoding" => "array_of_arrays",
        "shape" => [2, 3, 2],
        "data" => [[[1, 7], [3, 9], [5, 11]], [[2, 8], [4, 10], [6, 12]]]
    )

    @test_json_serialization s [1 2;;; 3 4;;;; 5 6;;; 7 8] => Dict(
        "type" => "mdarray",
        "encoding" => "array_of_arrays",
        "shape" => [1, 2, 2, 2],
        "data" => [[[[1, 5], [3, 7]], [[2, 6], [4, 8]]]]
    )

    @test_json_serialization s [[1 2;;; 3 4];;;; [5 6];;; [7 8]] => Dict(
        "type" => "mdarray",
        "encoding" => "array_of_arrays",
        "shape" => [1, 2, 2, 2],
        "data" => [[[[1, 5], [3, 7]], [[2, 6], [4, 8]]]]
    )

    # Shouldn't affect the serialization of 1D arrays
    @test_json_serialization s [1, 2, 3, 4] => [1, 2, 3, 4]
end

@testitem "MultiDimensionalArrayData.ReshapeColumnMajor" setup = [SerializationTestUtils] begin
    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization

    s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.ReshapeColumnMajor)

    @test_json_serialization s [1 2; 3 4] =>
        Dict("type" => "mdarray", "encoding" => "reshape_column_major", "shape" => [2, 2], "data" => [1, 3, 2, 4])

    @test_json_serialization s [1 3; 2 4] =>
        Dict("type" => "mdarray", "encoding" => "reshape_column_major", "shape" => [2, 2], "data" => [1, 2, 3, 4])

    @test_json_serialization s [1 2 3; 4 5 6] =>
        Dict("type" => "mdarray", "encoding" => "reshape_column_major", "shape" => [2, 3], "data" => [1, 4, 2, 5, 3, 6])

    @test_json_serialization s [1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 16] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_column_major",
        "shape" => [4, 4],
        "data" => [1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16]
    )

    @test_json_serialization s [1 2 3 4] =>
        Dict("type" => "mdarray", "encoding" => "reshape_column_major", "shape" => [1, 4], "data" => [1, 2, 3, 4])
    @test_json_serialization s [1 2 3 4]' =>
        Dict("type" => "mdarray", "encoding" => "reshape_column_major", "shape" => [4, 1], "data" => [1, 2, 3, 4])

    @test_json_serialization s [1 3 5; 2 4 6;;; 7 9 11; 8 10 12] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_column_major",
        "shape" => [2, 3, 2],
        "data" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    )

    @test_json_serialization s [1 2;;; 3 4;;;; 5 6;;; 7 8] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_column_major",
        "shape" => [1, 2, 2, 2],
        "data" => [1, 2, 3, 4, 5, 6, 7, 8]
    )

    @test_json_serialization s [[1 2;;; 3 4];;;; [5 6];;; [7 8]] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_column_major",
        "shape" => [1, 2, 2, 2],
        "data" => [1, 2, 3, 4, 5, 6, 7, 8]
    )

    # Shouldn't affect the serialization of 1D arrays
    @test_json_serialization s [1, 2, 3, 4] => [1, 2, 3, 4]
end

@testitem "MultiDimensionalArrayData.ReshapeRowMajor" setup = [SerializationTestUtils] begin
    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: MultiDimensionalArrayData, JSONSerialization

    s = JSONSerialization(mdarray_data = MultiDimensionalArrayData.ReshapeRowMajor)

    @test_json_serialization s [1 2; 3 4] =>
        Dict("type" => "mdarray", "encoding" => "reshape_row_major", "shape" => [2, 2], "data" => [1, 2, 3, 4])

    @test_json_serialization s [1 3; 2 4] =>
        Dict("type" => "mdarray", "encoding" => "reshape_row_major", "shape" => [2, 2], "data" => [1, 3, 2, 4])

    @test_json_serialization s [1 2 3; 4 5 6] =>
        Dict("type" => "mdarray", "encoding" => "reshape_row_major", "shape" => [2, 3], "data" => [1, 2, 3, 4, 5, 6])

    @test_json_serialization s [1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 16] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_row_major",
        "shape" => [4, 4],
        "data" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    )

    @test_json_serialization s [1 2 3 4] =>
        Dict("type" => "mdarray", "encoding" => "reshape_row_major", "shape" => [1, 4], "data" => [1, 2, 3, 4])
    @test_json_serialization s [1 2 3 4]' =>
        Dict("type" => "mdarray", "encoding" => "reshape_row_major", "shape" => [4, 1], "data" => [1, 2, 3, 4])

    @test_json_serialization s [1 3 5; 2 4 6;;; 7 9 11; 8 10 12] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_row_major",
        "shape" => [2, 3, 2],
        "data" => [1, 7, 3, 9, 5, 11, 2, 8, 4, 10, 6, 12]
    )

    @test_json_serialization s [1 2;;; 3 4;;;; 5 6;;; 7 8] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_row_major",
        "shape" => [1, 2, 2, 2],
        "data" => [1, 5, 3, 7, 2, 6, 4, 8]
    )

    @test_json_serialization s [[1 2;;; 3 4];;;; [5 6];;; [7 8]] => Dict(
        "type" => "mdarray",
        "encoding" => "reshape_row_major",
        "shape" => [1, 2, 2, 2],
        "data" => [1, 5, 3, 7, 2, 6, 4, 8]
    )

    # Shouldn't affect the serialization of 1D arrays
    @test_json_serialization s [1, 2, 3, 4] => [1, 2, 3, 4]
end

@testitem "MultiDimensionalArrayRepr" setup = [SerializationTestUtils] begin
    import .SerializationTestUtils: to_from_json, @test_json_serialization
    import RxInferServer.Serialization: MultiDimensionalArrayData, MultiDimensionalArrayRepr, JSONSerialization

    base_transform = MultiDimensionalArrayData.ArrayOfArrays

    @testset "All" begin
        s = JSONSerialization(mdarray_data = base_transform, mdarray_repr = MultiDimensionalArrayRepr.Dict)

        @test_json_serialization s [1 2; 3 4] =>
            Dict("type" => "mdarray", "encoding" => "array_of_arrays", "shape" => [2, 2], "data" => [[1, 2], [3, 4]])
    end

    @testset "TypeAndShape" begin
        s = JSONSerialization(mdarray_data = base_transform, mdarray_repr = MultiDimensionalArrayRepr.DictTypeAndShape)

        @test_json_serialization s [1 2; 3 4] =>
            Dict("type" => "mdarray", "shape" => [2, 2], "data" => [[1, 2], [3, 4]])
    end

    @testset "Shape" begin
        s = JSONSerialization(mdarray_data = base_transform, mdarray_repr = MultiDimensionalArrayRepr.DictShape)

        @test_json_serialization s [1 2; 3 4] => Dict("shape" => [2, 2], "data" => [[1, 2], [3, 4]])
    end

    @testset "Data" begin
        s = JSONSerialization(mdarray_data = base_transform, mdarray_repr = MultiDimensionalArrayRepr.Data)

        @test_json_serialization s [1 2; 3 4] => [[1, 2], [3, 4]]
    end
end

@testitem "Serialization of matrices should change based on `Prefer` header" setup = [TestUtils] begin

    # Ask the server for a matrix and return it to the caller
    # The actual place of getting a matrix isn't really important here,
    # so we just create a state space model as an example and get the matrix from it
    # this code can be changed if the model is changed
    function ask_server_for_matrix(f, headers)
        client = TestUtils.TestClient(headers = headers)
        models_api = TestUtils.RxInferClientOpenAPI.ModelsApi(client)

        create_model_instance_request = TestUtils.RxInferClientOpenAPI.CreateModelInstanceRequest(
            model_name = "BlackBoxStateSpaceModel-v1",
            description = "Testing black-box state space model",
            arguments = Dict("state_dimension" => 2)
        )

        response, info = TestUtils.RxInferClientOpenAPI.create_model_instance(models_api, create_model_instance_request)
        instance_id = response.instance_id

        response, info = TestUtils.RxInferClientOpenAPI.get_model_instance_parameters(models_api, instance_id)

        f(response.parameters["A"])

        response, info = TestUtils.RxInferClientOpenAPI.delete_model_instance(models_api, instance_id)
        @test info.status == 200 && response.message == "Model instance deleted successfully"
    end

    @testset "ArrayOfArrays" begin
        ask_server_for_matrix(["Prefer" => "mdarray_data=array_of_arrays"]) do matrix
            @test matrix["type"] == "mdarray"
            @test matrix["encoding"] == "array_of_arrays"
            @test matrix["shape"] == [2, 2]
            @test matrix["data"] == [[1, 2], [3, 4]]
        end
    end
end