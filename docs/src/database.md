# Database

The `Database` module provides functionality for connecting to and interacting with MongoDB databases in RxInferServer.jl.

## Overview

This module uses the [Mongoc.jl](https://github.com/felipenoris/Mongoc.jl) package to provide MongoDB integration. It implements a scoped connection pattern that ensures proper resource cleanup and provides convenient access to database resources.

### Configuration

Read more about the configuration of the database in the [Database Configuration](@ref mongodb-configuration) section.

## Core Functions

```@docs
RxInferServer.Database.with_connection
RxInferServer.Database.client
RxInferServer.Database.database
RxInferServer.Database.collection
RxInferServer.Database.hidden_url
```
