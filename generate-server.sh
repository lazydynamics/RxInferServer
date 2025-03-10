#!/bin/bash

# This script generates Julia server code from the OpenAPI specification

# Ensure we're in the correct directory
cd "$(dirname "$0")"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running. Please start Docker and try again."
  exit 1
fi

# Check if our containers are running
if ! docker-compose ps | grep -q "swagger-editor"; then
  echo "Starting Docker Compose services..."
  docker-compose up -d
  sleep 5
fi

echo "Generating Julia server code from OpenAPI specification..."

# Run the OpenAPI Generator for Julia
docker-compose exec openapi-generator \
  /usr/local/bin/docker-entrypoint.sh generate \
  -i /openapi/spec.yaml \
  -g julia-server \
  -o /openapi/server \
  --additional-properties=packageName=RxInferServerOpenAPI

echo "Code generation complete!"
echo "Generated Julia server code is available in the 'openapi/server' directory."
echo ""
echo "You can access the Swagger Editor at http://localhost:8080"
echo "to view and modify the OpenAPI specification." 