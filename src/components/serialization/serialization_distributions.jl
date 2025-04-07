# Preference based serialization of distributions, such as Normal, Poisson, etc.
# The major problem and potential solution is described here:
# https://github.com/lazydynamics/RxInferServer/issues/59
import RxInfer: Distribution
import RxInfer.BayesBase: params

module DistributionsData
const Unknown::UInt8 = 0x00

const NamedParams::UInt8 = 0x01

const Params::UInt8 = 0x02

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
end

module DistributionsRepr
const Unknown::UInt8 = 0x00

const Dict::UInt8 = 0x01

const DictTypeAndTag::UInt8 = 0x02

const DictTag::UInt8 = 0x03

const Data::UInt8 = 0x04

const OptionName = "distribution_repr"
const AvailableOptions = (
    DistributionsRepr.Dict, DistributionsRepr.DictTypeAndTag, DistributionsRepr.DictTag, DistributionsRepr.Data
)

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
        # noop
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
