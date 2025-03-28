
@testitem "ModelConfigurationValidationError should be a custom error type" begin
    import RxInferServer.Models: ModelConfigurationValidationError
    @test_throws "model configuration validation error - test" throw(ModelConfigurationValidationError("test"))
    @test_throws "model configuration validation error - some error" throw(
        ModelConfigurationValidationError("some error")
    )
end

@testitem "ModelConfigurationValidationError should be convertable to a string" begin
    import RxInferServer.Models: ModelConfigurationValidationError
    struct SomeCustomStructure 
        error::String
    end
    error = ModelConfigurationValidationError("test")
    structure = SomeCustomStructure(error)
    @test structure.error == "model configuration validation error - test"
end

@testitem "parse header should not return an error for a valid model configuration" begin
    import RxInferServer.Models: validate_model_config_header
    import YAML
    config_file = """
    name: MyModel-v1
    description: A model for predicting the weather
    author: John Doe
    roles:
      - user
    """
    config = YAML.load(config_file)

    @test isnothing(validate_model_config_header(config))
end

@testitem "parse header should return an error for missing fields" begin
    import RxInferServer.Models: validate_model_config_header, ModelConfigurationValidationError
    import YAML

    @testset "missing name" begin
        config_file = """
        description: A model for predicting the weather
        author: John Doe
        roles:
          - user
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration must include a 'name' field")
    end

    @testset "missing description" begin
        config_file = """
        name: MyModel-v1
        author: John Doe
        roles:
          - user
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration must include a 'description' field")
    end

    @testset "missing author" begin
        config_file = """
        name: MyModel-v1
        description: A model for predicting the weather
        roles:
          - user
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration must include an 'author' field")
    end

    @testset "missing roles" begin
        config_file = """
        name: MyModel-v1
        description: A model for predicting the weather
        author: John Doe
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration must include a 'roles' field")
    end
end

@testitem "parse header should return an error for invalid types" begin
    import RxInferServer.Models: validate_model_config_header, ModelConfigurationValidationError
    import YAML

    @testset "name is not a string" begin
        config_file = """
        name: 123
        description: A model for predicting the weather
        author: John Doe
        roles:
          - user
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration 'name' field must be of type String")
    end

    @testset "description is not a string" begin
        config_file = """
        name: MyModel-v1
        description: 123
        author: John Doe
        roles:
          - user
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration 'description' field must be of type String")
    end

    @testset "author is not a string" begin
        config_file = """
        name: MyModel-v1
        description: A model for predicting the weather
        author: 123
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration 'author' field must be of type String")
    end

    @testset "roles is not an array of strings" begin
        config_file = """
        name: MyModel-v1
        description: A model for predicting the weather
        author: John Doe
        roles:
          - 1
          - user
        """
        config = YAML.load(config_file)
        @test validate_model_config_header(config) ==
            ModelConfigurationValidationError("model configuration 'roles' field must be an array of strings")
    end
end

@testitem "parse_default_arguments_from_config" begin
    import RxInferServer.Models: parse_model_config_default_arguments

    # Test with empty config
    empty_config = Dict()
    @test parse_model_config_default_arguments(empty_config) == Dict{String, Any}()

    # Test with config that has no default arguments
    no_defaults_config = Dict(
        "arguments" => [Dict("name" => "arg1", "type" => "int"), Dict("name" => "arg2", "type" => "float")]
    )
    @test parse_model_config_default_arguments(no_defaults_config) == Dict{String, Any}()

    # Test with config that has default arguments
    with_defaults_config = Dict(
        "arguments" => [
            Dict("name" => "prior_a", "type" => "int", "default" => 1),
            Dict("name" => "prior_b", "type" => "int", "default" => 1),
            Dict("name" => "no_default", "type" => "string")
        ]
    )
    expected = Dict{String, Any}("prior_a" => 1, "prior_b" => 1)
    @test parse_model_config_default_arguments(with_defaults_config) == expected

    # Test with mixed types of default values
    mixed_types_config = Dict(
        "arguments" => [
            Dict("name" => "int_arg", "type" => "int", "default" => 42),
            Dict("name" => "float_arg", "type" => "float", "default" => 3.14),
            Dict("name" => "string_arg", "type" => "string", "default" => "hello"),
            Dict("name" => "bool_arg", "type" => "boolean", "default" => true)
        ]
    )
    expected_mixed = Dict{String, Any}(
        "int_arg" => 42, "float_arg" => 3.14, "string_arg" => "hello", "bool_arg" => true
    )
    @test parse_model_config_default_arguments(mixed_types_config) == expected_mixed
end

@testitem "validate_model_config_arguments" begin
    import RxInferServer.Models: validate_model_config_arguments, ModelConfigurationValidationError
    import YAML

    @testset begin
        config_file = """
        arguments:
          - name: arg1
            required: false
          - name: arg2
            required: false
        """
        config = YAML.load(config_file)

        @test isnothing(validate_model_config_arguments(config, Dict{String, Any}("arg1" => 1, "arg2" => 2.0)))
        @test isnothing(validate_model_config_arguments(config, Dict{String, Any}("arg1" => 1)))
        @test isnothing(validate_model_config_arguments(config, Dict{String, Any}("arg2" => 2.0)))
        @test isnothing(validate_model_config_arguments(config, Dict{String, Any}()))
    end

    @testset begin
        config_file = """
        arguments:
          - name: arg1
            required: true
          - name: arg2
            required: false
        """
        config = YAML.load(config_file)

        @test isnothing(validate_model_config_arguments(config, Dict{String, Any}("arg1" => 1, "arg2" => 2.0)))
        @test isnothing(validate_model_config_arguments(config, Dict{String, Any}("arg1" => 1)))

        @test validate_model_config_arguments(config, Dict{String, Any}("arg2" => 2.0)) ==
            ModelConfigurationValidationError("model configuration argument arg1 is required")
    end

    @testset begin
        config_file = """
        arguments:
          - name: arg1
            required: true
          - name: arg2
            required: true
        """
        config = YAML.load(config_file)

        @test isnothing(validate_model_config_arguments(config, Dict{String, Any}("arg1" => 1, "arg2" => 2.0)))

        @test validate_model_config_arguments(config, Dict{String, Any}("arg1" => 2.0)) ==
            ModelConfigurationValidationError("model configuration argument arg2 is required")

        @test validate_model_config_arguments(config, Dict{String, Any}("arg2" => 2.0)) ==
            ModelConfigurationValidationError("model configuration argument arg1 is required")

        @test validate_model_config_arguments(config, Dict{String, Any}()) ==
            ModelConfigurationValidationError("model configuration argument arg1 is required")
    end
end