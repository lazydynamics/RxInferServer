# Preference based serialization of distributions, such as Normal, Poisson, etc.
# The major problem and potential solution is described here:
# https://github.com/lazydynamics/RxInferServer/issues/59
import RxInfer: Distribution
import RxInfer.BayesBase: params

"""
A module that specifies the encoding format for distribution data.
Is supposed to be used as a namespace for the `DistributionsData` enum.

See also: [`RxInferServer.Serialization.DistributionsRepr`](@ref)
"""
module DistributionsData
"""
Unknown encoding format. Used to indicate that the encoding format is not known or cannot be parsed from the request.
"""
const Unknown::UInt8 = 0x00

"""
Encodes the data of distributions as a dictionary with named parameters.

```jldoctest
julia> import RxInferServer.Serialization: DistributionsData, JSONSerialization, to_json

julia> using RxInfer

julia> s = JSONSerialization(distributions_data = DistributionsData.NamedParams);

julia> to_json(s, NormalMeanVariance(1.0, 2.0))
"{\\"encoding\\":\\"named_params\\",\\"type\\":\\"Distribution{Univariate, Continuous}\\",\\"tag\\":\\"NormalMeanVariance\\",\\"data\\":{\\"μ\\":1.0,\\"v\\":2.0}}"
```

!!! note
    This encoding preserves the semantic meaning of each parameter by using its name as a key in the dictionary.
"""
const NamedParams::UInt8 = 0x01

"""
Encodes the data of distributions as an array of parameters in their natural order.

```jldoctest
julia> import RxInferServer.Serialization: DistributionsData, JSONSerialization, to_json

julia> using RxInfer

julia> s = JSONSerialization(distributions_data = DistributionsData.Params);

julia> to_json(s, NormalMeanVariance(1.0, 2.0))
"{\\"encoding\\":\\"params\\",\\"type\\":\\"Distribution{Univariate, Continuous}\\",\\"tag\\":\\"NormalMeanVariance\\",\\"data\\":[1.0,2.0]}"
```

!!! note
    This encoding is more compact but requires knowledge of the parameter order for each distribution type.
"""
const Params::UInt8 = 0x02

"""
Removes the distribution data from the response entirely.

```jldoctest
julia> import RxInferServer.Serialization: DistributionsData, JSONSerialization, to_json

julia> using RxInfer

julia> s = JSONSerialization(distributions_data = DistributionsData.None);

julia> to_json(s, NormalMeanVariance(1.0, 2.0))
"{\\"encoding\\":\\"none\\",\\"type\\":\\"Distribution{Univariate, Continuous}\\",\\"tag\\":\\"NormalMeanVariance\\",\\"data\\":null}"
```

!!! note
    Use [`RxInferServer.Serialization.DistributionsRepr.Data`](@ref) to remove everything.
"""
const None::UInt8 = 0x03

const OptionName = "distribution_data"
const AvailableOptions = (DistributionsData.NamedParams, DistributionsData.Params, DistributionsData.None)

function to_string(dist_data::UInt8)
    if dist_data == DistributionsData.NamedParams
        return "named_params"
    elseif dist_data == DistributionsData.Params
        return "params"
    elseif dist_data == DistributionsData.None
        return "none"
    else
        return "unknown"
    end
end

function from_string(str::String)
    if str == "named_params"
        return DistributionsData.NamedParams
    elseif str == "params"
        return DistributionsData.Params
    elseif str == "none"
        return DistributionsData.None
    else
        return DistributionsData.Unknown
    end
end
end

"""
Specifies the JSON representation format for distributions.
Is supposed to be used as a namespace for the `DistributionsRepr` enum.

See also: [`RxInferServer.Serialization.DistributionsData`](@ref)
"""
module DistributionsRepr
"""
Unknown representation format. Used to indicate that the representation format is not known or cannot be parsed from the request.
"""
const Unknown::UInt8 = 0x00

"""
Represents the distribution as a dictionary with the following keys:
- `type` set to the distribution type (e.g. `"Distribution{Univariate, Continuous}"`)
- `encoding` set to the selected encoding format (e.g. `"named_params"`)
- `tag` set to the specific distribution tag (e.g. `"NormalMeanVariance"`)
- `data` set to the encoded distribution parameters

```jldoctest
julia> import RxInferServer.Serialization: DistributionsData, DistributionsRepr, JSONSerialization, to_json

julia> using RxInfer

julia> s = JSONSerialization(distributions_repr = DistributionsRepr.Dict, distributions_data = DistributionsData.NamedParams);

julia> to_json(s, NormalMeanVariance(1.0, 2.0))
"{\\"encoding\\":\\"named_params\\",\\"type\\":\\"Distribution{Univariate, Continuous}\\",\\"tag\\":\\"NormalMeanVariance\\",\\"data\\":{\\"μ\\":1.0,\\"v\\":2.0}}"
```
"""
const Dict::UInt8 = 0x01

"""
Same as [`RxInferServer.Serialization.DistributionsRepr.Dict`](@ref), but excludes the `encoding` key, leaving only the `type`, `tag` and `data` keys.

```jldoctest
julia> import RxInferServer.Serialization: DistributionsData, DistributionsRepr, JSONSerialization, to_json

julia> using RxInfer

julia> s = JSONSerialization(distributions_repr = DistributionsRepr.DictTypeAndTag, distributions_data = DistributionsData.NamedParams);

julia> to_json(s, NormalMeanVariance(1.0, 2.0))
"{\\"type\\":\\"Distribution{Univariate, Continuous}\\",\\"tag\\":\\"NormalMeanVariance\\",\\"data\\":{\\"μ\\":1.0,\\"v\\":2.0}}"
```
"""
const DictTypeAndTag::UInt8 = 0x02

