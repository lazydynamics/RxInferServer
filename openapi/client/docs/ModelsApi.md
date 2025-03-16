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
> attach_metadata_to_event(_api::ModelsApi, model_id::String, episode_name::String, event_id::Int64, attach_metadata_to_event_request::AttachMetadataToEventRequest; _mediaType=nothing) -> SuccessResponse, OpenAPI.Clients.ApiResponse <br/>
> attach_metadata_to_event(_api::ModelsApi, response_stream::Channel, model_id::String, episode_name::String, event_id::Int64, attach_metadata_to_event_request::AttachMetadataToEventRequest; _mediaType=nothing) -> Channel{ SuccessResponse }, OpenAPI.Clients.ApiResponse

Attach metadata to an event

Attach metadata to a specific event for a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to attach metadata to |
**episode_name** | **String** | Name of the episode to attach metadata to |
**event_id** | **Int64** | ID of the event to attach metadata to |
**attach_metadata_to_event_request** | [**AttachMetadataToEventRequest**](AttachMetadataToEventRequest.md) |  |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **create_episode**
> create_episode(_api::ModelsApi, model_id::String, episode_name::String; _mediaType=nothing) -> EpisodeInfo, OpenAPI.Clients.ApiResponse <br/>
> create_episode(_api::ModelsApi, response_stream::Channel, model_id::String, episode_name::String; _mediaType=nothing) -> Channel{ EpisodeInfo }, OpenAPI.Clients.ApiResponse

Create a new episode for a model

Create a new episode for a specific model, note that the default episode cannot be created, but you can wipe data from it. When created, the new episode becomes the current episode for the model.

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to create episode for |
**episode_name** | **String** | Name of the episode to create |

### Return type

