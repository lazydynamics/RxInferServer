@testitem "Test database connection (indirect, only with RXINFER_SERVER_MONGODB_URL)" begin
    using Mongoc
    # This test only ensures that the database connection is working
    client = Mongoc.Client(RxInferServer.Database.RXINFER_SERVER_MONGODB_URL())
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

@testitem "Database connection should fail if the server is not reachable" begin
    using Mongoc
    @test_throws "Invalid URI Schema" RxInferServer.Database.with_connection(url = "non-existing-url") do
        @test false
    end
    @test_throws "No suitable servers found" RxInferServer.Database.with_connection(
        url = "mongodb://non-existing-host:27017"
    ) do
        @test false
    end
end

@testitem "Database connection outside of `with_connection` should fail" begin
    @test_throws "Database connection not established" RxInferServer.Database.client()
end

@testitem "`with_connection` should connect to the default database from `ENV`" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        client = RxInferServer.Database.client()
        database_env = RxInferServer.Database.RXINFER_SERVER_MONGODB_DATABASE()
        @test client[database_env].name == RxInferServer.Database.database().name
    end
end

@testitem "Database.collection should return a writable collection" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        collection = RxInferServer.Database.collection("database_tests")
        @test collection isa Mongoc.Collection

        # Insert a document
        document = Mongoc.BSON("name" => "test", "value" => 1)
        insert_result = Mongoc.insert_one(collection, document)
        @test insert_result.reply["insertedCount"] == 1
        @test insert_result.inserted_oid isa Mongoc.BSONObjectId

        # Query the document
        query = Mongoc.BSON("name" => "test")
        result = Mongoc.find_one(collection, query)
        @test result["value"] == 1

        # Update the document
        update = Mongoc.BSON("\$set" => Mongoc.BSON("value" => 2))
        update_result = Mongoc.update_one(collection, query, update)
        @test update_result["modifiedCount"] == 1

        # Delete the document
        delete_result = Mongoc.delete_one(collection, query)
        @test delete_result["deletedCount"] == 1

        # Drop the collection
        Mongoc.drop(collection)

        # Check that the collection is empty
        result = Mongoc.find_one(collection, query)
        @test result === nothing
    end
end

@testitem "Database.hidden_url should  hide the user and password from MongoDB URL" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        @test RxInferServer.Database.hidden_url("mongodb://localhost:27017/?directConnection=true") ==
            "mongodb://localhost:27017/?directConnection=true"
        @test RxInferServer.Database.hidden_url("mongodb://user:password@localhost:27017/?directConnection=true") ==
            "mongodb://****:****@localhost:27017/?directConnection=true"
        @test RxInferServer.Database.hidden_url("mongodb://user:password@some.server.com") ==
            "mongodb://****:****@some.server.com"
    end
end

@testitem "Database.hidden_url should hide tlsCertificateKeyFile path in MongoDB URL" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        # Test with only tlsCertificateKeyFile
        @test RxInferServer.Database.hidden_url("mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=/tmp/cert.pem") == 
            "mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=****"
        
        # Test with tlsCertificateKeyFile in the middle of other parameters
        @test RxInferServer.Database.hidden_url("mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=/tmp/cert.pem&retryWrites=true") == 
            "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=****&retryWrites=true"
        
        # Test with both credentials and tlsCertificateKeyFile
        @test RxInferServer.Database.hidden_url("mongodb+srv://user:password@cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=/tmp/cert.pem") == 
            "mongodb+srv://****:****@cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=****"
    end
end

@testitem "Database.hidden_url should hide tlsCAFile path in MongoDB URL" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        # Test with only tlsCAFile
        @test RxInferServer.Database.hidden_url("mongodb+srv://cluster.mongodb.net/?tlsCAFile=/tmp/ca.pem") == 
            "mongodb+srv://cluster.mongodb.net/?tlsCAFile=****"
        
        # Test with tlsCAFile in the middle of other parameters
        @test RxInferServer.Database.hidden_url("mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=/tmp/ca.pem&retryWrites=true") == 
            "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=****&retryWrites=true"
        
        # Test with both credentials and tlsCAFile
        @test RxInferServer.Database.hidden_url("mongodb+srv://user:password@cluster.mongodb.net/?authSource=%24external&tlsCAFile=/tmp/ca.pem") == 
            "mongodb+srv://****:****@cluster.mongodb.net/?authSource=%24external&tlsCAFile=****"
    end
end

@testitem "Database.hidden_url should hide both certificate paths in MongoDB URL" begin
    using Mongoc
    RxInferServer.Database.with_connection() do
        # Test with both certificate parameters
        @test RxInferServer.Database.hidden_url(
            "mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=/tmp/cert.pem&tlsCAFile=/tmp/ca.pem"
        ) == "mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=****&tlsCAFile=****"
        
        # Test with both certificate parameters and credentials
        @test RxInferServer.Database.hidden_url(
            "mongodb+srv://user:password@cluster.mongodb.net/?tlsCertificateKeyFile=/tmp/cert.pem&tlsCAFile=/tmp/ca.pem"
        ) == "mongodb+srv://****:****@cluster.mongodb.net/?tlsCertificateKeyFile=****&tlsCAFile=****"
        
        # Test with both certificate parameters and other parameters
        @test RxInferServer.Database.hidden_url(
            "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=/tmp/ca.pem&retryWrites=true&tlsCertificateKeyFile=/tmp/cert.pem"
        ) == "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=****&retryWrites=true&tlsCertificateKeyFile=****" 
    end
end
