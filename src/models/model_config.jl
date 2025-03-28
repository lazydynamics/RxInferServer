
"""
    ModelConfigurationValidationError

A custom error type for model configuration validation errors.
"""
struct ModelConfigurationValidationError <: Exception
    error::String
end

function Base.showerror(io::IO, e::ModelConfigurationValidationError)
    print(io, "model configuration validation error - ", e.error)
end

function Base.convert(::Type{String}, e::ModelConfigurationValidationError)
    return string("model configuration validation error - ", e.error)
end

"""
    validate_model_config_header(config)

Validate the model config header. This includes checking that the config satisfies the model config schema.
The function checks the existence of the following named keys:
- `name` must be a string
- `description` must be a string
- `author` must be a string
- `roles` must be an array of strings

# Arguments
- `config`: The model configuration

# Returns
- `nothing`: If the model configuration is valid
- [`RxInferServer.ModelConfigurationValidationError`](@ref): If the model configuration is invalid
"""
function validate_model_config_header(config)
    if !haskey(config, "name")
        return ModelConfigurationValidationError("model configuration must include a 'name' field")
    end

    if typeof(config["name"]) !== String
        return ModelConfigurationValidationError("model configuration 'name' field must be of type String")
    end

    if !haskey(config, "description")
        return ModelConfigurationValidationError("model configuration must include a 'description' field")
    end

    if typeof(config["description"]) !== String
        return ModelConfigurationValidationError("model configuration 'description' field must be of type String")
    end

    if !haskey(config, "author")
        return ModelConfigurationValidationError("model configuration must include an 'author' field")
    end

    if typeof(config["author"]) !== String
        return ModelConfigurationValidationError("model configuration 'author' field must be of type String")
    end

    if !haskey(config, "roles")
        return ModelConfigurationValidationError("model configuration must include a 'roles' field")
    end

    if typeof(config["roles"]) !== Array{String, 1}
        return ModelConfigurationValidationError("model configuration 'roles' field must be an array of strings")
    end

    return nothing
end

"""
    parse_model_config_default_arguments(config)

Parse the default arguments from the model configuration.

# Arguments
- `config`: The model configuration

# Returns
- `Dict{String, Any}`: The default arguments
"""
function parse_model_config_default_arguments(config)
    if !haskey(config, "arguments")
        return Dict{String, Any}()
    end

    arguments_specification = config["arguments"]
    default_arguments = Dict{String, Any}()

    for arg in arguments_specification
        if haskey(arg, "default")
            default_arguments[arg["name"]] = arg["default"]
        end
    end

    return default_arguments
end

"""
    validate_model_config_required_arguments(config, arguments)

Validate the arguments from the model configuration.
This includes checking that 
- the required arguments are present

# Arguments
- `config`: The model configuration
- `arguments`: The arguments to validate
"""
function validate_model_config_arguments(config, arguments)
    if !haskey(config, "arguments")
        return nothing
    end

    arguments_specification = config["arguments"]

    for arg in arguments_specification
        is_required = haskey(arg, "required") && (arg["required"] == true)
        if is_required
            arg_name = arg["name"]
            if !haskey(arguments, arg_name)
                return ModelConfigurationValidationError(lazy"model configuration argument $(arg_name) is required")
            end
        end
    end

    return nothing
end
