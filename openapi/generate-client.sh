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

# Set output directory from environment variable or use default
OUTPUT_DIR="${OPENAPI_OUTPUT_DIR:-${CURRENT_DIR}}/client"

# Delete both docs and src directories if they exists
rm -rf "${OUTPUT_DIR}/docs"
rm -rf "${OUTPUT_DIR}/src"

# Run the OpenAPI Generator for Julia client directly with Docker
docker run --rm \
  -v "${CURRENT_DIR}:/openapi" \
  -v "${OUTPUT_DIR}:/openapi/client" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g julia-client \
  -o /openapi/client \
  --additional-properties=packageName=RxInferClientOpenAPI

# Remove docs again because the previous command will have created them
# But in a different format
rm -rf "${OUTPUT_DIR}/docs"

# Generate Markdown documentation
docker run --rm \
  -v "${CURRENT_DIR}:/openapi" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g markdown \
  -o /openapi/client/docs

echo "Client code and documentation generation complete!"
echo "Generated Julia client code is available in '${OUTPUT_DIR}'"
echo "Generated documentation is available in '${OUTPUT_DIR}/docs'"
echo "You can now use this client to interact with the RxInfer API." 