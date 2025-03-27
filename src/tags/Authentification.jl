using Mongoc, UUIDs

function token_generate(req::HTTP.Request)
    # Check if the token is already in the database
    # We cannot use `current_token()` here because 
    # middleware bypasses the authentication check for this endpoint
    token = HTTP.header(req, "Authorization", nothing)
    if !isnothing(token)
        token = replace(token, "Bearer " => "")
        return RxInferServerOpenAPI.TokenGenerateResponse(token = token)
    end

    token = @expect __database_op_create_new_token() || RxInferServerOpenAPI.ErrorResponse(
        error = "Bad Request", message = "Unable to generate token due to internal error"
    )

    return RxInferServerOpenAPI.TokenGenerateResponse(token = token)
end

function token_roles(req::HTTP.Request)
    return RxInferServerOpenAPI.TokenRolesResponse(roles = current_roles())
end

# Database operations

function __database_op_create_new_token()
    token = string(UUIDs.uuid4())
    roles = ["user"]

    @debug "Inserting new token into the database" token
    document = Mongoc.BSON("token" => token, "created_at" => Dates.now(), "roles" => roles)
    collection = Database.collection("tokens")
    result = Mongoc.insert_one(collection, document)

    if result.reply["insertedCount"] != 1
        @debug "Cannot insert token into the database" token
        return nothing
    end

    @debug "Successfully inserted token into the database" token
    return token
end
