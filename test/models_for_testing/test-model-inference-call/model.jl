
function initial_state(arguments)
    return Dict("number_of_inference_calls" => 0)
end

function initial_parameters(arguments)
    return arguments
end

function run_inference(state, parameters, data)
    state["number_of_inference_calls"] += 1
    result = data
    return result, state
end
