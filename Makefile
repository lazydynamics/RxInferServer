# RxInferServer.jl Makefile

.PHONY: help docs docs-serve docs-clean docs-build deps test serve dev docker-start docker-stop clean format check-format generate-client generate-server generate-all

# Colors for terminal output
ifdef NO_COLOR
GREEN  :=
YELLOW :=
WHITE  :=
RESET  :=
else
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
endif

# Default target
.DEFAULT_GOAL := help

## Show help for each of the Makefile targets
help:
	@echo ''
	@echo 'RxInferServer.jl Makefile ${YELLOW}targets${RESET}:'
	@echo ''
	@echo '${GREEN}Documentation commands:${RESET}'
	@echo '  ${YELLOW}docs${RESET}                 Build the documentation (same as docs-build)'
	@echo '  ${YELLOW}docs-build${RESET}           Build the documentation (requires a running server to run checks)'
	@echo '  ${YELLOW}docs-serve${RESET}           Serve documentation locally for preview in browser'
	@echo '  ${YELLOW}docs-clean${RESET}           Clean the documentation build directory'
	@echo ''
	@echo '${GREEN}Development commands:${RESET}'
	@echo '  ${YELLOW}deps${RESET}                 Install project dependencies'
	@echo '  ${YELLOW}test${RESET}                 Run project tests'
	@echo '  ${YELLOW}serve${RESET}                Run the server'
	@echo '  ${YELLOW}dev${RESET}                  Run the server in the development mode (do not use for production)'
	@echo '  ${YELLOW}docker-start${RESET}         Start the docker compose environment'
	@echo '  ${YELLOW}docker-stop${RESET}          Stop the docker compose environment'
	@echo '  ${YELLOW}generate-client${RESET}      Generate OpenAPI client code'
	@echo '  ${YELLOW}generate-server${RESET}      Generate OpenAPI server code'
	@echo '  ${YELLOW}generate-all${RESET}         Generate both OpenAPI client and server code'
	@echo '  ${YELLOW}clean${RESET}                Clean all generated files'
	@echo ''
	@echo '${GREEN}Formatting commands:${RESET}'
	@echo '  ${YELLOW}format${RESET}               Format Julia code (overwrites files)'
	@echo '  ${YELLOW}check-format${RESET}         Check Julia code formatting (does not overwrite files)'
	@echo ''
	@echo '${GREEN}Help:${RESET}'
	@echo '  ${YELLOW}help${RESET}                 Show this help message'
	@echo ''
	@echo '${GREEN}Environment variables:${RESET}'
	@echo '  ${YELLOW}NO_COLOR${RESET}             Set this variable to any value to disable colored output'
	@echo ''

## Documentation commands:
docs: docs-build ## Build the documentation (same as docs-build)

docs-build: ## Build the documentation
	julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
	julia --project=docs docs/make.jl

docs-serve: ## Serve documentation locally for preview in browser (requires LiveServer.jl installed globally, ignores changes to auto-generated openapi documentation)
	julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
	julia --project=docs -e 'using LiveServer; servedocs(port=8001, skip_dirs=[joinpath("docs", "src", "openapi")])'
  
docs-clean: ## Clean the documentation build directory
	rm -rf docs/build/
	rm -rf docs/src/openapi/

## Development commands:
deps: ## Install project dependencies
	julia --project -e 'using Pkg; Pkg.instantiate()'

test: deps ## Run project tests
	julia --project -e 'using Pkg; Pkg.test()'

serve: deps ## Run the server
	julia --project -e 'using RxInferServer; RxInferServer.serve()'

dev: deps ## Run the server (with .env.development)
	$(eval TRACE_COMPILE_PATH ?=)
	$(eval TRACE_COMPILE_FLAG := $(if $(TRACE_COMPILE_PATH),--trace-compile=$(TRACE_COMPILE_PATH),))
	RXINFER_SERVER_ENV=development \
	julia --project $(TRACE_COMPILE_FLAG) -e 'using RxInferServer; RxInferServer.serve()'

docker: docker-start ## Starts the docker compose environment

docker-start: ## Starts the docker compose environment
	docker compose up -d --build --wait --wait-timeout 240 || (docker compose logs && exit 1)

docker-stop: ## Stops the docker compose environment
	docker compose down

generate-client: ## Generate OpenAPI client code
	OPENAPI_OUTPUT_DIR=$(PWD)/src/openapi ./openapi/generate.sh client

generate-server: ## Generate OpenAPI server code
	OPENAPI_OUTPUT_DIR=$(PWD)/src/openapi ./openapi/generate.sh server

generate-all: ## Generate both OpenAPI client and server code
	OPENAPI_OUTPUT_DIR=$(PWD)/src/openapi ./openapi/generate.sh all

clean: docs-clean ## Clean all generated files

# Formatting commands:
scripts-deps: ## Install dependencies for the scripts
	julia --project=scripts -e 'using Pkg; Pkg.instantiate()'

format: scripts-deps ## Format Julia code
	julia --project=scripts scripts/formatter.jl --overwrite

check-format: scripts-deps ## Check Julia code formatting
	julia --project=scripts scripts/formatter.jl