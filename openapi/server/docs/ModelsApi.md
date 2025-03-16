# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create_model**](ModelsApi.md#create_model) | **POST** /models/create | Create a new model instance
[**get_model_details**](ModelsApi.md#get_model_details) | **GET** /models/{model_name}/details | Get model details
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

# **get_model_details**
> get_model_details(req::HTTP.Request, model_name::String;) -> ModelDetails

Get model details

Retrieve detailed information about a specific model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_name** | **String**| Name of the model to retrieve information for (including version identifier if applicable, e.g. \&quot;CoinToss-v1\&quot;) |

### Return type

[**ModelDetails**](ModelDetails.md)

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

