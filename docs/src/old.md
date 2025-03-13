## Basic Usage

Here's a simple example of deploying a coin toss model:

```julia
using RxInfer
using RxInferServer

# Define a coin toss model
@model function coin_model(y, a, b)
    θ ~ Beta(a, b)
    for i in eachindex(y)
        y[i] ~ Bernoulli(θ)
    end
end

# Create model specification with constraints and initialization
constraints = @constraints begin
    q(θ, y) = q(θ)q(y)
end

init = @initialization begin
    q(θ) = Beta(1.0, 1.0)
end

# Create and start the server
server = RxInferModelServer()

# Add model endpoint
add_model(
    server,
    "/coin",
    coin_model(a=4.0, b=8.0),
    [:θ],
    constraints=constraints,
    initialization=init,
)

start(server)

# Server will be available at http://localhost:8080
```

You can then make POST requests to the endpoint:

```bash
curl -X POST http://localhost:8080/coin \
     -H "Content-Type: application/json" \
     -d '{"data": {"y": [1,1,0,1,1,0,1]}}'
```

or using Julia:

```julia
using HTTP, JSON3

response = HTTP.post("http://localhost:8080/coin",
                     ["Content-Type" => "application/json"],
                     JSON3.write(Dict("data" => Dict("y" => [1,1,0,1,1,0,1]))))
```

The response will contain the posterior distributions:

```json
{
    "posteriors": {
        "θ": {
            "α": 9.0,
            "β": 10.0
        }
    }
}
```

## Advanced Features

### Inference Parameters

You can control inference parameters through the request body:

```json
{
    "data": {"y": [1,1,0,1,1,0,1]},
    "iterations": 50,
    "free_energy": true
}
```

### Multiple Endpoints

You can add multiple models to the same server:

```julia
# Add a model with few iterations
add_model(server, "/coin-quick", coin_model(a=4.0, b=8.0), [:θ], 
         constraints=constraints, init=init)

# Add same model with more iterations for better accuracy
add_model(server, "/coin-accurate", coin_model(a=4.0, b=8.0), [:θ], 
         constraints=constraints, init=init)
```

### Meta Specifications

Meta specifications allow you to fine-tune the inference behavior:

```julia
struct FastMeta end
struct StableMeta end
# Define different meta specifications for different inference behaviors
meta_fast = @meta begin
    Bernoulli(θ, y) -> FastMeta()
end

meta_stable = @meta begin
    Bernoulli(θ, y) -> StableMeta()
end

# Add endpoints with different meta specifications
add_model(server, "/coin-fast", coin_model(a=4.0, b=8.0), [:θ],
         constraints=constraints, init=init, meta=meta_fast)

add_model(server, "/coin-stable", coin_model(a=4.0, b=8.0), [:θ],
         constraints=constraints, init=init, meta=meta_stable)
```

### Missing Data Handling

The server can handle missing data in the input:

```julia
@model function smoothing_model(x0, y)
    P ~ Gamma(shape=0.001, scale=0.001)
    x_prior ~ Normal(mean=mean(x0), var=var(x0))
    
    local x
    x_prev = x_prior
    
    for i in 1:length(y)
        x[i] ~ Normal(mean=x_prev, precision=1.0)
        y[i] ~ Normal(mean=x[i], precision=P)
        x_prev = x[i]
    end
end

# Data with missing values is handled automatically
data = [1.0, 2.0, missing, 4.0, 5.0]
```

```@docs 
RxInferServer.OldImplementation.start   
RxInferServer.OldImplementation.add_model 
RxInferServer.OldImplementation.add 
RxInferServer.OldImplementation.stop 
RxInferServer.OldImplementation.DeployableRxInferModel
RxInferServer.OldImplementation.RxInferModelServer
```