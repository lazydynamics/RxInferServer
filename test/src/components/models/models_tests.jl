using Test
using RxInferServer.Models

@testitem "with_models" setup = [TestUtils] begin
    import RxInferServer.Models
    import Logging

    @test_throws "Models dispatcher is not initialized" Models.get_models()
    @test_throws "Models dispatcher is not initialized" Models.get_model("BetaBernoulli-v1")

    Models.with_models(locations = [TestUtils.projectdir("models")]) do
        models = Models.get_models()
        @test !isempty(models)

        model = Models.get_model("BetaBernoulli-v1")
        @test model.name == "BetaBernoulli-v1"
    end

    tmpdir_created = mktempdir(; prefix = "models_created")

    io = IOBuffer()
    Logging.with_logger(Logging.SimpleLogger(io, Logging.Info)) do
        Models.with_models(locations = [tmpdir_created, TestUtils.projectdir("models")]) do
            models = Models.get_models()
            @test !isempty(models)

            model = Models.get_model("BetaBernoulli-v1")
            @test model.name == "BetaBernoulli-v1"
        end
    end

    # No logs should be produced by the logger for the previous case
    @test isempty(String(take!(io)))

    # Warning for non-existent directory
    tmpdir_notcreated = joinpath(tempdir(), "models_not_created")

    io = IOBuffer()
    Logging.with_logger(Logging.SimpleLogger(io, Logging.Info)) do
        Models.with_models(locations = [tmpdir_notcreated]) do
            @test true
        end
    end

    # Warning for non-existent directory
    @test occursin(
        "Warning: Cannot load models from `$(tmpdir_notcreated)` because it does not exist or is not a directory",
        String(take!(io))
    )

    # Warning for directory that is not a directory
    tmpdir_notdir, _ = mktemp()

    io = IOBuffer()
    Logging.with_logger(Logging.SimpleLogger(io, Logging.Info)) do
        Models.with_models(locations = [tmpdir_notdir]) do
            @test true
        end
    end

    @test occursin(
        "Warning: Cannot load models from `$(tmpdir_notdir)` because it does not exist or is not a directory",
        String(take!(io))
    )
end
