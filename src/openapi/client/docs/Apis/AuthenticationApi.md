# AuthenticationApi

All URIs are relative to *http://localhost:8000/v1*

| Method | HTTP request | Description |
|------------- | ------------- | -------------|
| [**tokenGenerate**](AuthenticationApi.md#tokenGenerate) | **POST** /token/generate | Generate authentication token |
| [**tokenRoles**](AuthenticationApi.md#tokenRoles) | **GET** /token/roles | Get token roles |


<a name="tokenGenerate"></a>
# **tokenGenerate**
> TokenGenerateResponse tokenGenerate()

Generate authentication token

    Generates a new authentication token for accessing protected endpoints

### Parameters
This endpoint does not need any parameter.

### Return type

[**TokenGenerateResponse**](../Models/TokenGenerateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="tokenRoles"></a>
# **tokenRoles**
> TokenRolesResponse tokenRoles()

Get token roles

    Retrieve the list of roles for a specific token

### Parameters
This endpoint does not need any parameter.

### Return type

[**TokenRolesResponse**](../Models/TokenRolesResponse.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

