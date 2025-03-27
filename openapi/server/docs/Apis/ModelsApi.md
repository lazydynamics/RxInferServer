# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

| Method | HTTP request | Description |
|------------- | ------------- | -------------|
| [**attachMetadataToEvent**](ModelsApi.md#attachMetadataToEvent) | **POST** /models/i/{model_id}/episodes/{episode_name}/events/{event_id}/attach-metadata | Attach metadata to an event |
| [**createEpisode**](ModelsApi.md#createEpisode) | **POST** /models/i/{model_id}/episodes/{episode_name}/create | Create a new episode for a model |
| [**createModelInstance**](ModelsApi.md#createModelInstance) | **POST** /models/create-instance | Create a new model instance |
| [**deleteEpisode**](ModelsApi.md#deleteEpisode) | **DELETE** /models/i/{model_id}/episodes/{episode_name}/delete | Delete an episode for a model |
| [**deleteModelInstance**](ModelsApi.md#deleteModelInstance) | **DELETE** /models/i/{model_id} | Delete a model instance |
| [**getAvailableModel**](ModelsApi.md#getAvailableModel) | **GET** /models/available/{model_name} | Get information about a specific model available for creation |
| [**getAvailableModels**](ModelsApi.md#getAvailableModels) | **GET** /models/available | Get models available for creation |
| [**getEpisodeInfo**](ModelsApi.md#getEpisodeInfo) | **GET** /models/i/{model_id}/episodes/{episode_name} | Get episode information |
| [**getEpisodes**](ModelsApi.md#getEpisodes) | **GET** /models/i/{model_id}/episodes | Get all episodes for a model |
| [**getModelInstance**](ModelsApi.md#getModelInstance) | **GET** /models/i/{model_id} | Get model instance information |
| [**getModelInstanceState**](ModelsApi.md#getModelInstanceState) | **GET** /models/i/{model_id}/state | Get the state of a model instance |
| [**getModelInstances**](ModelsApi.md#getModelInstances) | **GET** /models/created-instances | Get all created model instances |
| [**runInference**](ModelsApi.md#runInference) | **POST** /models/i/{model_id}/infer | Run inference |
| [**runLearning**](ModelsApi.md#runLearning) | **POST** /models/i/{model_id}/learn | Learn from previous observations |
| [**wipeEpisode**](ModelsApi.md#wipeEpisode) | **POST** /models/i/{model_id}/episodes/{episode_name}/wipe | Wipe all events from an episode |


<a name="attachMetadataToEvent"></a>
# **attachMetadataToEvent**
> SuccessResponse attachMetadataToEvent(model\_id, episode\_name, event\_id, AttachMetadataToEventRequest)

Attach metadata to an event

    Attach metadata to a specific event for a model

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to attach metadata to | [default to null] |
| **episode\_name** | **String**| Name of the episode to attach metadata to | [default to null] |
| **event\_id** | **Long**| ID of the event to attach metadata to | [default to null] |
| **AttachMetadataToEventRequest** | [**AttachMetadataToEventRequest**](../Models/AttachMetadataToEventRequest.md)|  | |

### Return type

[**SuccessResponse**](../Models/SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

<a name="createEpisode"></a>
# **createEpisode**
> EpisodeInfo createEpisode(model\_id, episode\_name)

Create a new episode for a model

    Create a new episode for a specific model, note that the default episode cannot be created, but you can wipe data from it. When created, the new episode becomes the current episode for the model.

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to create episode for | [default to null] |
| **episode\_name** | **String**| Name of the episode to create | [default to null] |

### Return type

[**EpisodeInfo**](../Models/EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="createModelInstance"></a>
# **createModelInstance**
> CreateModelInstanceResponse createModelInstance(CreateModelInstanceRequest)

Create a new model instance

    Creates a new instance of a model with the specified configuration

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **CreateModelInstanceRequest** | [**CreateModelInstanceRequest**](../Models/CreateModelInstanceRequest.md)|  | |

### Return type

[**CreateModelInstanceResponse**](../Models/CreateModelInstanceResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

<a name="deleteEpisode"></a>
# **deleteEpisode**
> SuccessResponse deleteEpisode(model\_id, episode\_name)

Delete an episode for a model

    Delete a specific episode for a model, note that the default episode cannot be deleted, but you can wipe data from it. If the deleted episode was the current episode, the default episode will become the current episode.

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to delete episode for | [default to null] |
| **episode\_name** | **String**| Name of the episode to delete | [default to null] |

### Return type

[**SuccessResponse**](../Models/SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="deleteModelInstance"></a>
# **deleteModelInstance**
> SuccessResponse deleteModelInstance(model\_id)

Delete a model instance

    Delete a specific model instance by its ID

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to delete | [default to null] |

### Return type

[**SuccessResponse**](../Models/SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getAvailableModel"></a>
# **getAvailableModel**
> AvailableModel getAvailableModel(model\_name)

Get information about a specific model available for creation

    Retrieve detailed information about a specific model available for creation

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_name** | **String**| Name of the model to retrieve information for (including version identifier if applicable, e.g. \&quot;BetaBernoulli-v1\&quot;) | [default to null] |

### Return type

[**AvailableModel**](../Models/AvailableModel.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getAvailableModels"></a>
# **getAvailableModels**
> List getAvailableModels()

Get models available for creation

    Retrieve the list of models available for creation for a given token. This list specifies names and available arguments for each model.  **Note** The list of available models might differ for different access tokens. For example, a token with only the \&quot;user\&quot; role might not have access to all models. 

### Parameters
This endpoint does not need any parameter.

### Return type

[**List**](../Models/AvailableModel.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getEpisodeInfo"></a>
# **getEpisodeInfo**
> EpisodeInfo getEpisodeInfo(model\_id, episode\_name)

Get episode information

    Retrieve information about a specific episode of a model

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to retrieve episode for | [default to null] |
| **episode\_name** | **String**| Name of the episode to retrieve | [default to null] |

### Return type

[**EpisodeInfo**](../Models/EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getEpisodes"></a>
# **getEpisodes**
> List getEpisodes(model\_id)

Get all episodes for a model

    Retrieve all episodes for a specific model

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to retrieve episodes for | [default to null] |

### Return type

[**List**](../Models/EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getModelInstance"></a>
# **getModelInstance**
> ModelInstance getModelInstance(model\_id)

Get model instance information

    Retrieve detailed information about a specific model instance

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to retrieve information for | [default to null] |

### Return type

[**ModelInstance**](../Models/ModelInstance.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getModelInstanceState"></a>
# **getModelInstanceState**
> ModelInstanceState getModelInstanceState(model\_id)

Get the state of a model instance

    Retrieve the state of a specific model instance

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to retrieve state for | [default to null] |

### Return type

[**ModelInstanceState**](../Models/ModelInstanceState.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getModelInstances"></a>
# **getModelInstances**
> List getModelInstances()

Get all created model instances

    Retrieve detailed information about all created model instances for a specific token

### Parameters
This endpoint does not need any parameter.

### Return type

[**List**](../Models/ModelInstance.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="runInference"></a>
# **runInference**
> InferResponse runInference(model\_id, InferRequest)

Run inference

    Run inference on a specific model instance

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to run inference on | [default to null] |
| **InferRequest** | [**InferRequest**](../Models/InferRequest.md)|  | |

### Return type

[**InferResponse**](../Models/InferResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

<a name="runLearning"></a>
# **runLearning**
> LearnResponse runLearning(model\_id, LearnRequest)

Learn from previous observations

    Learn from previous episodes for a specific model

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**|  | [default to null] |
| **LearnRequest** | [**LearnRequest**](../Models/LearnRequest.md)|  | |

### Return type

[**LearnResponse**](../Models/LearnResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

<a name="wipeEpisode"></a>
# **wipeEpisode**
> SuccessResponse wipeEpisode(model\_id, episode\_name)

Wipe all events from an episode

    Wipe all events from a specific episode for a model

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to wipe episode for | [default to null] |
| **episode\_name** | **String**| Name of the episode to wipe | [default to null] |

### Return type

[**SuccessResponse**](../Models/SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

