
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

