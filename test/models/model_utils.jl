@testitem "it should be possible to serialize and deserialize a state" begin
    import RxInferServer.Models: serialize_state, deserialize_state

    state = Dict("A" => zeros(2, 2), "v" => 1.0, "c" => [1.0, 2.0])
    serialized_state = serialize_state(state)
    deserialized_state = deserialize_state(serialized_state)
    @test state == deserialized_state
end

@testitem "it should be possible to serialize and deserialize a state with a nested structure" begin
    import RxInferServer.Models: serialize_state, deserialize_state

    state = Dict("A" => Dict("B" => zeros(2, 2)))
    serialized_state = serialize_state(state)
    deserialized_state = deserialize_state(serialized_state)
    @test state == deserialized_state
end

@testitem "it should be possible to serialize and deserialize a state that uses distributions" begin
    using RxInfer
    import RxInferServer.Models: serialize_state, deserialize_state

    state = Dict(
        "A" => MvNormalMeanCovariance(zeros(2), diageye(2)),
        "b" => NormalMeanVariance(0.0, 1.0),
        "g" => GammaShapeRate(1.0, 1.0)
    )
    serialized_state = serialize_state(state)
    deserialized_state = deserialize_state(serialized_state)
    @test state == deserialized_state
end

@testitem "it should be possible to serialize and deserialize parameters" begin
    import RxInferServer.Models: serialize_parameters, deserialize_parameters

    parameters = Dict("A" => zeros(2, 2), "v" => 1.0, "c" => [1.0, 2.0])
    serialized_parameters = serialize_parameters(parameters)
    deserialized_parameters = deserialize_parameters(serialized_parameters)
    @test parameters == deserialized_parameters
end

@testitem "it should be possible to serialize and deserialize parameters with a nested structure" begin
    import RxInferServer.Models: serialize_parameters, deserialize_parameters

    parameters = Dict("A" => Dict("B" => zeros(2, 2)))
    serialized_parameters = serialize_parameters(parameters)
    deserialized_parameters = deserialize_parameters(serialized_parameters)
    @test parameters == deserialized_parameters
end

@testitem "it should be possible to serialize and deserialize a state that uses distributions" begin
    using RxInfer
    import RxInferServer.Models: serialize_parameters, deserialize_parameters

    parameters = Dict(
        "A" => MvNormalMeanCovariance(zeros(2), diageye(2)),
        "b" => NormalMeanVariance(0.0, 1.0),
        "g" => GammaShapeRate(1.0, 1.0)
    )
    serialized_parameters = serialize_parameters(parameters)
    deserialized_parameters = deserialize_parameters(serialized_parameters)
    @test parameters == deserialized_parameters
end
