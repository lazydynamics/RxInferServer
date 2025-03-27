@testitem "@expect macro should not return if the result is not nothing" begin
    import RxInferServer: @expect

    function g()
        return 1
    end

    function f()
        @expect g() || 2
    end

    @test f() == 1
end

@testitem "@expect macro should short-circuit and return if the result is nothing" begin
    import RxInferServer: @expect

    function g()
        return nothing
    end

    function f()
        @expect g() || 2
    end

    @test f() == 2
end