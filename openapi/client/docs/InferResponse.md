# InferResponse


## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**event_id** | **Int64** | Unique identifier for the inference event | [default to nothing]
**results** | **Dict{String, Any}** | Model-specific results of the inference | [default to nothing]
**errors** | [**Vector{ErrorResponse}**](ErrorResponse.md) | List of errors that occurred during the inference call, but were not fatal and the inference was still completed successfully | [default to nothing]


[[Back to Model list]](../README.md#models) [[Back to API list]](../README.md#api-endpoints) [[Back to README]](../README.md)


