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

@testitem "Unknown preference should have a helpful message" begin
    import RxInferServer.Serialization: UnsupportedPreferenceError

    module SomePreference
    const Preference1 = 0
    const Preference2 = 1
    const Preference3 = 2

    const OptionName = "some_preference"
    const AvailableOptions = (Preference1, Preference2, Preference3)

    function to_string(preference)
        if preference == Preference1
            return "preference_1"
        elseif preference == Preference2
            return "preference_2"
        elseif preference == Preference3
            return "preference_3"
        else
            return "unknown"
        end
    end
    end

    for options in (SomePreference,), option in (3, 4, 124)
        errmsg = sprint(showerror, UnsupportedPreferenceError(option, options))

        @test occursin("unknown preference `$(option)` for `some_preference`", errmsg)
        @test occursin("Available preferences are `preference_1`, `preference_2` and `preference_3`", errmsg)
    end
end
