using Mongoc, UUIDs

function generate_token(req::HTTP.Request)::HTTP.Response
    # Check if the token is already in the database
    token = HTTP.header(req, "Authorization", nothing)
    if !isnothing(token)
        token = replace(token, "Bearer " => "")
        return HTTP.Response(200, RxInferServerOpenAPI.TokenResponse(token = token))
    end

    @debug "New token request"
    token = string(UUIDs.uuid4())
    document = Mongoc.BSON("token" => token, "created_at" => Dates.now(), "role" => "user")
    collection = Database.collection("tokens")
    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        @error "Unable to generate token due to internal error"
        return HTTP.Response(400, RxInferServerOpenAPI.ErrorResponse(error = "Bad Request", message = "Unable to generate token due to internal error"))
    end

    @debug "New token generated" token
    return HTTP.Response(200, RxInferServerOpenAPI.TokenResponse(token = token))
end
