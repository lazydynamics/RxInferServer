using Mongoc, UUIDs

function token_generate(req::HTTP.Request)
    # Check if the token is already in the database
    token = HTTP.header(req, "Authorization", nothing)
    if !isnothing(token)
        token = replace(token, "Bearer " => "")
        return RxInferServerOpenAPI.TokenGenerateResponse(token = token)
    end

    @debug "New token request"
    token = string(UUIDs.uuid4())
    inserted = __database_op_insert_token(token)

    if !inserted
        @error "Unable to generate token due to internal error"
        return RxInferServerOpenAPI.ErrorResponse(
            error = "Bad Request", message = "Unable to generate token due to internal error"
        )
    end

    @debug "New token generated" token
    return RxInferServerOpenAPI.TokenGenerateResponse(token = token)
end

function token_roles(req::HTTP.Request)
    return RxInferServerOpenAPI.TokenRolesResponse(roles = current_roles())
end

# Database operations

const __database_op_default_roles = ["user"]
# Insert a token into the database, return true if the token was inserted successfully
function __database_op_insert_token(token::String)::Bool
    document = Mongoc.BSON("token" => token, "created_at" => Dates.now(), "roles" => __database_op_default_roles)
    collection = Database.collection("tokens")
    insert_result = Mongoc.insert_one(collection, document)
    return insert_result.reply["insertedCount"] == 1
end
