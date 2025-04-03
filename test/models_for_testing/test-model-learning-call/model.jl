
function initial_state(arguments)
    return Dict("number_of_inference_calls" => 0, "number_of_learning_calls" => 0)
end

function initial_parameters(arguments)
    return Dict("parameter" => 0)
end

function run_inference(state, parameters, data)
    state["number_of_inference_calls"] += 1
    result = data
    return result, state
end

function run_learning(state, parameters, events)
    parameter = 0
    for event in events
        parameter += event["data"]["observation"]
    end
    parameters["parameter"] = parameter
    state["number_of_learning_calls"] += 1

    result = Dict("parameter" => parameter)
    return result, state, parameters
end
