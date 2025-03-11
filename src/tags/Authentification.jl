

function generate_token(req::HTTP.Request)::RxInferServerOpenAPI.TokenResponse
    return RxInferServerOpenAPI.TokenResponse(token="1234567890")
end