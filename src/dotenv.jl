using DotEnv

"""
    RXINFER_SERVER_ENV() -> String

Controls which .env files are loaded by the server.

Returns the value of the `RXINFER_SERVER_ENV` environment variable, 
which determines the environment-specific configuration files to load.
Defaults to an empty string when the environment variable is not set.

By default, values already set in the environment variable are not overridden by the .env files.
Set [`RXINFER_SERVER_ENV_OVERRIDE`](@ref) to `true` to override existing values.

## Files Loaded Based on Environment Value

| Environment Value    | .env Files Loaded                                   |
|----------------------|-----------------------------------------------------|
| `""` (default)       | `.env.local`, `.env`                                |
| `"production"`       | `.env.production.local`, `.env.production`, `.env`  |
| `"development"`      | `.env.development.local`, `.env.development`, `.env`|
| `"test"`             | `.env.test.local`, `.env.test`, `.env`              |
| `"local"`            | `.env.local.local`, `.env.local`, `.env`            |
| Custom value `"xyz"` | `.env.xyz.local`, `.env.xyz`, `.env`                |

If the same key is defined in multiple files, the first occurrence of the key is used (e.g the `.env.local` file takes precedence over the `.env` file).
However, if the `RXINFER_SERVER_ENV_OVERRIDE` environment variable is set to `true`, the last occurrence of the key is used instead (e.g the `.env` file takes precedence over the `.env.local` file).

All files are assumed to be in the directory specified by the `RXINFER_SERVER_ENV_PWD` environment variable.
If this variable is not set, the current working directory (`pwd()`) is used instead.

!!! warning
    Never store sensitive information in the .env files.
    The .env files are included in the repository by default to simplify the setup process.
    In a production environment, sensitive information should be stored in a more secure manner,
    such as in environment variables or in a secrets manager.

!!! note 
    Both [`RXINFER_SERVER_ENV`](@ref) and [`RXINFER_SERVER_ENV_PWD`](@ref) cannot be set via the .env files 
    as they are accessed before the .env files are loaded.
"""
RXINFER_SERVER_ENV() = get(ENV, "RXINFER_SERVER_ENV", "")

"""
    RXINFER_SERVER_ENV_PWD() -> String

Returns the directory in which to search for .env files.
Defaults to the current working directory (`pwd()`) when the environment variable is not set.

!!! note 
    Both [`RXINFER_SERVER_ENV`](@ref) and [`RXINFER_SERVER_ENV_PWD`](@ref) cannot be set via the .env files 
    as they are accessed before the .env files are loaded.
"""
RXINFER_SERVER_ENV_PWD() = get(ENV, "RXINFER_SERVER_ENV_PWD", pwd())

"""
    RXINFER_SERVER_ENV_OVERRIDE() -> Bool

Returns the value of the `RXINFER_SERVER_ENV_OVERRIDE` environment variable.
Defaults to `false` when the environment variable is not set.

If `RXINFER_SERVER_ENV_OVERRIDE` environment variable is set to `true`, 
values already set in the environment variable are overridden by the .env files.

See also: [`RXINFER_SERVER_ENV`](@ref), [`RXINFER_SERVER_ENV_PWD`](@ref).
"""
RXINFER_SERVER_ENV_OVERRIDE() = lowercase(get(ENV, "RXINFER_SERVER_ENV_OVERRIDE", "false")) == "true"

mutable struct DotEnvFile
    path::String
    found::Bool
end

DotEnvFile(path::String) = DotEnvFile(path, false)

Base.show(io::IO, f::DotEnvFile) = print(io, basename(f.path), " (", f.found ? "loaded" : "missing", ")")

function load_dotenv()
    env = RXINFER_SERVER_ENV()
    env_pwd = RXINFER_SERVER_ENV_PWD()

    try_to_load_paths = isempty(env) ? [".env.local", ".env"] : [".env.$env.local", ".env.$env", ".env"]
    try_to_load_paths = map(path -> joinpath(env_pwd, path), try_to_load_paths)
    try_to_load = map(f -> DotEnvFile(f), try_to_load_paths)

    for env_file in try_to_load
        if isfile(env_file.path)
            env_file.found = true
        end
    end

    override = RXINFER_SERVER_ENV_OVERRIDE()

    to_load = map(f -> f.path, filter(f -> f.found, try_to_load))
    DotEnv.load!(ENV, to_load; override = override)

    return try_to_load
end

function unload_dotenv(dot_env_files)
    DotEnv.unload!(ENV, map(f -> f.path, filter(f -> f.found, dot_env_files)))
end
