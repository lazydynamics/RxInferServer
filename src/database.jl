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

"""
The path to the SSL CA file to use for the MongoDB connection.
This can be configured using the `RXINFER_SERVER_SSL_CA_FILE` environment variable.
Defaults to an empty string if not specified.

If not specified and the MongoDB connection string does not contain the "localhost" or "127.0.0.1" address, 
RxInferServer will try to find the SSL CA file in the default locations based on the operating system using 
the [`RxInferServer.Database.find_ssl_certificates`](@ref) function and inject it using the [`RxInferServer.Database.inject_tls_ca_file`](@ref) function.

!!! note
    This setting is ignored if the MongoDB connection string already contains the `tlsCAFile` parameter.

```julia
ENV["RXINFER_SERVER_SSL_CA_FILE"] = "/path/to/ca.pem"
RxInferServer.serve()
```
"""
RXINFER_SERVER_SSL_CA_FILE() = get(ENV, "RXINFER_SERVER_SSL_CA_FILE", "")

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
    _url_with_tls = inject_tls_ca_file(url)
    _client = Mongoc.Client(_url_with_tls)::Mongoc.Client
    _database = _client[database]::Mongoc.Database
    _hidden_url = hidden_url(_url_with_tls)
    @info "Connecting to MongoDB server at $_hidden_url"
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
    @info "Connected to MongoDB server at $_hidden_url"
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

Returns the MongoDB URL with sensitive information hidden for logging and display purposes.
If the URL contains credentials (username:password), they will be replaced with "****:****".
Additionally, sensitive query parameters like `tlsCertificateKeyFile` and `tlsCAFile` will have their values hidden.

# Arguments
- `url::String`: The MongoDB connection URL

# Examples
```julia
hidden_url("mongodb://user:password@localhost:27017") # returns "mongodb://****:****@localhost:27017"
hidden_url("mongodb://localhost:27017") # returns "mongodb://localhost:27017"
hidden_url("mongodb+srv://host.mongodb.net/?tlsCertificateKeyFile=/path/to/cert.pem") # returns "mongodb+srv://host.mongodb.net/?tlsCertificateKeyFile=****"
hidden_url("mongodb+srv://host.mongodb.net/?tlsCAFile=/path/to/ca.pem") # returns "mongodb+srv://host.mongodb.net/?tlsCAFile=****"
```
"""
function hidden_url(url::String)::String
    result = url
    
    # Hide username:password
    if contains(url, '@')
        protocol_part, rest = split(url, "://", limit=2)
        
        if contains(rest, '@')
            credentials_part, server_part = split(rest, '@', limit=2)
            result = "$protocol_part://****:****@$server_part"
        end
    end
    
    # Hide sensitive parameters if URL contains query string
    sensitive_params = ["tlsCertificateKeyFile", "tlsCAFile"]
    
    if any(param -> contains(result, "$param="), sensitive_params) && contains(result, "?")
        base_url, query_string = split(result, "?", limit=2)
        
        # Split query parameters
        query_params = split(query_string, "&")
        
        # Process each parameter
        for (i, param) in enumerate(query_params)
            for sensitive_param in sensitive_params
                if startswith(param, "$sensitive_param=")
                    key_value = split(param, "=", limit=2)
                    if length(key_value) == 2
                        query_params[i] = "$(key_value[1])=****"
                    end
                    break
                end
            end
        end
        
        # Reassemble URL
        result = base_url * "?" * join(query_params, "&")
    end
    
    return result
end

"""
    inject_tls_ca_file(url::String)::String

Injects the TLS CA file into the URL if it is not already present.
"""
function inject_tls_ca_file(url::String)::String
    tls_ca_file = RXINFER_SERVER_SSL_CA_FILE()
    if isempty(tls_ca_file) || contains(url, "localhost") || contains(url, "127.0.0.1") || !contains(url, "tlsCAFile")
        return url
    end
    url_append_symbol = contains(url, "?") ? "&" : "?"
    return url * url_append_symbol * "tlsCAFile=$tls_ca_file"
end

"""
    find_ssl_certificates()::Dict{String, Vector{String}}

