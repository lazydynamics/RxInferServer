# [Database](@id database)

The `Database` module provides functionality for connecting to and interacting with MongoDB databases in RxInferServer.jl. This module uses the [Mongoc.jl](https://github.com/felipenoris/Mongoc.jl) package to provide MongoDB integration. It implements a scoped connection pattern that ensures proper resource cleanup and provides convenient access to database resources.

## Configuration

Read more about the configuration of the database in the [Database Configuration](@ref mongodb-configuration) section.

## SSL Certificates

When connecting to MongoDB servers, it is often require to provide SSL certificates. RxInferServer will automatically try to find the certificates on your system and append them to the MongoDB connection string when MongoDB connection string does not contain the "localhost" or "127.0.0.1" address. You can manually set the SSL certificates file by setting the [`RxInferServer.Database.RXINFER_SERVER_SSL_CA_FILE`](@ref) environment variable to your own MongoDB connection string. RxInferServer also will not inject the TLS CA file if the MongoDB connection string already contains the `tlsCAFile` parameter.

## API Reference

```@docs
RxInferServer.Database.with_connection
RxInferServer.Database.client
RxInferServer.Database.database
RxInferServer.Database.collection
RxInferServer.Database.find_ssl_certificates
RxInferServer.Database.inject_tls_ca_file
RxInferServer.Database.RedactedURL
RxInferServer.Database.DatabaseFailedConnectionError
```