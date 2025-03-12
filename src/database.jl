module Database

using Mongoc
using Base.ScopedValues

const MONGODB_URL = get(ENV, "RXINFER_MONGODB_URL", "mongodb://localhost:27017")
const MONGODB_CLIENT = ScopedValue{Union{Nothing, Mongoc.Client}}(nothing)

function with_connection(f::F) where {F}
    return with(MONGODB_CLIENT => Mongoc.Client(MONGODB_URL)) do
        return f()
    end
end

function client()::Mongoc.Client
    client = MONGODB_CLIENT[]
    if isnothing(client)
        error("Database connection not established. Use `with_connection` to establish a connection.")
    end
    return client::Mongoc.Client
end

end