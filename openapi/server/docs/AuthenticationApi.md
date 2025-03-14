# AuthenticationApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**generate_token**](AuthenticationApi.md#generate_token) | **POST** /generate-token | Generate authentication token


# **generate_token**
> generate_token(req::HTTP.Request;) -> TokenResponse

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

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

