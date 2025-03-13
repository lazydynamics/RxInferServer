using Mongoc, UUIDs

function generate_token(req::HTTP.Request)::RxInferServerOpenAPI.TokenResponse
    token = string(UUIDs.uuid4())
    document = Mongoc.BSON("token" => token, "created_at" => Dates.now(), "role" => "user")
    collection = Database.collection("tokens")

    insert_result = Mongoc.insert_one(collection, document)

    if insert_result.reply["insertedCount"] != 1
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request",
            message = "Unable to generate token due to internal error"
        )
    end

    return RxInferServerOpenAPI.TokenResponse(token = token)
end
