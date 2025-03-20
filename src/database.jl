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
The SSL/TLS CA file path to use for MongoDB connections.
This can be configured using the `RXINFER_SERVER_SSL_CA_FILE` environment variable.
If not specified, the system will try to automatically find a suitable CA certificate.

```julia
# Set SSL CA file path via environment variable
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
"""
function hidden_url(url::String)::String
    result = url

    # Hide username:password
    if contains(url, '@')
        protocol_part, rest = split(url, "://", limit = 2)

        if contains(rest, '@')
            credentials_part, server_part = split(rest, '@', limit = 2)
            result = "$protocol_part://****:****@$server_part"
        end
    end

    # Hide sensitive parameters if URL contains query string
    sensitive_params = ["tlsCertificateKeyFile", "tlsCAFile"]

    if any(param -> contains(result, "$param="), sensitive_params) && contains(result, "?")
        base_url, query_string = split(result, "?", limit = 2)

        # Split query parameters
        query_params = split(query_string, "&")

        # Process each parameter
        for (i, param) in enumerate(query_params)
            for sensitive_param in sensitive_params
                if startswith(param, "$sensitive_param=")
                    key_value = split(param, "=", limit = 2)
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

Injects the TLS CA file into the MongoDB connection URL if it's not already present.
This function adds the tlsCAFile parameter to the URL in the following priority:
1. Uses RXINFER_SERVER_SSL_CA_FILE environment variable if set
2. Automatically finds SSL certificates if the environment variable is empty and the connection is not to localhost
3. Leaves the URL unchanged if it already contains a tlsCAFile parameter or points to localhost/127.0.0.1

# Arguments
- `url::String`: The MongoDB connection URL

# Returns
- `String`: The MongoDB connection URL with tlsCAFile parameter added if needed
"""
function inject_tls_ca_file(url::String)::String
    # If URL already has tlsCAFile or is localhost, don't modify
    if contains(url, "tlsCAFile") || contains(url, "localhost") || contains(url, "127.0.0.1")
        return url
    end

    # Try to get CA file path from environment variable
    tls_ca_file = RXINFER_SERVER_SSL_CA_FILE()

    # If environment variable is empty, try to find certificates automatically
    if isempty(tls_ca_file)
        certificates = find_ssl_certificates()
        if !isempty(certificates["ca_certs"])
            # Use the first CA certificate found
            tls_ca_file = first(certificates["ca_certs"])
            @info "Automatically using CA certificate: $tls_ca_file"
        end
    end

    # If we have a CA file (either from env or auto-discovery), append it to URL
    if !isempty(tls_ca_file)
        url_append_symbol = contains(url, "?") ? "&" : "?"
        return url * url_append_symbol * "tlsCAFile=$tls_ca_file"
    end

    # If no CA file found, return original URL
    return url
end

"""
    find_ssl_certificates()::Dict{String, Vector{String}}

Searches for SSL certificates in default locations based on the operating system.
Returns a dictionary with keys for different certificate types and values as vectors of found file paths.
Certificate locations are prioritized with standard system locations first.

The function searches for:
- CA certificates (trusted root certificates)
- Client certificates (for client authentication)

For Linux systems, it prioritizes locations where certificates are installed via package managers
(e.g., `apt-get install ca-certificates`).

# Returns
- `Dict{String, Vector{String}}`: Dictionary with keys "ca_certs" and "client_certs"
"""
function find_ssl_certificates()::Dict{String, Vector{String}}
    result = Dict{String, Vector{String}}("ca_certs" => String[], "client_certs" => String[])

    # Determine OS
    os_name = if Sys.iswindows()
        "windows"
    elseif Sys.isapple()
        "macos"
    elseif Sys.islinux()
        "linux"
    else
        "unknown"
    end

    # Define search paths based on OS
    ca_cert_paths = String[]
    client_cert_paths = String[]

    if os_name == "windows"
        # Windows certificate locations - prioritize system store
        push!(
            ca_cert_paths,
            "C:\\Windows\\System32\\certmgr.msc",
            "C:\\ProgramData\\Microsoft\\Crypto\\RSA\\MachineKeys",
            "C:\\OpenSSL\\certs",
            joinpath(homedir(), "AppData", "Roaming", "Microsoft", "Crypto", "RSA")
        )
        push!(
            client_cert_paths,
            "C:\\ProgramData\\Microsoft\\Crypto\\RSA\\MachineKeys",
            "C:\\OpenSSL\\certs",
            joinpath(homedir(), "AppData", "Roaming", "Microsoft", "Crypto", "RSA")
        )
    elseif os_name == "macos"
        # macOS certificate locations - prioritize system certs
        push!(
            ca_cert_paths,
            "/etc/ssl/cert.pem",            # Main system bundle
            "/etc/ssl/certs",               # System certs directory
            "/usr/local/etc/openssl/certs", # Homebrew OpenSSL
            "/usr/local/etc/openssl@1.1/certs",
            joinpath(homedir(), "Library", "Application Support", "Certificates")
        )
        push!(
            client_cert_paths,
            "/etc/ssl/certs",
            "/usr/local/etc/openssl/certs",
            "/usr/local/etc/openssl@1.1/certs",
            joinpath(homedir(), "Library", "Application Support", "Certificates")
        )
    elseif os_name == "linux"
        # Linux certificate locations - prioritize standard package manager locations
        # These are typically installed via apt-get install ca-certificates
        push!(
            ca_cert_paths,
            "/etc/ssl/certs/ca-certificates.crt", # Debian/Ubuntu main bundle
            "/etc/ssl/certs",                     # Standard directory 
            "/etc/pki/tls/certs/ca-bundle.crt",   # RHEL/CentOS main bundle
            "/etc/pki/tls/certs",                 # RHEL/CentOS directory
            "/usr/share/ca-certificates"          # Additional certs
        )
        push!(
            client_cert_paths, 
            "/etc/ssl/certs",                    # Standard directory
            "/etc/pki/tls/certs",                # RHEL/CentOS 
            joinpath(homedir(), ".ssl", "certs") # User certs
        )
    end

    # Search for CA certificates
    for path in ca_cert_paths
        if isfile(path) && (endswith(path, ".crt") || endswith(path, ".pem"))
            push!(result["ca_certs"], path)
        elseif isdir(path)
            # Look for .crt and .pem files in the directory
            for file in readdir(path, join = true)
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
            for file in readdir(path, join = true)
                if isfile(file) && (
                    endswith(file, ".crt") ||
                    endswith(file, ".pem") ||
                    endswith(file, ".key") ||
                    endswith(file, ".pfx") ||
                    endswith(file, ".p12")
                )
                    push!(result["client_certs"], file)
                end
            end
        end
    end

    return result
end

end
