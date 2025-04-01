@testitem "RxInferServer JSON serialization should work for OpenAPI data-types" begin
    import RxInferServer.Serialization: to_json, from_json

    @testset "string" begin
        @test to_json("test") == "\"test\""
        @test to_json("test2") == "\"test2\""
        @test from_json("\"test\"") == "test"
        @test from_json("\"test2\"") == "test2"
    end

    @testset "number" begin
        @test to_json(1.0) == "1.0"
        @test to_json(2.0) == "2.0"
        @test from_json("1.0") == 1.0
        @test from_json("2.0") == 2.0
    end

    @testset "integer" begin
        @test to_json(1) == "1"
        @test to_json(2) == "2"
        @test from_json("1") == 1
        @test from_json("2") == 2
    end

    @testset "boolean" begin
        @test to_json(true) == "true"
        @test to_json(false) == "false"
        @test from_json("true") == true
        @test from_json("false") == false
    end

    @testset "array" begin
        @test to_json([1, 2, 3]) == "[1,2,3]"
        @test to_json([1.0, 2.0, 3.0]) == "[1.0,2.0,3.0]"
        @test from_json("[1,2,3]") == [1, 2, 3]
        @test from_json("[1.0,2.0,3.0]") == [1.0, 2.0, 3.0]
        @test to_json([[1], [2], [3]]) == "[[1],[2],[3]]"
        @test to_json([[[1]], [[2]], [[3]]]) == "[[[1]],[[2]],[[3]]]"
        @test to_json([ "a", "b", "c" ]) == "[\"a\",\"b\",\"c\"]"
        @test from_json("[\"a\",\"b\",\"c\"]") == [ "a", "b", "c" ]
        @test to_json([[1, 2, 3], [4, 5, 6]]) == "[[1,2,3],[4,5,6]]"
        @test from_json("[[1,2,3],[4,5,6]]") == [[1, 2, 3], [4, 5, 6]]
        @test from_json("[[[1]],[[2]],[[3]]]") == [[[1]], [[2]], [[3]]]
    end

    @testset "object" begin
        @test to_json(Dict(:a => 1, :b => 2)) == "{\"a\":1,\"b\":2}"
        @test to_json(Dict("a" => 1, "b" => 2, "c" => 3)) == "{\"c\":3,\"b\":2,\"a\":1}"
        @test from_json("{\"a\":1,\"b\":2}") == Dict("a" => 1, "b" => 2)
        @test from_json("{\"a\":1,\"b\":2,\"c\":3}") == Dict("a" => 1, "b" => 2, "c" => 3)
    end
end

@testitem "RxInferServer JSON serialization should not work for custom types" begin
    import RxInferServer.Serialization: to_json, from_json, UnsupportedTypeSerializationError

    struct CustomTypeToTriggerSerializationError end

    @testset "custom type" begin
        @test_throws UnsupportedTypeSerializationError to_json(CustomTypeToTriggerSerializationError())
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
    import RxInferServer.Serialization: to_json, from_json, SerializationPreferences, UnsupportedPreferenceError

    preferences = SerializationPreferences(mdarray_transform = UInt8(124))

    @test_throws UnsupportedPreferenceError to_json(preferences, [1 2; 3 4])
end

@testitem "Multi-dimensional arrays should be serialized based on the preference: ArrayOfArrays" begin
    import RxInferServer.Serialization:
        to_json, from_json, MultiDimensionalArrayTransformPreference, SerializationPreferences, DefaultSerialization

    preferences = SerializationPreferences(mdarray_transform = MultiDimensionalArrayTransformPreference.ArrayOfArrays)

    @test to_json(preferences, [1 2; 3 4]) == "[[1,3],[2,4]]" # array of arrays is row based by default
    @test to_json(preferences, [1 3; 2 4]) == "[[1,2],[3,4]]"
    @test to_json(preferences, [1 2 3; 4 5 6]) == "[[1,4],[2,5],[3,6]]"
    @test to_json(preferences, [1 2 3; 4 5 6; 7 8 9]) == "[[1,4,7],[2,5,8],[3,6,9]]"
    @test to_json(preferences, [1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 16]) ==
        "[[1,5,9,13],[2,6,10,14],[3,7,11,15],[4,8,12,16]]"
    @test to_json(preferences, [1, 2, 3, 4]') == "[[1],[2],[3],[4]]"

    # Test 3-dimensional tensors
    tensor_3d = zeros(Int, 2, 3, 2)
    tensor_3d[1, 1, 1] = 1
    tensor_3d[2, 1, 1] = 2
    tensor_3d[1, 2, 1] = 3
    tensor_3d[2, 2, 1] = 4
    tensor_3d[1, 3, 1] = 5
    tensor_3d[2, 3, 1] = 6
    tensor_3d[1, 1, 2] = 7
    tensor_3d[2, 1, 2] = 8
    tensor_3d[1, 2, 2] = 9
    tensor_3d[2, 2, 2] = 10
    tensor_3d[1, 3, 2] = 11
    tensor_3d[2, 3, 2] = 12
    
    # 3D tensor should be serialized as array of arrays of arrays
    @test to_json(preferences, tensor_3d) == "[[[1,2],[3,4],[5,6]],[[7,8],[9,10],[11,12]]]"
    
    # Test another 3D tensor with different dimensions
    tensor_3d_2 = zeros(Int, 2, 2, 3)
    tensor_3d_2[1, 1, 1] = 1
    tensor_3d_2[2, 1, 1] = 2
    tensor_3d_2[1, 2, 1] = 3
    tensor_3d_2[2, 2, 1] = 4
    tensor_3d_2[1, 1, 2] = 5
    tensor_3d_2[2, 1, 2] = 6
    tensor_3d_2[1, 2, 2] = 7
    tensor_3d_2[2, 2, 2] = 8
    tensor_3d_2[1, 1, 3] = 9
    tensor_3d_2[2, 1, 3] = 10
    tensor_3d_2[1, 2, 3] = 11
    tensor_3d_2[2, 2, 3] = 12
    
    @test to_json(preferences, tensor_3d_2) == "[[[1,2],[3,4]],[[5,6],[7,8]],[[9,10],[11,12]]]"
end