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

# Delete both docs and src directories if they exists
rm -rf "${CURRENT_DIR}/client/docs"
rm -rf "${CURRENT_DIR}/client/src"

# Run the OpenAPI Generator for Julia client directly with Docker
docker run --rm \
  -v "${CURRENT_DIR}:/openapi" \
  -v "${CURRENT_DIR}/client:/openapi/client" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g julia-client \
  -o /openapi/client \
  --additional-properties=packageName=RxInferClientOpenAPI

# Remove docs again because the previous command will have created them
# But in a different format
rm -rf "${CURRENT_DIR}/client/docs"

# Generate Markdown documentation
docker run --rm \
  -v "${CURRENT_DIR}:/openapi" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g markdown \
  -o /openapi/client/docs

echo "Client code and documentation generation complete!"
echo "Generated Julia client code is available in the 'openapi/client' directory."
echo "Generated documentation is available in the 'openapi/client/docs' directory."
echo "You can now use this client to interact with the RxInfer API." 