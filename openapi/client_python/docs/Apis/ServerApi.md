# ServerApi

All URIs are relative to *http://localhost:8000/v1*

| Method | HTTP request | Description |
|------------- | ------------- | -------------|
| [**getServerInfo**](ServerApi.md#getServerInfo) | **GET** /info | Get server information |
| [**pingServer**](ServerApi.md#pingServer) | **GET** /ping | Health check endpoint |


<a name="getServerInfo"></a>
# **getServerInfo**
> ServerInfo getServerInfo()

Get server information

    Returns information about the server, such as the RxInfer version, Server version, Server edition, and Julia version

### Parameters
This endpoint does not need any parameter.

### Return type

[**ServerInfo**](../Models/ServerInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

<a name="pingServer"></a>
# **pingServer**
> PingResponse pingServer()

Health check endpoint

    Simple endpoint to check if the server is alive and running

### Parameters
This endpoint does not need any parameter.

### Return type

[**PingResponse**](../Models/PingResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json

