# Documentation for RxInferServer OpenAPI specification

<a name="documentation-for-api-endpoints"></a>
## Documentation for API Endpoints

All URIs are relative to *http://localhost:8000/v1*

| Class | Method | HTTP request | Description |
|------------ | ------------- | ------------- | -------------|
| *AuthenticationApi* | [**generateToken**](Apis/AuthenticationApi.md#generatetoken) | **POST** /generate-token | Generate authentication token |
| *ModelsApi* | [**attachMetadataToEvent**](Apis/ModelsApi.md#attachmetadatatoevent) | **POST** /models/{model_id}/episodes/{episode_name}/events/{event_id}/attach-metadata | Attach metadata to an event |
*ModelsApi* | [**createEpisode**](Apis/ModelsApi.md#createepisode) | **POST** /models/{model_id}/episodes/{episode_name}/create | Create a new episode for a model |
*ModelsApi* | [**createModel**](Apis/ModelsApi.md#createmodel) | **POST** /models/create | Create a new model instance |
*ModelsApi* | [**deleteEpisode**](Apis/ModelsApi.md#deleteepisode) | **DELETE** /models/{model_id}/episodes/{episode_name}/delete | Delete an episode for a model |
*ModelsApi* | [**deleteModel**](Apis/ModelsApi.md#deletemodel) | **DELETE** /models/{model_id}/delete | Delete a model instance |
*ModelsApi* | [**getCreatedModelsInfo**](Apis/ModelsApi.md#getcreatedmodelsinfo) | **GET** /models/created | Get information about all created models for a specific token |
*ModelsApi* | [**getEpisodeInfo**](Apis/ModelsApi.md#getepisodeinfo) | **GET** /models/{model_id}/episodes/{episode_name} | Get episode information |
*ModelsApi* | [**getEpisodes**](Apis/ModelsApi.md#getepisodes) | **GET** /models/{model_id}/episodes | Get all episodes for a model |
*ModelsApi* | [**getModelDetails**](Apis/ModelsApi.md#getmodeldetails) | **GET** /models/{model_name}/details | Get model details |
*ModelsApi* | [**getModelInfo**](Apis/ModelsApi.md#getmodelinfo) | **GET** /models/{model_id}/info | Get model information |
*ModelsApi* | [**getModelState**](Apis/ModelsApi.md#getmodelstate) | **GET** /models/{model_id}/state | Get the state of a model |
*ModelsApi* | [**getModels**](Apis/ModelsApi.md#getmodels) | **GET** /models | Get models |
*ModelsApi* | [**runAction**](Apis/ModelsApi.md#runaction) | **POST** /models/{model_id}/act | Run action on a model |
*ModelsApi* | [**runInference**](Apis/ModelsApi.md#runinference) | **POST** /models/{model_id}/infer | Run inference on a model |
*ModelsApi* | [**runLearning**](Apis/ModelsApi.md#runlearning) | **POST** /models/{model_id}/learn | Learn from previous observations |
*ModelsApi* | [**runPlanning**](Apis/ModelsApi.md#runplanning) | **POST** /models/{model_id}/plan | Run planning on a model |
*ModelsApi* | [**wipeEpisode**](Apis/ModelsApi.md#wipeepisode) | **POST** /models/{model_id}/episodes/{episode_name}/wipe | Wipe all events from an episode |
| *ServerApi* | [**getServerInfo**](Apis/ServerApi.md#getserverinfo) | **GET** /info | Get server information |
*ServerApi* | [**pingServer**](Apis/ServerApi.md#pingserver) | **GET** /ping | Health check endpoint |


<a name="documentation-for-models"></a>
## Documentation for Models

 - [ActionRequest](./Models/ActionRequest.md)
 - [ActionResponse](./Models/ActionResponse.md)
 - [AttachMetadataToEventRequest](./Models/AttachMetadataToEventRequest.md)
 - [CreateModelRequest](./Models/CreateModelRequest.md)
 - [CreateModelResponse](./Models/CreateModelResponse.md)
 - [CreatedModelInfo](./Models/CreatedModelInfo.md)
 - [DeleteModelRequest](./Models/DeleteModelRequest.md)
 - [EpisodeInfo](./Models/EpisodeInfo.md)
 - [ErrorResponse](./Models/ErrorResponse.md)
 - [InferRequest](./Models/InferRequest.md)
 - [InferResponse](./Models/InferResponse.md)
 - [LearnRequest](./Models/LearnRequest.md)
 - [LearnResponse](./Models/LearnResponse.md)
 - [LightweightModelDetails](./Models/LightweightModelDetails.md)
 - [ModelDetails](./Models/ModelDetails.md)
 - [ModelList](./Models/ModelList.md)
 - [ModelState](./Models/ModelState.md)
 - [NotFoundResponse](./Models/NotFoundResponse.md)
 - [PingResponse](./Models/PingResponse.md)
 - [PlanningRequest](./Models/PlanningRequest.md)
 - [PlanningResponse](./Models/PlanningResponse.md)
 - [ServerInfo](./Models/ServerInfo.md)
 - [SuccessResponse](./Models/SuccessResponse.md)
 - [TokenResponse](./Models/TokenResponse.md)
 - [UnauthorizedResponse](./Models/UnauthorizedResponse.md)


<a name="documentation-for-authorization"></a>
## Documentation for Authorization

<a name="ApiKeyAuth"></a>
### ApiKeyAuth

- **Type**: HTTP Bearer Token authentication

