#!/bin/bash

# This script generates Julia client and server code from the OpenAPI specification

# Ensure we're in the correct directory
cd "$(dirname "$0")"

# Check if docker is running
check_docker() {
  if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
  fi
}

# Function to capitalize first letter of a string
capitalize() {
  local input="$1"
  local first_char=$(echo "${input:0:1}" | tr '[:lower:]' '[:upper:]')
  local rest="${input:1}"
  echo "${first_char}${rest}"
}

# Function to generate OpenAPI code
generate_openapi_code() {
  local type=$1  # "client" or "server"
  local generator="julia-${type}"
  local type_capitalized=$(capitalize "$type")
  local package_name="RxInfer${type_capitalized}OpenAPI"
  local output_dir="${OPENAPI_OUTPUT_DIR:-$(pwd)}/${type}"
  local temp_docs_dir="/tmp/openapi-${type}-docs-julia"
  
  echo "Generating Julia ${type} code from OpenAPI specification..."
  
  # Create necessary directories
  mkdir -p "${output_dir}/src"
  mkdir -p "${temp_docs_dir}"
  
  # Run the OpenAPI Generator for Julia
  docker run --rm \
    -v "$(pwd):/openapi" \
    -v "${output_dir}:/openapi/${type}" \
    -v "${temp_docs_dir}:/openapi/${type}/docs" \
    openapitools/openapi-generator-cli:latest generate \
    -i /openapi/spec.yaml \
    -g "${generator}" \
    -o "/openapi/${type}" \
    --additional-properties=packageName="${package_name}"
  
  # Generate Markdown documentation in a separate step
  mkdir -p "${output_dir}/docs"
  
  docker run --rm \
    -v "$(pwd):/openapi" \
    -v "${output_dir}/docs:/openapi/${type}/docs" \
    openapitools/openapi-generator-cli:latest generate \
    -i /openapi/spec.yaml \
    -g markdown \
    -o "/openapi/${type}/docs"
  
  echo "${type_capitalized} code and documentation generation complete!"
  echo "Generated Julia ${type} code is available in '${output_dir}'"
  echo "Generated documentation is available in '${output_dir}/docs'"
}

# Main function
main() {
  check_docker
  
  # Process command line arguments
  local target="all"
  if [ $# -ge 1 ]; then
    target="$1"
  fi
  
  echo "OpenAPI code generation started..."
  
  case "${target}" in
    "client")
      generate_openapi_code "client"
      echo "You can now use this client to interact with the RxInfer API."
      ;;
    "server")
      generate_openapi_code "server"
      echo "Do not modify the generated code. Instead, you should implement the API defined in the 'src/RxInferServerOpenAPI.jl' file."
      ;;
    "all")
      generate_openapi_code "client"
      echo "You can now use this client to interact with the RxInfer API."
      echo ""
      generate_openapi_code "server"
      echo "Do not modify the generated code. Instead, you should implement the API defined in the 'src/RxInferServerOpenAPI.jl' file."
      ;;
    *)
      echo "Error: Invalid target specified. Use 'client', 'server', or 'all'."
      exit 1
      ;;
  esac
  
  echo "OpenAPI code generation completed successfully!"
}

# Execute the main function
main "$@" 