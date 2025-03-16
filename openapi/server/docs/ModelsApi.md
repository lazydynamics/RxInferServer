# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create_model**](ModelsApi.md#create_model) | **POST** /models/create | Create a new model instance
[**delete_model**](ModelsApi.md#delete_model) | **DELETE** /models/{model_id}/delete | Delete a model instance
[**get_created_models_info**](ModelsApi.md#get_created_models_info) | **GET** /models/created/info | Get information about all created models for a specific token
[**get_episode_info**](ModelsApi.md#get_episode_info) | **GET** /models/{model_id}/episodes/{episode_name} | Get episode information
[**get_episodes**](ModelsApi.md#get_episodes) | **GET** /models/{model_id}/episodes | Get all episodes for a model
[**get_model_details**](ModelsApi.md#get_model_details) | **GET** /models/{model_name}/details | Get model details
[**get_model_info**](ModelsApi.md#get_model_info) | **GET** /models/{model_id}/info | Get model information
[**get_models**](ModelsApi.md#get_models) | **GET** /models | Get models


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

