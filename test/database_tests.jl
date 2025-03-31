@testitem "Test database connection (indirect, only with RXINFER_SERVER_MONGODB_URL)" begin
    using Mongoc
    # This test only ensures that the database connection is working
    client = Mongoc.Client(RxInferServer.Database.RXINFER_SERVER_MONGODB_URL())
    ping = Mongoc.ping(client)
    @test isone(ping["ok"])
    # https://github.com/felipenoris/Mongoc.jl/issues/124
    Mongoc.destroy!(client)
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

@testitem "Database connection should fail if the server is not reachable #1" begin
    using Mongoc

    @test_throws RxInferServer.Database.DatabaseFailedConnectionError RxInferServer.Database.with_connection(
        url = "non-existing-url"
    ) do
        @test false
    end

    @test_throws RxInferServer.Database.DatabaseFailedConnectionError RxInferServer.Database.with_connection(
        url = "mongodb://non-existing-host:27017/"
    ) do
        @test false
    end
end

@testitem "Database connection should not fail if asked not to check connection even if the server is not reachable" begin
    using Mongoc
    RxInferServer.Database.with_connection(url = "mongodb://non-existing-host:27017/", check_connection = false) do
        @test true
    end
end

@testitem "DatabaseFailedConnectionError should have a message" begin
    using Mongoc
    err = RxInferServer.Database.DatabaseFailedConnectionError("mongodb://non-existing-host:27017/")
    io = IOBuffer()
    showerror(io, err)
    err_msg = String(take!(io))
    @test occursin("Failed to connect to MongoDB server at mongodb://non-existing-host:27017/", err_msg)
    @test occursin("Potential reasons:", err_msg)
    @test occursin("Database is not running", err_msg)
    @test occursin("use `make docker` to start the Docker compose environment with local MongoDB database.", err_msg)
    @test occursin("Database is not reachable", err_msg)
    @test occursin("Credentials are invalid", err_msg)
    @test occursin("Missing TLS configuration", err_msg)
end

@testitem "DatabaseFailedConnectionError should redact the url even if a simple string is passed" begin
    using Mongoc
    err = RxInferServer.Database.DatabaseFailedConnectionError("mongodb://user:password@non-existing-host:27017/")
    io = IOBuffer()
    showerror(io, err)
    err_msg = String(take!(io))
    @test occursin("mongodb://****:****@non-existing-host:27017/", err_msg)
    @test !occursin("user:password", err_msg)
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

@testitem "Database.RedactedURL should redact the user and password from MongoDB URL" begin
    @test repr(RxInferServer.Database.RedactedURL("mongodb://localhost:27017/?directConnection=true")) ==
        "mongodb://localhost:27017/?directConnection=true"
    @test repr(RxInferServer.Database.RedactedURL("mongodb://user:password@localhost:27017/?directConnection=true")) ==
        "mongodb://****:****@localhost:27017/?directConnection=true"
    @test repr(RxInferServer.Database.RedactedURL("mongodb://user:password@some.server.com")) ==
        "mongodb://****:****@some.server.com"
end

@testitem "Database.inject_tls_ca_file should add TLS CA file to MongoDB URL" begin
    # With empty RXINFER_SERVER_SSL_CA_FILE, the function should automatically 
    # find and use a suitable certificate for remote connections
    withenv("RXINFER_SERVER_SSL_CA_FILE" => "") do
        url = "mongodb://example.com:27017"
        @test occursin("?tlsCAFile=", RxInferServer.Database.inject_tls_ca_file(url))
    end

    # For URLs with existing query parameters, it should append with &
    # rather than ? when automatically discovering certificates
    withenv("RXINFER_SERVER_SSL_CA_FILE" => "") do
        url = "mongodb://example.com:27017?retryWrites=true"
        @test occursin("&tlsCAFile=", RxInferServer.Database.inject_tls_ca_file(url))
    end

    # Localhost connections should remain unchanged, even with 
    # automatic certificate discovery enabled
    withenv("RXINFER_SERVER_SSL_CA_FILE" => "") do
        url = "mongodb://localhost:27017"
        @test RxInferServer.Database.inject_tls_ca_file(url) == url
    end

    # Loopback IP connections should also remain unchanged
    withenv("RXINFER_SERVER_SSL_CA_FILE" => "") do
        url = "mongodb://127.0.0.1:27017"
        @test RxInferServer.Database.inject_tls_ca_file(url) == url
    end

    # URLs that already have a tlsCAFile parameter should remain unchanged,
    # regardless of automatic discovery settings
    withenv("RXINFER_SERVER_SSL_CA_FILE" => "") do
        url = "mongodb://127.0.0.1:27017?tlsCAFile=/existing/ca.pem"
        @test RxInferServer.Database.inject_tls_ca_file(url) == url
    end

    # Test cases using explicitly set CA file path via environment variable,
    # which should take precedence over automatic discovery
    withenv("RXINFER_SERVER_SSL_CA_FILE" => "/path/to/ca.pem") do
        # Localhost connections should remain unchanged even with explicit CA file
        localhost_url = "mongodb://localhost:27017"
        @test RxInferServer.Database.inject_tls_ca_file(localhost_url) == localhost_url

        # Loopback IP connections should remain unchanged
        loopback_url = "mongodb://127.0.0.1:27017"
        @test RxInferServer.Database.inject_tls_ca_file(loopback_url) == loopback_url

        # Remote connections should have the explicit CA file added with ?
        remote_url = "mongodb://example.com:27017"
        @test RxInferServer.Database.inject_tls_ca_file(remote_url) ==
            "mongodb://example.com:27017?tlsCAFile=/path/to/ca.pem"

        # URLs with existing parameters should have CA file appended with &
        remote_url_with_params = "mongodb://example.com:27017?retryWrites=true"
        @test RxInferServer.Database.inject_tls_ca_file(remote_url_with_params) ==
            "mongodb://example.com:27017?retryWrites=true&tlsCAFile=/path/to/ca.pem"

        # URLs that already have a tlsCAFile parameter should remain unchanged
        url_with_ca = "mongodb://example.com:27017?tlsCAFile=/existing/ca.pem"
        @test RxInferServer.Database.inject_tls_ca_file(url_with_ca) == url_with_ca

        # Complex URLs with credentials and multiple parameters
        complex_url = "mongodb+srv://user:password@cluster.mongodb.net/?retryWrites=true&w=majority"
        @test RxInferServer.Database.inject_tls_ca_file(complex_url) ==
            "mongodb+srv://user:password@cluster.mongodb.net/?retryWrites=true&w=majority&tlsCAFile=/path/to/ca.pem"
    end
