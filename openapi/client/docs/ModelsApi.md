# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**get_model_info**](ModelsApi.md#get_model_info) | **GET** /models/{model_name}/info | Get model information
[**get_models**](ModelsApi.md#get_models) | **GET** /models | Get models


# **get_model_info**
> get_model_info(_api::ModelsApi, model_name::String; _mediaType=nothing) -> ModelInfo, OpenAPI.Clients.ApiResponse <br/>
> get_model_info(_api::ModelsApi, response_stream::Channel, model_name::String; _mediaType=nothing) -> Channel{ ModelInfo }, OpenAPI.Clients.ApiResponse

Get model information

Retrieve detailed information about a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **_api** | **ModelsApi** | API context | 
**model_name** | **String** | Name of the model to retrieve information for (including version identifier if applicable, e.g. \&quot;CoinToss-v1\&quot;) |

### Return type

[**ModelInfo**](ModelInfo.md)

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

Retrieve the list of available models. Note that some access tokens might not have access to all models.

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

