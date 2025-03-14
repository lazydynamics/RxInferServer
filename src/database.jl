module Database

using Mongoc
using Base.ScopedValues

const MONGODB_URL = get(ENV, "RXINFER_MONGODB_URL", "mongodb://localhost:27017")
const MONGODB_DATABASE_NAME = get(ENV, "RXINFER_MONGODB_DATABASE", "rxinferserver")

const MONGODB_CLIENT = ScopedValue{Union{Nothing, Mongoc.Client}}(nothing)
const MONGODB_DATABASE = ScopedValue{Union{Nothing, Mongoc.Database}}(nothing)

function with_connection(f::F) where {F}
    _client = Mongoc.Client(MONGODB_URL)
    _database = _client[MONGODB_DATABASE_NAME]
    return with(MONGODB_CLIENT => _client, MONGODB_DATABASE => _database) do
        returnval = f()
        Mongoc.destroy!(_client)
        return returnval
    end
end

function client()::Mongoc.Client
    client = MONGODB_CLIENT[]
    if isnothing(client)
        error("Database connection not established. Use `with_connection` to establish a connection.")
    end
    return client::Mongoc.Client
end

function database()::Mongoc.Database
    database = MONGODB_DATABASE[]
    if isnothing(database)
        error("Database not established. Use `with_connection` to establish a connection.")
    end
    return database::Mongoc.Database
end

function collection(name::String)::Mongoc.Collection
    return database()[name]
end

end
