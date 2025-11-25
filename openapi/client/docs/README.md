# Documentation for RxInferServer OpenAPI specification

<a name="documentation-for-api-endpoints"></a>
## Documentation for API Endpoints

All URIs are relative to *http://localhost:8000/v1*

| Class | Method | HTTP request | Description |
|------------ | ------------- | ------------- | -------------|
| *AuthenticationApi* | [**tokenGenerate**](Apis/AuthenticationApi.md#tokenGenerate) | **POST** /token/generate | Generate authentication token |
*AuthenticationApi* | [**tokenRoles**](Apis/AuthenticationApi.md#tokenRoles) | **GET** /token/roles | Get token roles |
| *ModelsApi* | [**attachEventsToEpisode**](Apis/ModelsApi.md#attachEventsToEpisode) | **POST** /models/i/{instance_id}/episodes/{episode_name}/attach-events | Attach events to an episode |
*ModelsApi* | [**attachMetadataToEvent**](Apis/ModelsApi.md#attachMetadataToEvent) | **POST** /models/i/{instance_id}/episodes/{episode_name}/events/{event_id}/attach-metadata | Attach metadata to an event |
*ModelsApi* | [**createEpisode**](Apis/ModelsApi.md#createEpisode) | **POST** /models/i/{instance_id}/create-episode | Create a new episode for a model instance |
*ModelsApi* | [**createModelInstance**](Apis/ModelsApi.md#createModelInstance) | **POST** /models/create-instance | Create a new model instance |
*ModelsApi* | [**deleteEpisode**](Apis/ModelsApi.md#deleteEpisode) | **DELETE** /models/i/{instance_id}/episodes/{episode_name} | Delete an episode for a model |
*ModelsApi* | [**deleteModelInstance**](Apis/ModelsApi.md#deleteModelInstance) | **DELETE** /models/i/{instance_id} | Delete a model instance |
*ModelsApi* | [**getAvailableModel**](Apis/ModelsApi.md#getAvailableModel) | **GET** /models/available/{model_name} | Get information about a specific model available for creation |
*ModelsApi* | [**getAvailableModels**](Apis/ModelsApi.md#getAvailableModels) | **GET** /models/available | Get models available for creation |
*ModelsApi* | [**getEpisodeInfo**](Apis/ModelsApi.md#getEpisodeInfo) | **GET** /models/i/{instance_id}/episodes/{episode_name} | Get episode information |
*ModelsApi* | [**getEpisodes**](Apis/ModelsApi.md#getEpisodes) | **GET** /models/i/{instance_id}/episodes | Get all episodes for a model instance |
*ModelsApi* | [**getModelInstance**](Apis/ModelsApi.md#getModelInstance) | **GET** /models/i/{instance_id} | Get model instance information |
*ModelsApi* | [**getModelInstanceParameters**](Apis/ModelsApi.md#getModelInstanceParameters) | **GET** /models/i/{instance_id}/parameters | Get the parameters of a model instance (current episode) |
*ModelsApi* | [**getModelInstanceState**](Apis/ModelsApi.md#getModelInstanceState) | **GET** /models/i/{instance_id}/state | Get the state of a model instance |
*ModelsApi* | [**getModelInstances**](Apis/ModelsApi.md#getModelInstances) | **GET** /models/instances | Get all created model instances |
*ModelsApi* | [**runInference**](Apis/ModelsApi.md#runInference) | **POST** /models/i/{instance_id}/infer | Run inference |
*ModelsApi* | [**runLearning**](Apis/ModelsApi.md#runLearning) | **POST** /models/i/{instance_id}/learn | Learn from previous observations |
*ModelsApi* | [**wipeEpisode**](Apis/ModelsApi.md#wipeEpisode) | **POST** /models/i/{instance_id}/episodes/{episode_name}/wipe | Wipe all events from an episode |
| *ServerApi* | [**getServerInfo**](Apis/ServerApi.md#getServerInfo) | **GET** /info | Get server information |
*ServerApi* | [**pingServer**](Apis/ServerApi.md#pingServer) | **GET** /ping | Health check endpoint |


<a name="documentation-for-models"></a>
## Documentation for Models

 - [AttachEventsToEpisodeRequest](./Models/AttachEventsToEpisodeRequest.md)
 - [AttachEventsToEpisodeRequest_events_inner](./Models/AttachEventsToEpisodeRequest_events_inner.md)
 - [AttachMetadataToEventRequest](./Models/AttachMetadataToEventRequest.md)
 - [AvailableModel](./Models/AvailableModel.md)
 - [AvailableModel_details](./Models/AvailableModel_details.md)
 - [CreateEpisodeRequest](./Models/CreateEpisodeRequest.md)
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
 - [ModelInstanceParameters](./Models/ModelInstanceParameters.md)
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

