# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

| Method | HTTP request | Description |
|------------- | ------------- | -------------|
| [**attachMetadataToEvent**](ModelsApi.md#attachMetadataToEvent) | **POST** /models/{model_id}/episodes/{episode_name}/events/{event_id}/attach-metadata | Attach metadata to an event |
| [**createEpisode**](ModelsApi.md#createEpisode) | **POST** /models/{model_id}/episodes/{episode_name}/create | Create a new episode for a model |
| [**createModel**](ModelsApi.md#createModel) | **POST** /models/create | Create a new model instance |
| [**deleteEpisode**](ModelsApi.md#deleteEpisode) | **DELETE** /models/{model_id}/episodes/{episode_name}/delete | Delete an episode for a model |
| [**deleteModel**](ModelsApi.md#deleteModel) | **DELETE** /models/{model_id}/delete | Delete a model instance |
| [**getCreatedModelsInfo**](ModelsApi.md#getCreatedModelsInfo) | **GET** /models/created | Get information about all created models for a specific token |
| [**getEpisodeInfo**](ModelsApi.md#getEpisodeInfo) | **GET** /models/{model_id}/episodes/{episode_name} | Get episode information |
| [**getEpisodes**](ModelsApi.md#getEpisodes) | **GET** /models/{model_id}/episodes | Get all episodes for a model |
| [**getModelDetails**](ModelsApi.md#getModelDetails) | **GET** /models/{model_name}/details | Get model details |
| [**getModelInfo**](ModelsApi.md#getModelInfo) | **GET** /models/{model_id}/info | Get model information |
| [**getModelState**](ModelsApi.md#getModelState) | **GET** /models/{model_id}/state | Get the state of a model |
| [**getModels**](ModelsApi.md#getModels) | **GET** /models | Get models |
| [**runInference**](ModelsApi.md#runInference) | **POST** /models/{model_id}/infer | Run inference on a model |
| [**runLearning**](ModelsApi.md#runLearning) | **POST** /models/{model_id}/learn | Learn from previous observations |
| [**wipeEpisode**](ModelsApi.md#wipeEpisode) | **POST** /models/{model_id}/episodes/{episode_name}/wipe | Wipe all events from an episode |


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

<a name="createModel"></a>
# **createModel**
> CreateModelResponse createModel(CreateModelRequest)

Create a new model instance

    Creates a new instance of a model with the specified configuration

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **CreateModelRequest** | [**CreateModelRequest**](../Models/CreateModelRequest.md)|  | |

### Return type

[**CreateModelResponse**](../Models/CreateModelResponse.md)

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

<a name="deleteModel"></a>
# **deleteModel**
> SuccessResponse deleteModel(model\_id)

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

<a name="getCreatedModelsInfo"></a>
# **getCreatedModelsInfo**
> List getCreatedModelsInfo()

Get information about all created models for a specific token

    Retrieve detailed information about all created models for a specific token

### Parameters
This endpoint does not need any parameter.

### Return type

[**List**](../Models/CreatedModelInfo.md)

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

<a name="getModelDetails"></a>
# **getModelDetails**
> ModelDetails getModelDetails(model\_name)

Get model details

    Retrieve detailed information about a specific model

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_name** | **String**| Name of the model to retrieve information for (including version identifier if applicable, e.g. \&quot;BetaBernoulli-v1\&quot;) | [default to null] |

### Return type

[**ModelDetails**](../Models/ModelDetails.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getModelInfo"></a>
# **getModelInfo**
> CreatedModelInfo getModelInfo(model\_id)

Get model information

    Retrieve detailed information about a specific model instance

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to retrieve information for | [default to null] |

### Return type

[**CreatedModelInfo**](../Models/CreatedModelInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getModelState"></a>
# **getModelState**
> ModelState getModelState(model\_id)

Get the state of a model

    Retrieve the state of a specific model instance

### Parameters

|Name | Type | Description  | Notes |
|------------- | ------------- | ------------- | -------------|
| **model\_id** | **UUID**| ID of the model to retrieve state for | [default to null] |

### Return type

[**ModelState**](../Models/ModelState.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="getModels"></a>
# **getModels**
> ModelList getModels()

Get models

    Retrieve the list of available models and their lightweight details. Note that some access tokens might not have access to all models.

### Parameters
This endpoint does not need any parameter.

### Return type

[**ModelList**](../Models/ModelList.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="runInference"></a>
# **runInference**
> InferResponse runInference(model\_id, InferRequest)

Run inference on a model

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

