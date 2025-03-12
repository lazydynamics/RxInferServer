@testitem "Test database connection (indirect, only with MONGODB_URL)" begin
    using Mongoc
    # This test only ensures that the database connection is working
    client = Mongoc.Client(RxInferServer.Database.MONGODB_URL)
    ping = Mongoc.ping(client)
    @test isone(ping["ok"])
end

@testitem "Test database connection (direct, sync)" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        ping = Mongoc.ping(RxInferServer.Database.client())
        @test isone(ping["ok"])
    end
end

@testitem "Test database connection (direct, async)" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        result1 = Threads.@spawn begin
            client = RxInferServer.Database.client()
            ping = Mongoc.ping(client)
            isone(ping["ok"])
        end
        result2 = Threads.@spawn begin
            client = RxInferServer.Database.client()
            ping = Mongoc.ping(client)
            isone(ping["ok"])
        end
        @test fetch(result1)
        @test fetch(result2)
    end
end

@testitem "Database connection outside of `with_connection` should fail" begin
    @test_throws "Database connection not established" RxInferServer.Database.client()
end