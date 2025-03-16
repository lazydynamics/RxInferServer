#!/bin/bash

# This script generates Julia server code from the OpenAPI specification

# Ensure we're in the correct directory
cd "$(dirname "$0")"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running. Please start Docker and try again."
  exit 1
fi

echo "Generating Julia server code from OpenAPI specification..."

# Get absolute path to the current directory
CURRENT_DIR=$(pwd)

# Run the OpenAPI Generator for Julia directly with Docker
docker run --rm \
  -v "${CURRENT_DIR}/openapi:/openapi" \
  -v "${CURRENT_DIR}/openapi/server:/openapi/server" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g julia-server \
  -o /openapi/server \
  --additional-properties=packageName=RxInferServerOpenAPI

echo "Code generation complete!"
echo "Generated Julia server code is available in the 'openapi/server' directory."
echo "Do not modify the generated code. Instead, you should implement the API defined in the 'src/RxInferServerOpenAPI.jl' file."