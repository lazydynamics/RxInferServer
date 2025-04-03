
function initial_state(arguments)
    size = arguments["size"]

    matrix = zeros(Float64, size, size)
    counter = 1
    for i in 1:size
        for j in 1:size
            matrix[i, j] = counter
            counter += 1
        end
    end

    return Dict("matrix" => matrix)
end

function initial_parameters(arguments)
    return Dict()
end
