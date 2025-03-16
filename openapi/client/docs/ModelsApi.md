# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create_model**](ModelsApi.md#create_model) | **POST** /models/create | Create a new model instance
[**get_model_details**](ModelsApi.md#get_model_details) | **GET** /models/{model_name}/details | Get model details
[**get_models**](ModelsApi.md#get_models) | **GET** /models | Get models


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

# **get_model_details**
> get_model_details(_api::ModelsApi, model_name::String; _mediaType=nothing) -> ModelDetails, OpenAPI.Clients.ApiResponse <br/>
> get_model_details(_api::ModelsApi, response_stream::Channel, model_name::String; _mediaType=nothing) -> Channel{ ModelDetails }, OpenAPI.Clients.ApiResponse

Get model details

Retrieve detailed information about a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_name** | **String** | Name of the model to retrieve information for (including version identifier if applicable, e.g. \&quot;CoinToss-v1\&quot;) |

### Return type

[**ModelDetails**](ModelDetails.md)

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

