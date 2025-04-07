
"""
    serialize_state(state)

Serialize the given state to an opaque binary format.
"""
function serialize_state(state)
    serialization_io = IOBuffer()
    serialize(serialization_io, state)
    return take!(serialization_io)
end

"""
    deserialize_state(state_buffer)

Deserialize the given state from an opaque binary format.
"""
function deserialize_state(state_buffer::Vector{UInt8})
    deserialization_io = IOBuffer(state_buffer)
    return deserialize(deserialization_io)
end

"""
    serialize_parameters(parameters)

Serialize the given parameters to an opaque binary format.
"""
function serialize_parameters(parameters)
    return serialize_state(parameters)
end

"""
    deserialize_parameters(parameters_buffer)

Deserialize the given parameters from an opaque binary format.
"""
function deserialize_parameters(parameters_buffer::Vector{UInt8})
    return deserialize_state(parameters_buffer)
end
