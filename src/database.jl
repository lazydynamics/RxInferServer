module Database

using Mongoc
using Base.ScopedValues

"""
The MongoDB connection URL for the server.
This can be configured using the `RXINFER_SERVER_MONGODB_URL` environment variable.
Defaults to `mongodb://localhost:27017` if not specified.

```julia
# Set MongoDB URL via environment variable
ENV["RXINFER_SERVER_MONGODB_URL"] = "mongodb://user:password@host:port/database"
RxInferServer.serve()
```
"""
RXINFER_SERVER_MONGODB_URL() = get(ENV, "RXINFER_SERVER_MONGODB_URL", "mongodb://localhost:27017")

"""
The MongoDB database name to use.
This can be configured using the `RXINFER_SERVER_MONGODB_DATABASE` environment variable.
Defaults to `rxinferserver` if not specified.

```julia
# Set MongoDB database name via environment variable
ENV["RXINFER_SERVER_MONGODB_DATABASE"] = "my-database"
RxInferServer.serve()
```
"""
RXINFER_SERVER_MONGODB_DATABASE() = get(ENV, "RXINFER_SERVER_MONGODB_DATABASE", "rxinferserver")

const MONGODB_CLIENT = ScopedValue{Mongoc.Client}()
const MONGODB_DATABASE = ScopedValue{Mongoc.Database}()

"""
    with_connection(f::F; url::String = RXINFER_SERVER_MONGODB_URL(), database::String = RXINFER_SERVER_MONGODB_DATABASE(), check_connection::Bool = true) where {F}

Establishes a connection to the MongoDB database and executes the given function with the connection and database scoped.
This function automatically handles cleanup of MongoDB resources by destroying the client when the provided function completes.

# Arguments
- `f::F`: The function to execute with the database connection.
- `url::String`: The URL of the MongoDB server.
- `database::String`: The name of the database to use.

```julia
with_connection(f; url = RXINFER_SERVER_MONGODB_URL(), database = RXINFER_SERVER_MONGODB_DATABASE(), check_connection = true) do 
    # Your code here
    client = Database.client()
    database = Database.database()
    collection = Database.collection("users")
end
```

See also [`RxInferServer.Database.client`](@ref), [`RxInferServer.Database.database`](@ref), [`RxInferServer.Database.collection`](@ref).
"""
function with_connection(
    f::F;
    url::String = RXINFER_SERVER_MONGODB_URL(),
    database::String = RXINFER_SERVER_MONGODB_DATABASE(),
    check_connection::Bool = true
) where {F}
    _client = Mongoc.Client(url)::Mongoc.Client
    _database = _client[database]::Mongoc.Database
    _hidden_url = hidden_url(url)
    if check_connection
        try
            ping = Mongoc.ping(_client)
            if !isone(ping["ok"])
                error(lazy"Failed to connect to MongoDB server at $_hidden_url")
            end
        catch e
            @error lazy"Failed to connect to MongoDB server at $_hidden_url. Is the server running? If running locally, use `make docker` to start the Docker compose environment with local MongoDB database."
            rethrow(e)
        end
    end
    return with(MONGODB_CLIENT => _client, MONGODB_DATABASE => _database) do
        returnval = f()
        Mongoc.destroy!(_client)
        return returnval
    end
end

"""
    client()::Mongoc.Client

Returns the current database client. Throws an error if called outside of a `with_connection` block.

See also [`RxInferServer.Database.with_connection`](@ref), [`RxInferServer.Database.database`](@ref), [`RxInferServer.Database.collection`](@ref).
"""
function client()::Mongoc.Client
    client = @inline Base.ScopedValues.get(MONGODB_CLIENT)
    return @something client error(
        "Database connection not established. Use `with_connection` to establish a connection."
    )
end

"""
    database()::Mongoc.Database

Returns the current database. Throws an error if called outside of a `with_connection` block.

See also [`RxInferServer.Database.client`](@ref), [`RxInferServer.Database.with_connection`](@ref), [`RxInferServer.Database.collection`](@ref).
"""
function database()::Mongoc.Database
    database = @inline Base.ScopedValues.get(MONGODB_DATABASE)
    return @something database error("Database not established. Use `with_connection` to establish a connection.")
end

"""
    collection(name::String)::Mongoc.Collection

Returns the collection with the given name from the current database. Throws an error if called outside of a `with_connection` block.

See also [`RxInferServer.Database.client`](@ref), [`RxInferServer.Database.database`](@ref), [`RxInferServer.Database.with_connection`](@ref).
"""
function collection(name::String)::Mongoc.Collection
    return database()[name]
end

"""
    hidden_url(url::String)::String

Returns the MongoDB URL with username and password hidden for logging and display purposes.
If the URL contains credentials (username:password), they will be replaced with "****:****".

# Arguments
- `url::String`: The MongoDB connection URL

# Examples
```julia
hidden_url("mongodb://user:password@localhost:27017") # returns "mongodb://****:****@localhost:27017"
hidden_url("mongodb://localhost:27017") # returns "mongodb://localhost:27017"
```
"""
function hidden_url(url::String)::String
    if !contains(url, '@')
        return url
    end

    protocol_part, rest = split(url, "://", limit = 2)

    if contains(rest, '@')
        credentials_part, server_part = split(rest, '@', limit = 2)
        return "$protocol_part://****:****@$server_part"
    end

    return url
end

end
