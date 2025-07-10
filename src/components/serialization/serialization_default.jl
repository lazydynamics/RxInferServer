# OpenAPI has the following types defined
# https://swagger.io/docs/specification/v3_0/data-models/data-types/
# - string (this includes dates and files)
# - number 
# - integer
# - boolean
# - array 
# - object
show_json(io::StructuralContext, ::JSONSerialization, value::Symbol) = show_json(
    io, JSON.StandardSerialization(), string(value)
)
show_json(io::StructuralContext, ::JSONSerialization, value::String) = show_json(
    io, JSON.StandardSerialization(), value
)
show_json(io::StructuralContext, ::JSONSerialization, value::Number) = show_json(
    io, JSON.StandardSerialization(), value
)
show_json(io::StructuralContext, ::JSONSerialization, value::Bool) = show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::JSONSerialization, value::Union{Missing, Nothing}) = show_json(
    io, JSON.StandardSerialization(), value
)

# String - date-time including timezones
using Dates, TimeZones

show_json(io::StructuralContext, ::JSONSerialization, value::Date) = show_json(io, JSON.StandardSerialization(), value)
show_json(io::StructuralContext, ::JSONSerialization, value::DateTime) = show_json(
    io, JSON.StandardSerialization(), value
)
show_json(io::StructuralContext, ::JSONSerialization, value::ZonedDateTime) = show_json(
    io, JSON.StandardSerialization(), value
)

# Vector-like values
show_json(io::StructuralContext, s::JSONSerialization, value::Tuple) = __json_serialization_vector_like(io, s, value)
show_json(io::StructuralContext, s::JSONSerialization, value::AbstractVector) = __json_serialization_vector_like(
    io, s, value
)

function __json_serialization_vector_like(io::StructuralContext, s::JSONSerialization, vectorlike)
    begin_array(io)
    foreach(element -> show_element(io, s, element), vectorlike)
    end_array(io)
end

# Dict-like values
show_json(io::StructuralContext, s::JSONSerialization, value::NamedTuple) = __json_serialization_dict_like(io, s, value)
show_json(io::StructuralContext, s::JSONSerialization, value::AbstractDict) = __json_serialization_dict_like(
    io, s, value
)

function __json_serialization_dict_like(io::StructuralContext, s::JSONSerialization, dictlike)
    begin_object(io)
    foreach(pair -> show_pair(io, s, pair), pairs(dictlike))
    end_object(io)
end
