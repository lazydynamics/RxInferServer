# Documentation for RxInferServer OpenAPI specification

<a name="documentation-for-api-endpoints"></a>
## Documentation for API Endpoints

All URIs are relative to *http://localhost:8000/v1*

| Class | Method | HTTP request | Description |
|------------ | ------------- | ------------- | -------------|
| *AuthenticationApi* | [**tokenGenerate**](Apis/AuthenticationApi.md#tokengenerate) | **POST** /token/generate | Generate authentication token |
*AuthenticationApi* | [**tokenRoles**](Apis/AuthenticationApi.md#tokenroles) | **GET** /token/roles | Get token roles |
| *ModelsApi* | [**attachMetadataToEvent**](Apis/ModelsApi.md#attachmetadatatoevent) | **POST** /models/i/{instance_id}/episodes/{episode_name}/events/{event_id}/attach-metadata | Attach metadata to an event |
*ModelsApi* | [**createEpisode**](Apis/ModelsApi.md#createepisode) | **POST** /models/i/{instance_id}/episodes/{episode_name}/create | Create a new episode for a model |
*ModelsApi* | [**createModelInstance**](Apis/ModelsApi.md#createmodelinstance) | **POST** /models/create-instance | Create a new model instance |
*ModelsApi* | [**deleteEpisode**](Apis/ModelsApi.md#deleteepisode) | **DELETE** /models/i/{instance_id}/episodes/{episode_name}/delete | Delete an episode for a model |
*ModelsApi* | [**deleteModelInstance**](Apis/ModelsApi.md#deletemodelinstance) | **DELETE** /models/i/{instance_id} | Delete a model instance |
*ModelsApi* | [**getAvailableModel**](Apis/ModelsApi.md#getavailablemodel) | **GET** /models/available/{model_name} | Get information about a specific model available for creation |
*ModelsApi* | [**getAvailableModels**](Apis/ModelsApi.md#getavailablemodels) | **GET** /models/available | Get models available for creation |
*ModelsApi* | [**getEpisodeInfo**](Apis/ModelsApi.md#getepisodeinfo) | **GET** /models/i/{instance_id}/episodes/{episode_name} | Get episode information |
*ModelsApi* | [**getEpisodes**](Apis/ModelsApi.md#getepisodes) | **GET** /models/i/{instance_id}/episodes | Get all episodes for a model |
*ModelsApi* | [**getModelInstance**](Apis/ModelsApi.md#getmodelinstance) | **GET** /models/i/{instance_id} | Get model instance information |
*ModelsApi* | [**getModelInstanceState**](Apis/ModelsApi.md#getmodelinstancestate) | **GET** /models/i/{instance_id}/state | Get the state of a model instance |
*ModelsApi* | [**getModelInstances**](Apis/ModelsApi.md#getmodelinstances) | **GET** /models/created-instances | Get all created model instances |
*ModelsApi* | [**runInference**](Apis/ModelsApi.md#runinference) | **POST** /models/i/{instance_id}/infer | Run inference |
*ModelsApi* | [**runLearning**](Apis/ModelsApi.md#runlearning) | **POST** /models/i/{instance_id}/learn | Learn from previous observations |
*ModelsApi* | [**wipeEpisode**](Apis/ModelsApi.md#wipeepisode) | **POST** /models/i/{instance_id}/episodes/{episode_name}/wipe | Wipe all events from an episode |
| *ServerApi* | [**getServerInfo**](Apis/ServerApi.md#getserverinfo) | **GET** /info | Get server information |
*ServerApi* | [**pingServer**](Apis/ServerApi.md#pingserver) | **GET** /ping | Health check endpoint |


<a name="documentation-for-models"></a>
## Documentation for Models

 - [AttachMetadataToEventRequest](./Models/AttachMetadataToEventRequest.md)
 - [AvailableModel](./Models/AvailableModel.md)
 - [AvailableModel_details](./Models/AvailableModel_details.md)
 - [CreateModelInstanceRequest](./Models/CreateModelInstanceRequest.md)
 - [CreateModelInstanceResponse](./Models/CreateModelInstanceResponse.md)
 - [DeleteModelInstanceRequest](./Models/DeleteModelInstanceRequest.md)
 - [EpisodeInfo](./Models/EpisodeInfo.md)
 - [ErrorResponse](./Models/ErrorResponse.md)
 - [InferRequest](./Models/InferRequest.md)
 - [InferResponse](./Models/InferResponse.md)
 - [LearnRequest](./Models/LearnRequest.md)
 - [LearnResponse](./Models/LearnResponse.md)
 - [ModelInstance](./Models/ModelInstance.md)
 - [ModelInstanceState](./Models/ModelInstanceState.md)
 - [NotFoundResponse](./Models/NotFoundResponse.md)
 - [PingResponse](./Models/PingResponse.md)
 - [ServerInfo](./Models/ServerInfo.md)
 - [SuccessResponse](./Models/SuccessResponse.md)
 - [TokenGenerateResponse](./Models/TokenGenerateResponse.md)
 - [TokenRolesResponse](./Models/TokenRolesResponse.md)
 - [UnauthorizedResponse](./Models/UnauthorizedResponse.md)


<a name="documentation-for-authorization"></a>
## Documentation for Authorization

<a name="ApiKeyAuth"></a>
### ApiKeyAuth

- **Type**: HTTP Bearer Token authentication

