# AuthenticationApi

All URIs are relative to *http://localhost:8000/v1*

| Method | HTTP request | Description |
|------------- | ------------- | -------------|
| [**generateToken**](AuthenticationApi.md#generateToken) | **POST** /generate-token | Generate authentication token |


<a name="generateToken"></a>
# **generateToken**
> TokenResponse generateToken()

Generate authentication token

    Generates a new authentication token for accessing protected endpoints

### Parameters
This endpoint does not need any parameter.

### Return type

[**TokenResponse**](../Models/TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

