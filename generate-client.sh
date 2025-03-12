#!/bin/bash

# This script generates Julia client code from the OpenAPI specification

# Ensure we're in the correct directory
cd "$(dirname "$0")"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running. Please start Docker and try again."
  exit 1
fi

# Stop all running Docker Compose services to prevent conflicts
echo "Stopping all Docker Compose services to prevent code conflicts..."
docker-compose down
echo "Services stopped."

echo "Generating Julia client code from OpenAPI specification..."

# Get absolute path to the current directory
CURRENT_DIR=$(pwd)

# Run the OpenAPI Generator for Julia client directly with Docker
docker run --rm \
  -v "${CURRENT_DIR}/openapi:/openapi" \
  -v "${CURRENT_DIR}/openapi/client:/openapi/client" \
  openapitools/openapi-generator-cli:latest generate \
  -i /openapi/spec.yaml \
  -g julia-client \
  -o /openapi/client \
  --additional-properties=packageName=RxInferClientOpenAPI

echo "Client code generation complete!"
echo "Generated Julia client code is available in the 'openapi/client' directory."
echo "You can now use this client to interact with the RxInfer API."
echo ""
echo "IMPORTANT: Docker Compose services were stopped before generating code."
echo "You will need to restart them manually with: docker-compose up -d" 