

function generate_token(req::HTTP.Request)::RxInferServerOpenAPI.TokenResponse
    return RxInferServerOpenAPI.TokenResponse(token="123456789")
end