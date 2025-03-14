# ModelsApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**get_models**](ModelsApi.md#get_models) | **GET** /models | Get models


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

