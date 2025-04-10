# [Models](@id models)

RxInferServer provides a flexible system for loading, managing, and exposing RxInfer probabilistic models through the API. This section explains the technical implementation details of how models work in the server, including the model dispatcher, loading process, and API integration.

For information about how to create and add new models, please refer to the [How to Add a Model](@ref manual-how-to-add-a-model) manual.

## Model System Overview

The model system in RxInferServer consists of several key components:

- [`RxInferServer.Models.ModelsDispatcher`](@ref): Manages model discovery, loading, and access
- [`RxInferServer.Models.LoadedModel`](@ref): Represents a loaded model with its configuration and implementation
- Model registry: Maintains a collection of available models
- Hot-reloading system: Enables dynamic model updates during development

## Model Discovery and Loading

The server discovers and loads models at startup using this process:

1. It scans all directories specified in [`RxInferServer.Models.RXINFER_SERVER_MODELS_LOCATIONS`](@ref)
2. For each directory, it looks for subdirectories that might contain models
3. In each subdirectory, it checks for `model.jl` and `config.yaml` files
4. If both files exist, it loads the model's configuration and code
5. The model is added to the server's model registry if successful

Models are accessed through a [`RxInferServer.Models.ModelsDispatcher`](@ref) which provides methods to retrieve models by name or list all available (non-private) models.

## Hot-Reloading System

RxInferServer supports hot-reloading of models during development. When model files are modified:

1. The server detects the changes automatically
2. It reloads all models from their directories
3. The updated models become immediately available through the API

This feature is enabled by default during development and can be disabled through the server's configuration. See [Hot-Reloading](@ref hot-reloading-configuration) for more details.

## API Integration

Models are exposed through the API endpoints defined in the OpenAPI specification. When a client requests model information or executes a model, the server:

1. Looks up the requested model by name using the dispatcher
2. If found, returns the model's metadata
3. Returns appropriate error responses if the model is not found or other issues occur

## API Reference 

```@docs
RxInferServer.Models
RxInferServer.Models.ModelsDispatcher
RxInferServer.Models.LoadedModel
RxInferServer.Models.get_models
RxInferServer.Models.get_model
RxInferServer.Models.load_models!
RxInferServer.Models.reload!
RxInferServer.Models.with_models
RxInferServer.Models.get_models_dispatcher
RxInferServer.Models.serialize_parameters
RxInferServer.Models.serialize_state
RxInferServer.Models.deserialize_state
RxInferServer.Models.deserialize_parameters
RxInferServer.Models.validate_model_config_header
RxInferServer.Models.validate_model_config_arguments
RxInferServer.Models.parse_model_config_default_arguments
RxInferServer.Models.ModelConfigurationValidationError
```