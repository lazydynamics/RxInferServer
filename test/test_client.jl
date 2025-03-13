@testmodule TestClient begin
    using Test, RxInferServer
    using Base.ScopedValues

    import RxInferServer: Client

    _client = ScopedValue{Union{Client, Nothing}}(nothing)

    abstract type AbstractTestClient end

    struct Unauthorized{C} <: AbstractTestClient
        call::C
    end

    function __unauthorized_call(api::Symbol)
    end
end