end

@testitem "Database.RedactedURL should redact tlsCertificateKeyFile path in MongoDB URL" begin
    @test repr(
        RxInferServer.Database.RedactedURL("mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=/tmp/cert.pem")
    ) == "mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=****"

    # Test with tlsCertificateKeyFile in the middle of other parameters
    @test repr(
        RxInferServer.Database.RedactedURL(
            "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=/tmp/cert.pem&retryWrites=true"
        )
    ) == "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=****&retryWrites=true"

    # Test with both credentials and tlsCertificateKeyFile
    @test repr(
        RxInferServer.Database.RedactedURL(
            "mongodb+srv://user:password@cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=/tmp/cert.pem"
        )
    ) == "mongodb+srv://****:****@cluster.mongodb.net/?authSource=%24external&tlsCertificateKeyFile=****"
end

@testitem "Database.RedactedURL should redact tlsCAFile path in MongoDB URL" begin
    # Test with only tlsCAFile
    @test repr(RxInferServer.Database.RedactedURL("mongodb+srv://cluster.mongodb.net/?tlsCAFile=/tmp/ca.pem")) ==
        "mongodb+srv://cluster.mongodb.net/?tlsCAFile=****"

    # Test with tlsCAFile in the middle of other parameters
    @test repr(
        RxInferServer.Database.RedactedURL(
            "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=/tmp/ca.pem&retryWrites=true"
        )
    ) == "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=****&retryWrites=true"

    # Test with both credentials and tlsCAFile
    @test repr(
        RxInferServer.Database.RedactedURL(
            "mongodb+srv://user:password@cluster.mongodb.net/?authSource=%24external&tlsCAFile=/tmp/ca.pem"
        )
    ) == "mongodb+srv://****:****@cluster.mongodb.net/?authSource=%24external&tlsCAFile=****"
end

@testitem "Database.RedactedURL should redact both certificate paths in MongoDB URL" begin
    # Test with both certificate parameters
    @test repr(
        RxInferServer.Database.RedactedURL(
            "mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=/tmp/cert.pem&tlsCAFile=/tmp/ca.pem"
        )
    ) == "mongodb+srv://cluster.mongodb.net/?tlsCertificateKeyFile=****&tlsCAFile=****"

    # Test with both certificate parameters and credentials
    @test repr(
        RxInferServer.Database.RedactedURL(
            "mongodb+srv://user:password@cluster.mongodb.net/?tlsCertificateKeyFile=/tmp/cert.pem&tlsCAFile=/tmp/ca.pem"
        )
    ) == "mongodb+srv://****:****@cluster.mongodb.net/?tlsCertificateKeyFile=****&tlsCAFile=****"

    # Test with both certificate parameters and other parameters
    @test repr(
        RxInferServer.Database.RedactedURL(
            "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=/tmp/ca.pem&retryWrites=true&tlsCertificateKeyFile=/tmp/cert.pem"
        )
    ) ==
        "mongodb+srv://cluster.mongodb.net/?authSource=%24external&tlsCAFile=****&retryWrites=true&tlsCertificateKeyFile=****"
end
