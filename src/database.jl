module Database

using Mongoc
using Base.ScopedValues

const MONGODB_URL = get(ENV, "RXINFER_MONGODB_URL", "mongodb://localhost:27017")
const MONGODB_DATABASE_NAME = get(ENV, "RXINFER_MONGODB_DATABASE", "rxinferserver")

const MONGODB_CLIENT = ScopedValue{Mongoc.Client}()
const MONGODB_DATABASE = ScopedValue{Mongoc.Database}()

function with_connection(f::F) where {F}
    _client = Mongoc.Client(MONGODB_URL)::Mongoc.Client
    _database = _client[MONGODB_DATABASE_NAME]::Mongoc.Database
    return with(MONGODB_CLIENT => _client, MONGODB_DATABASE => _database) do
        returnval = f()
        Mongoc.destroy!(_client)
        return returnval
    end
end

function client()::Mongoc.Client
    client = @inline Base.ScopedValues.get(MONGODB_CLIENT)
    return @something client error("Database connection not established. Use `with_connection` to establish a connection.")
end

function database()::Mongoc.Database
    database = @inline Base.ScopedValues.get(MONGODB_DATABASE)
    return @something database error("Database not established. Use `with_connection` to establish a connection.")
end

function collection(name::String)::Mongoc.Collection
    return database()[name]
end

end
