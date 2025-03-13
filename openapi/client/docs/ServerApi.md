# ServerApi

All URIs are relative to *http://localhost:8000/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**get_server_info**](ServerApi.md#get_server_info) | **GET** /info | Get server information
[**ping_server**](ServerApi.md#ping_server) | **GET** /ping | Health check endpoint


# **get_server_info**
> get_server_info(_api::ServerApi; _mediaType=nothing) -> ServerInfo, OpenAPI.Clients.ApiResponse <br/>
> get_server_info(_api::ServerApi, response_stream::Channel; _mediaType=nothing) -> Channel{ ServerInfo }, OpenAPI.Clients.ApiResponse

Get server information

Returns information about the server, such as the RxInfer version, Server version, Server edition, and Julia version

### Required Parameters
This endpoint does not need any parameter.

### Return type

[**ServerInfo**](ServerInfo.md)

### Authorization

[ApiKeyAuth](../README.md#ApiKeyAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

# **ping_server**
> ping_server(_api::ServerApi; _mediaType=nothing) -> PingResponse, OpenAPI.Clients.ApiResponse <br/>
> ping_server(_api::ServerApi, response_stream::Channel; _mediaType=nothing) -> Channel{ PingResponse }, OpenAPI.Clients.ApiResponse

Health check endpoint

Simple endpoint to check if the server is alive and running

### Required Parameters
This endpoint does not need any parameter.

### Return type

[**PingResponse**](PingResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)