"""
Same as [`RxInferServer.Serialization.DistributionsRepr.Dict`](@ref), but excludes the `encoding` and `type` keys, leaving only the `tag` and `data` keys.

```jldoctest
julia> import RxInferServer.Serialization: DistributionsData, DistributionsRepr, JSONSerialization, to_json

julia> using RxInfer

julia> s = JSONSerialization(distributions_repr = DistributionsRepr.DictTag, distributions_data = DistributionsData.NamedParams);

julia> to_json(s, NormalMeanVariance(1.0, 2.0))
"{\\"tag\\":\\"NormalMeanVariance\\",\\"data\\":{\\"μ\\":1.0,\\"v\\":2.0}}"
```
"""
const DictTag::UInt8 = 0x03

"""
Compact representation of the distribution data as returned from the encoding.

```jldoctest
julia> import RxInferServer.Serialization: DistributionsData, DistributionsRepr, JSONSerialization, to_json

julia> using RxInfer

julia> s = JSONSerialization(distributions_repr = DistributionsRepr.Data, distributions_data = DistributionsData.NamedParams);

julia> to_json(s, NormalMeanVariance(1.0, 2.0))
"{\\"μ\\":1.0,\\"v\\":2.0}"
```
"""
const Data::UInt8 = 0x04

const OptionName = "distribution_repr"
const AvailableOptions = (
    DistributionsRepr.Dict, DistributionsRepr.DictTypeAndTag, DistributionsRepr.DictTag, DistributionsRepr.Data
)

function to_string(dist_repr::UInt8)
    if dist_repr == DistributionsRepr.Dict
        return "dict"
    elseif dist_repr == DistributionsRepr.DictTypeAndTag
        return "dict_type_and_tag"
    elseif dist_repr == DistributionsRepr.DictTag
        return "dict_tag"
    elseif dist_repr == DistributionsRepr.Data
        return "data"
    else
        return "unknown"
    end
end

function from_string(str::String)
    if str == "dict"
        return DistributionsRepr.Dict
    elseif str == "dict_type_and_tag"
        return DistributionsRepr.DictTypeAndTag
    elseif str == "dict_tag"
        return DistributionsRepr.DictTag
    elseif str == "data"
        return DistributionsRepr.Data
    else
        return DistributionsRepr.Unknown
    end
end

end

function show_json(io::StructuralContext, serialization::JSONSerialization, value::Distribution)
    dist_data = serialization.distributions_data
    dist_repr = serialization.distributions_repr

    if dist_repr != DistributionsRepr.Data
        begin_object(io)
    end

    if dist_repr == DistributionsRepr.Dict
        show_pair(io, JSON.StandardSerialization(), :encoding => DistributionsData.to_string(dist_data))
        __show_distribution_type(io, serialization, value)
        __show_distribution_tag(io, serialization, value)
        show_key(io, :data)
    elseif dist_repr == DistributionsRepr.DictTypeAndTag
        __show_distribution_type(io, serialization, value)
        __show_distribution_tag(io, serialization, value)
        show_key(io, :data)
    elseif dist_repr == DistributionsRepr.DictTag
        __show_distribution_tag(io, serialization, value)
        show_key(io, :data)
    elseif dist_repr == DistributionsRepr.Data
        # noop
    else
        throw(UnsupportedPreferenceError(dist_repr, DistributionsRepr))
    end

    if dist_data == DistributionsData.NamedParams
        __show_distribution_data_named_params(io, serialization, value)
    elseif dist_data == DistributionsData.Params
        __show_distribution_data_params(io, serialization, value)
    elseif dist_data == DistributionsData.None
        __show_distribution_data_none(io, serialization, value)
    else
        throw(UnsupportedPreferenceError(dist_data, DistributionsData))
    end

    if dist_repr != DistributionsRepr.Data
        end_object(io)
    end
end

function __show_distribution_type(io::StructuralContext, ::JSONSerialization, value::Distribution)
    show_key(io, :type)
    T = typeof(value)
    # dirty hack to remove `Distributions.` from the type name
    type = replace(string(T.super), "$(T.super.name.module)." => "")
    show_json(io, JSON.StandardSerialization(), type)
end

function __show_distribution_tag(io::StructuralContext, ::JSONSerialization, value::Distribution)
    show_key(io, :tag)
    T = typeof(value)
    # dirty hack to remove `ExponentialFamily.` from the tag
    tag = replace(string(T.name.wrapper), "$(T.name.module)." => "")
    show_json(io, JSON.StandardSerialization(), tag)
end

function __show_distribution_data_named_params(
    io::StructuralContext, serialization::JSONSerialization, value::Distribution
)
    begin_object(io)
    for fieldname in fieldnames(typeof(value))
        show_pair(io, serialization, fieldname => getfield(value, fieldname))
    end
    end_object(io)
end

function __show_distribution_data_params(io::StructuralContext, serialization::JSONSerialization, value::Distribution)
    show_json(io, serialization, params(value))
end

function __show_distribution_data_none(io::StructuralContext, serialization::JSONSerialization, value::Distribution)
    show_json(io, serialization, nothing)
end
