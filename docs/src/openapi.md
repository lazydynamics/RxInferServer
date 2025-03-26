# [OpenAPI Specification](@id openapi)

RxInfer Server provides a comprehensive OpenAPI (formerly known as Swagger) specification that describes all available REST API endpoints, request/response schemas, and authentication methods. This integration offers several key benefits for developers:

## Benefits for Developers

- **Interactive Documentation**: Access the interactive API documentation, allowing you to explore and test API endpoints directly from your browser. You can explore the API in the following ways:

1. Interact with the stable version of the API using the [Swagger UI](https://petstore.swagger.io/?url=https://server.rxinfer.com/stable/openapi/spec.yaml)
2. Interact with the latest version of the API using the [Swagger UI](https://petstore.swagger.io/?url=https://server.rxinfer.com/dev/openapi/spec.yaml)

- **Code Generation**: Generate client libraries in various programming languages using OpenAPI tools. This enables quick integration with the RxInferServer in your preferred language while maintaining type safety and proper error handling.

- **API Consistency**: The OpenAPI specification serves as a single source of truth for the API, ensuring that both the server implementation and client expectations remain in sync.

- **Type Safety**: Generated client libraries provide type-safe interfaces, reducing runtime errors and improving development experience through better IDE support.

## Client Generation

Generate client libraries using standard OpenAPI tools:

```bash
# Using openapi-generator-cli
openapi-generator-cli generate \
    -i https://server.rxinfer.com/stable/openapi/spec.yaml \
    -g python \
    -o ./client

# Using swagger-codegen
swagger-codegen generate \
    -i https://server.rxinfer.com/stable/openapi/spec.yaml \
    -l python \
    -o ./client
```

Read more about the OpenAPI specification [here](https://swagger.io/specification/).