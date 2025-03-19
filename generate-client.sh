#!/bin/bash

# This script generates Julia client code from the OpenAPI specification

# Ensure we're in the correct directory
cd "$(dirname "$0")"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running. Please start Docker and try again."
  exit 1
fi

echo "Generating Julia client code and documentation from OpenAPI specification..."

# Get absolute path to the current directory
CURRENT_DIR=$(pwd)

# Create documentation directory if it doesn't exist
mkdir -p "${CURRENT_DIR}/openapi/docs/client"

# Run the OpenAPI Generator for Julia client directly with Docker
docker run --rm \
  -v "${CURRENT_DIR}/openapi:/openapi" \
  -v "${CURRENT_DIR}/openapi/client:/openapi/client" \
  -v "${CURRENT_DIR}/openapi/docs/client:/openapi/docs/client" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g julia-client \
  -o /openapi/client \
  --additional-properties=packageName=RxInferClientOpenAPI

# Generate Markdown documentation
# Remove existing docs directory if it exists
rm -rf "${CURRENT_DIR}/openapi/client/docs"

docker run --rm \
  -v "${CURRENT_DIR}/openapi:/openapi" \
  -v "${CURRENT_DIR}/openapi/docs/client:/openapi/docs/client" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g markdown \
  -o /openapi/client/docs

echo "Client code and documentation generation complete!"
echo "Generated Julia client code is available in the 'openapi/client' directory."
echo "Generated documentation is available in the 'openapi/docs/client' directory."
echo "You can now use this client to interact with the RxInfer API." 


echo "Generating Python client code and documentation from OpenAPI specification..."

# Get absolute path to the current directory
CURRENT_DIR=$(pwd)

# Create documentation directory if it doesn't exist
mkdir -p "${CURRENT_DIR}/openapi/docs/client_python"

# Run the OpenAPI Generator for Julia client directly with Docker
docker run --rm \
  -v "${CURRENT_DIR}/openapi:/openapi" \
  -v "${CURRENT_DIR}/openapi/client_python:/openapi/client_python" \
  -v "${CURRENT_DIR}/openapi/docs/client_python:/openapi/docs/client_python" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g python \
  -o /openapi/client_python \
  --additional-properties=packageName=RxInferClientOpenAPI

# Generate Markdown documentation
# Remove existing docs directory if it exists
rm -rf "${CURRENT_DIR}/openapi/client_python/docs"

docker run --rm \
  -v "${CURRENT_DIR}/openapi:/openapi" \
  -v "${CURRENT_DIR}/openapi/docs/client_python:/openapi/docs/client_python" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g markdown \
  -o /openapi/client_python/docs

echo "Client code and documentation generation complete!"
echo "Generated Python client code is available in the 'openapi/client_python' directory."
echo "Generated documentation is available in the 'openapi/docs/client_python' directory."
echo "You can now use this client to interact with the RxInfer API." 