[**EpisodeInfo**](EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **create_model**
> create_model(_api::ModelsApi, create_model_request::CreateModelRequest; _mediaType=nothing) -> CreateModelResponse, OpenAPI.Clients.ApiResponse <br/>
> create_model(_api::ModelsApi, response_stream::Channel, create_model_request::CreateModelRequest; _mediaType=nothing) -> Channel{ CreateModelResponse }, OpenAPI.Clients.ApiResponse

Create a new model instance

Creates a new instance of a model with the specified configuration

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**create_model_request** | [**CreateModelRequest**](CreateModelRequest.md) |  |

### Return type

[**CreateModelResponse**](CreateModelResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **delete_episode**
> delete_episode(_api::ModelsApi, model_id::String, episode_name::String; _mediaType=nothing) -> SuccessResponse, OpenAPI.Clients.ApiResponse <br/>
> delete_episode(_api::ModelsApi, response_stream::Channel, model_id::String, episode_name::String; _mediaType=nothing) -> Channel{ SuccessResponse }, OpenAPI.Clients.ApiResponse

Delete an episode for a model

Delete a specific episode for a model, note that the default episode cannot be deleted, but you can wipe data from it. If the deleted episode was the current episode, the default episode will become the current episode.

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to delete episode for |
**episode_name** | **String** | Name of the episode to delete |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **delete_model**
> delete_model(_api::ModelsApi, model_id::String; _mediaType=nothing) -> SuccessResponse, OpenAPI.Clients.ApiResponse <br/>
> delete_model(_api::ModelsApi, response_stream::Channel, model_id::String; _mediaType=nothing) -> Channel{ SuccessResponse }, OpenAPI.Clients.ApiResponse

Delete a model instance

Delete a specific model instance by its ID

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to delete |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **get_created_models_info**
> get_created_models_info(_api::ModelsApi; _mediaType=nothing) -> Vector{CreatedModelInfo}, OpenAPI.Clients.ApiResponse <br/>
> get_created_models_info(_api::ModelsApi, response_stream::Channel; _mediaType=nothing) -> Channel{ Vector{CreatedModelInfo} }, OpenAPI.Clients.ApiResponse

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

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **get_episode_info**
> get_episode_info(_api::ModelsApi, model_id::String, episode_name::String; _mediaType=nothing) -> EpisodeInfo, OpenAPI.Clients.ApiResponse <br/>
> get_episode_info(_api::ModelsApi, response_stream::Channel, model_id::String, episode_name::String; _mediaType=nothing) -> Channel{ EpisodeInfo }, OpenAPI.Clients.ApiResponse

Get episode information

Retrieve information about a specific episode of a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to retrieve episode for |
**episode_name** | **String** | Name of the episode to retrieve |

### Return type

[**EpisodeInfo**](EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **get_episodes**
> get_episodes(_api::ModelsApi, model_id::String; _mediaType=nothing) -> Vector{EpisodeInfo}, OpenAPI.Clients.ApiResponse <br/>
> get_episodes(_api::ModelsApi, response_stream::Channel, model_id::String; _mediaType=nothing) -> Channel{ Vector{EpisodeInfo} }, OpenAPI.Clients.ApiResponse

Get all episodes for a model

Retrieve all episodes for a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to retrieve episodes for |

### Return type

[**Vector{EpisodeInfo}**](EpisodeInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **get_model_details**
> get_model_details(_api::ModelsApi, model_name::String; _mediaType=nothing) -> ModelDetails, OpenAPI.Clients.ApiResponse <br/>
> get_model_details(_api::ModelsApi, response_stream::Channel, model_name::String; _mediaType=nothing) -> Channel{ ModelDetails }, OpenAPI.Clients.ApiResponse

Get model details

Retrieve detailed information about a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_name** | **String** | Name of the model to retrieve information for (including version identifier if applicable, e.g. \&quot;BetaBernoulli-v1\&quot;) |

### Return type

[**ModelDetails**](ModelDetails.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **get_model_info**
> get_model_info(_api::ModelsApi, model_id::String; _mediaType=nothing) -> CreatedModelInfo, OpenAPI.Clients.ApiResponse <br/>
> get_model_info(_api::ModelsApi, response_stream::Channel, model_id::String; _mediaType=nothing) -> Channel{ CreatedModelInfo }, OpenAPI.Clients.ApiResponse

Get model information

Retrieve detailed information about a specific model instance

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to retrieve information for |

### Return type

[**CreatedModelInfo**](CreatedModelInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **get_model_state**
> get_model_state(_api::ModelsApi, model_id::String; _mediaType=nothing) -> ModelState, OpenAPI.Clients.ApiResponse <br/>
> get_model_state(_api::ModelsApi, response_stream::Channel, model_id::String; _mediaType=nothing) -> Channel{ ModelState }, OpenAPI.Clients.ApiResponse

Get the state of a model

Retrieve the state of a specific model instance

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to retrieve state for |

### Return type

[**ModelState**](ModelState.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **get_models**
> get_models(_api::ModelsApi; _mediaType=nothing) -> ModelList, OpenAPI.Clients.ApiResponse <br/>
> get_models(_api::ModelsApi, response_stream::Channel; _mediaType=nothing) -> Channel{ ModelList }, OpenAPI.Clients.ApiResponse

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

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **run_inference**
> run_inference(_api::ModelsApi, model_id::String, infer_request::InferRequest; _mediaType=nothing) -> InferResponse, OpenAPI.Clients.ApiResponse <br/>
> run_inference(_api::ModelsApi, response_stream::Channel, model_id::String, infer_request::InferRequest; _mediaType=nothing) -> Channel{ InferResponse }, OpenAPI.Clients.ApiResponse

Run inference on a model

Run inference on a specific model instance

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to run inference on |
**infer_request** | [**InferRequest**](InferRequest.md) |  |

### Return type

[**InferResponse**](InferResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **run_learning**
> run_learning(_api::ModelsApi, model_id::String, learn_request::LearnRequest; _mediaType=nothing) -> LearnResponse, OpenAPI.Clients.ApiResponse <br/>
> run_learning(_api::ModelsApi, response_stream::Channel, model_id::String, learn_request::LearnRequest; _mediaType=nothing) -> Channel{ LearnResponse }, OpenAPI.Clients.ApiResponse

Learn from previous observations

Learn from previous episodes for a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** |  |
**learn_request** | [**LearnRequest**](LearnRequest.md) |  |

### Return type

[**LearnResponse**](LearnResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **wipe_episode**
> wipe_episode(_api::ModelsApi, model_id::String, episode_name::String; _mediaType=nothing) -> SuccessResponse, OpenAPI.Clients.ApiResponse <br/>
> wipe_episode(_api::ModelsApi, response_stream::Channel, model_id::String, episode_name::String; _mediaType=nothing) -> Channel{ SuccessResponse }, OpenAPI.Clients.ApiResponse

Wipe all events from an episode

Wipe all events from a specific episode for a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_id** | **String** | ID of the model to wipe episode for |
**episode_name** | **String** | Name of the episode to wipe |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

