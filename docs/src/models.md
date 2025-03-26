# [Models](@id models)

RxInferServer provides a flexible system for loading, managing, and exposing RxInfer probabilistic models through the API. This section explains how models work in the server, how to create them, and how the model discovery and loading process works.

## Model Overview

Models in RxInferServer are self-contained probabilistic models built with RxInfer.jl that can be loaded by the server and exposed through the API. Each model:

- Is contained in its own directory
- Has a configuration file defining metadata
- Contains Julia code that implements the model's logic
- Can be dynamically discovered and loaded by the server
- Supports hot-reloading for rapid development

## Model Discovery and Loading

The server discovers and loads models at startup using this process:

1. It scans all directories specified in [`RxInferServer.Models.RXINFER_SERVER_MODELS_LOCATIONS`](@ref)
2. For each directory, it looks for subdirectories that might contain models
3. In each subdirectory, it checks for `model.jl` and `config.yaml` files
4. If both files exist, it loads the model's configuration and code
5. The model is added to the server's model registry if successful

Models are accessed through a [`RxInferServer.Models.ModelsDispatcher`](@ref) which provides methods to retrieve models by name or list all available (non-private) models.

## Hot-Reloading Models

RxInferServer supports hot-reloading of models during development, which means you can modify model files and see the changes without restarting the server. When model files are modified:

1. The server detects the changes automatically
2. It reloads all models from their directories
3. The updated models become immediately available through the API

This feature is enabled by default during development and can be disabled through the server's configuration. See [Hot-Reloading](@ref hot-reloading-configuration) for more details.

## Model Directory Structure

Each model must follow this directory structure:

```
models/
└── ModelName/
    ├── model.jl       # Model implementation
    └── config.yaml    # Model configuration
```

The server will automatically scan the directories specified in [`RXINFER_SERVER_MODELS_LOCATIONS`](@ref models-configuration) for models. By default, it looks in the `models` and `custom_models` directories relative to the current working directory. Note that the `custom_models` directory is git-ignored by default, it might be useful to experiment with custom models without committing them to the repository.

### Configuration File of a Model (config.yaml)

The configuration file defines the model's metadata and must contain at least the following fields:

```yaml
name: ModelName-v1             # Model name with version identifier
description: Model description # A brief description of the model
author: Author Name            # Name of the model's author
```

### Model Implementation (model.jl)

The `model.jl` file contains the Julia code implementing the model's logic. Each model is loaded into its own module to isolate its namespace, so it can define its own types and functions without conflicts.

## Exposing Models via API

Models are exposed through the API endpoints defined in the OpenAPI specification. Read the [Model management](@ref model-management-api) section to know more about how to create models with client API. When a client requests model information or executes a model, the server:

1. Looks up the requested model by name
2. If found, returns the model's metadata
3. Returns appropriate error responses if the model is not found or other issues occur

## API Reference 

```@docs
RxInferServer.Models.ModelsDispatcher
RxInferServer.Models.LoadedModel
RxInferServer.Models.get_models
RxInferServer.Models.get_model
RxInferServer.Models.load_models!
RxInferServer.Models.reload!
RxInferServer.Models.with_models
RxInferServer.Models.get_models_dispatcher
RxInferServer.Models.parse_default_arguments_from_config
RxInferServer.Models
```