Searches for SSL certificates in default locations based on the operating system.
Returns a dictionary with keys for different certificate types and values as vectors of found file paths.

The function searches for:
- CA certificates (trusted root certificates)
- Client certificates (for client authentication)

# Returns
- `Dict{String, Vector{String}}`: Dictionary with keys "ca_certs" and "client_certs"
"""
function find_ssl_certificates()::Dict{String, Vector{String}}
    result = Dict{String, Vector{String}}(
        "ca_certs" => String[],
        "client_certs" => String[]
    )
    
    # Determine OS
    os_name = Sys.iswindows() ? "windows" : 
              Sys.isapple() ? "macos" : 
              Sys.islinux() ? "linux" : "unknown"
    
    # Define search paths based on OS
    ca_cert_paths = String[]
    client_cert_paths = String[]
    
    if os_name == "windows"
        # Windows certificate locations
        push!(ca_cert_paths, 
            "C:\\Windows\\System32\\certmgr.msc",
            "C:\\ProgramData\\Microsoft\\Crypto\\RSA\\MachineKeys",
            joinpath(homedir(), "AppData", "Roaming", "Microsoft", "Crypto", "RSA"),
            "C:\\OpenSSL\\certs"
        )
        push!(client_cert_paths,
            "C:\\ProgramData\\Microsoft\\Crypto\\RSA\\MachineKeys",
            joinpath(homedir(), "AppData", "Roaming", "Microsoft", "Crypto", "RSA"),
            "C:\\OpenSSL\\certs"
        )
    elseif os_name == "macos"
        # macOS certificate locations
        push!(ca_cert_paths, 
            "/etc/ssl/certs",
            "/etc/ssl/cert.pem",
            joinpath(homedir(), "Library", "Application Support", "Certificates"),
            "/usr/local/etc/openssl/certs",
            "/usr/local/etc/openssl@1.1/certs"
        )
        push!(client_cert_paths,
            joinpath(homedir(), "Library", "Application Support", "Certificates"),
            "/usr/local/etc/openssl/certs",
            "/usr/local/etc/openssl@1.1/certs",
            "/etc/ssl/certs"
        )
    elseif os_name == "linux"
        # Linux certificate locations
        push!(ca_cert_paths, 
            "/etc/ssl/certs",
            "/etc/ssl/certs/ca-certificates.crt",
            "/etc/pki/tls/certs",
            "/etc/pki/tls/certs/ca-bundle.crt",
            "/usr/share/ca-certificates"
        )
        push!(client_cert_paths,
            "/etc/ssl/certs",
            "/etc/pki/tls/certs",
            joinpath(homedir(), ".ssl", "certs")
        )
    end
    
    # Search for CA certificates
    for path in ca_cert_paths
        if isfile(path) && (endswith(path, ".crt") || endswith(path, ".pem"))
            push!(result["ca_certs"], path)
        elseif isdir(path)
            # Look for .crt and .pem files in the directory
            for file in readdir(path, join=true)
                if isfile(file) && (endswith(file, ".crt") || endswith(file, ".pem"))
                    push!(result["ca_certs"], file)
                end
            end
        end
    end
    
    # Search for client certificates
    for path in client_cert_paths
        if isfile(path) && (endswith(path, ".crt") || endswith(path, ".pem") || endswith(path, ".key"))
            push!(result["client_certs"], path)
        elseif isdir(path)
            # Look for .crt, .pem, and .key files in the directory
            for file in readdir(path, join=true)
                if isfile(file) && (endswith(file, ".crt") || endswith(file, ".pem") || endswith(file, ".key") || endswith(file, ".pfx") || endswith(file, ".p12"))
                    push!(result["client_certs"], file)
                end
            end
        end
    end
    
    return result
end

end
