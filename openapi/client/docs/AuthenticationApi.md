# AuthenticationApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**generate_token**](AuthenticationApi.md#generate_token) | **POST** /token | Generate authentication token


# **generate_token**
> generate_token(_api::AuthenticationApi; _mediaType=nothing) -> TokenResponse, OpenAPI.Clients.ApiResponse <br/>
> generate_token(_api::AuthenticationApi, response_stream::Channel; _mediaType=nothing) -> Channel{ TokenResponse }, OpenAPI.Clients.ApiResponse

Generate authentication token

Generates a new authentication token for accessing protected endpoints

### Required Parameters
This endpoint does not need any parameter.

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

