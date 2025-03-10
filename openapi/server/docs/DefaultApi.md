# DefaultApi

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create_model**](DefaultApi.md#create_model) | **POST** /models | Create a new model
[**delete_model**](DefaultApi.md#delete_model) | **DELETE** /models/{modelId} | Delete a model
[**get_model_by_id**](DefaultApi.md#get_model_by_id) | **GET** /models/{modelId} | Get model by ID
[**list_models**](DefaultApi.md#list_models) | **GET** /models | List all models
[**run_inference**](DefaultApi.md#run_inference) | **POST** /models/{modelId}/inference | Run inference on a model


# **create_model**
> create_model(req::HTTP.Request, model_creation_request::ModelCreationRequest;) -> Model

Create a new model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_creation_request** | [**ModelCreationRequest**](ModelCreationRequest.md)|  |

### Return type

[**Model**](Model.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_model**
> delete_model(req::HTTP.Request, model_id::String;) -> Nothing

Delete a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**|  |

### Return type

Nothing

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_model_by_id**
> get_model_by_id(req::HTTP.Request, model_id::String;) -> Model

Get model by ID

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**|  |

### Return type

[**Model**](Model.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_models**
> list_models(req::HTTP.Request;) -> Vector{Model}

List all models

### Required Parameters
This endpoint does not need any parameter.

### Return type

[**Vector{Model}**](Model.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **run_inference**
> run_inference(req::HTTP.Request, model_id::String, inference_request::InferenceRequest;) -> InferenceResult

Run inference on a model

### Required Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **req** | **HTTP.Request** | The HTTP Request object | 
**model_id** | **String**|  |
**inference_request** | [**InferenceRequest**](InferenceRequest.md)|  |

### Return type

[**InferenceResult**](InferenceResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

