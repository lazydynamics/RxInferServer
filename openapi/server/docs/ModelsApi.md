# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**attach_metadata_to_event**](ModelsApi.md#attach_metadata_to_event) | **POST** /models/{model_id}/episodes/{episode_name}/events/{event_id}/attach-metadata | Attach metadata to an event
[**create_episode**](ModelsApi.md#create_episode) | **POST** /models/{model_id}/episodes/{episode_name}/create | Create a new episode for a model
[**create_model**](ModelsApi.md#create_model) | **POST** /models/create | Create a new model instance
[**delete_episode**](ModelsApi.md#delete_episode) | **DELETE** /models/{model_id}/episodes/{episode_name}/delete | Delete an episode for a model
[**delete_model**](ModelsApi.md#delete_model) | **DELETE** /models/{model_id}/delete | Delete a model instance
[**get_created_models_info**](ModelsApi.md#get_created_models_info) | **GET** /models/created | Get information about all created models for a specific token
[**get_episode_info**](ModelsApi.md#get_episode_info) | **GET** /models/{model_id}/episodes/{episode_name} | Get episode information
[**get_episodes**](ModelsApi.md#get_episodes) | **GET** /models/{model_id}/episodes | Get all episodes for a model
[**get_model_details**](ModelsApi.md#get_model_details) | **GET** /models/{model_name}/details | Get model details
[**get_model_info**](ModelsApi.md#get_model_info) | **GET** /models/{model_id}/info | Get model information
[**get_model_state**](ModelsApi.md#get_model_state) | **GET** /models/{model_id}/state | Get the state of a model
[**get_models**](ModelsApi.md#get_models) | **GET** /models | Get models
[**run_inference**](ModelsApi.md#run_inference) | **POST** /models/{model_id}/infer | Run inference on a model
[**run_learning**](ModelsApi.md#run_learning) | **POST** /models/{model_id}/learn | Learn from previous observations
[**wipe_episode**](ModelsApi.md#wipe_episode) | **POST** /models/{model_id}/episodes/{episode_name}/wipe | Wipe all events from an episode


# **attach_metadata_to_event**
> attach_metadata_to_event(req::HTTP.Request, model_id::String, episode_name::String, event_id::Int64, attach_metadata_to_event_request::AttachMetadataToEventRequest;) -> SuccessResponse

Attach metadata to an event

Attach metadata to a specific event for a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to attach metadata to |
**episode_name** | **String**| Name of the episode to attach metadata to |
**event_id** | **Int64**| ID of the event to attach metadata to |
**attach_metadata_to_event_request** | [**AttachMetadataToEventRequest**](AttachMetadataToEventRequest.md)|  |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_episode**
> create_episode(req::HTTP.Request, model_id::String, episode_name::String;) -> EpisodeInfo

Create a new episode for a model

Create a new episode for a specific model, note that the default episode cannot be created, but you can wipe data from it. When created, the new episode becomes the current episode for the model.

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to create episode for |
**episode_name** | **String**| Name of the episode to create |

### Return type

[**EpisodeInfo**](EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_model**
> create_model(req::HTTP.Request, create_model_request::CreateModelRequest;) -> CreateModelResponse

Create a new model instance

Creates a new instance of a model with the specified configuration

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**create_model_request** | [**CreateModelRequest**](CreateModelRequest.md)|  |

### Return type

[**CreateModelResponse**](CreateModelResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_episode**
> delete_episode(req::HTTP.Request, model_id::String, episode_name::String;) -> SuccessResponse

Delete an episode for a model

Delete a specific episode for a model, note that the default episode cannot be deleted, but you can wipe data from it. If the deleted episode was the current episode, the default episode will become the current episode.

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to delete episode for |
**episode_name** | **String**| Name of the episode to delete |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_model**
> delete_model(req::HTTP.Request, model_id::String;) -> SuccessResponse

Delete a model instance

Delete a specific model instance by its ID

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to delete |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_created_models_info**
> get_created_models_info(req::HTTP.Request;) -> Vector{CreatedModelInfo}

Get information about all created models for a specific token

Retrieve detailed information about all created models for a specific token

### Required Parameters
This endpoint does not need any parameter.

### Return type

[**Vector{CreatedModelInfo}**](CreatedModelInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_episode_info**
> get_episode_info(req::HTTP.Request, model_id::String, episode_name::String;) -> EpisodeInfo

Get episode information

Retrieve information about a specific episode of a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to retrieve episode for |
**episode_name** | **String**| Name of the episode to retrieve |

### Return type

[**EpisodeInfo**](EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_episodes**
> get_episodes(req::HTTP.Request, model_id::String;) -> Vector{EpisodeInfo}

Get all episodes for a model

Retrieve all episodes for a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to retrieve episodes for |

### Return type

[**Vector{EpisodeInfo}**](EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_model_details**
> get_model_details(req::HTTP.Request, model_name::String;) -> ModelDetails

Get model details

Retrieve detailed information about a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_name** | **String**| Name of the model to retrieve information for (including version identifier if applicable, e.g. \&quot;BetaBernoulli-v1\&quot;) |

### Return type

[**ModelDetails**](ModelDetails.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_model_info**
> get_model_info(req::HTTP.Request, model_id::String;) -> CreatedModelInfo

Get model information

Retrieve detailed information about a specific model instance

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to retrieve information for |

### Return type

[**CreatedModelInfo**](CreatedModelInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_model_state**
> get_model_state(req::HTTP.Request, model_id::String;) -> ModelState

Get the state of a model

Retrieve the state of a specific model instance

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to retrieve state for |

### Return type

[**ModelState**](ModelState.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_models**
> get_models(req::HTTP.Request;) -> ModelList

Get models

Retrieve the list of available models and their lightweight details. Note that some access tokens might not have access to all models.

### Required Parameters
This endpoint does not need any parameter.

### Return type

[**ModelList**](ModelList.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **run_inference**
> run_inference(req::HTTP.Request, model_id::String, infer_request::InferRequest;) -> InferResponse

Run inference on a model

Run inference on a specific model instance

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to run inference on |
**infer_request** | [**InferRequest**](InferRequest.md)|  |

### Return type

[**InferResponse**](InferResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **run_learning**
> run_learning(req::HTTP.Request, model_id::String, learn_request::LearnRequest;) -> LearnResponse

Learn from previous observations

Learn from previous episodes for a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**|  |
**learn_request** | [**LearnRequest**](LearnRequest.md)|  |

### Return type

[**LearnResponse**](LearnResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **wipe_episode**
> wipe_episode(req::HTTP.Request, model_id::String, episode_name::String;) -> SuccessResponse

Wipe all events from an episode

Wipe all events from a specific episode for a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**| ID of the model to wipe episode for |
**episode_name** | **String**| Name of the episode to wipe |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

