using RxInfer

export DeployableRxInferModel

"""
    DeployableRxInferModel

A wrapper for RxInfer models that can be deployed as a service.

# Fields
- `model`: The RxInfer model specification (a `GraphPPL.ModelGenerator`)
- `constraints`: The constraint specification for the model
- `init`: The initialization specification for the model
- `meta`: The meta specification for the model
"""
struct DeployableRxInferModel{M,C,I,ME}
    model::M
    constraints::C
    init::I
    meta::ME

    function DeployableRxInferModel(model, constraints=nothing, init=nothing, meta=nothing)
        new{typeof(model),typeof(constraints),typeof(init),typeof(meta)}(model, constraints, init, meta)
    end
end

"""
    (model::DeployableRxInferModel)(data, output; kwargs...)

Run inference on the model with the given data and return the specified output posteriors.

# Arguments
- `data`: A NamedTuple mapping data names to their values
- `output`: A collection of variable names to return posteriors for
- `kwargs...`: Additional keyword arguments passed to `infer` (e.g., iterations, free_energy)

# Returns
- A dictionary mapping the requested output names to their posterior distributions
"""
function (model::DeployableRxInferModel)(data::NamedTuple, output; kwargs...)
    # Run inference with the model specification
    inference_result = infer(
        model=model.model,
        data=data,
        constraints=model.constraints,
        initialization=model.init,
        meta=model.meta;
        kwargs...  # Forward any additional kwargs to infer
    )

    result = Dict()
    result["posteriors"] = Dict(name => inference_result.posteriors[name] for name in output)
    if haskey(kwargs, :free_energy) && kwargs[:free_energy]
        result["free_energy"] = inference_result.free_energy
    end
    return result
end

"""
    (model::DeployableRxInferModel)(; kwargs...)

Alternative method that accepts data and inference parameters as keyword arguments.

# Arguments
- `kwargs`: Keyword arguments for:
  - data values
  - output specification (required)
  - inference parameters (e.g., iterations, free_energy)

# Returns
- A dictionary mapping the requested output names to their posterior distributions

# Example```julia
model(
    x=[1.0, 2.0], 
    y=[3.0, 4.0], 
    output=[:z],
    iterations=100,  # passed to infer
    free_energy=true  # passed to infer
)```
"""
function (model::DeployableRxInferModel)(; kwargs...)
    # Split kwargs into data, output, and inference parameters
    kwargs_dict = Dict(kwargs)

    # Extract data specification
    data = pop!(kwargs_dict, :data)
    if haskey(kwargs_dict, :factorize)
        factorize = pop!(kwargs_dict, :factorize)
        data = NamedTuple{keys(data)}([factorize[key] ? value : UnfactorizedData(value) for (key, value) in pairs(data)])
    end

    # Extract output specification
    if !haskey(kwargs_dict, :output)
        throw(ArgumentError("Must specify 'output' keyword argument"))
    end

    output = pop!(kwargs_dict, :output)

    # Call the main method with the separated arguments
    return model(data, output; kwargs_dict...)
end

