using RxInfer, LinearAlgebra

function initial_state(arguments)
    return Dict(
        "dt" => arguments["dt"],
        "horizon" => arguments["horizon"],
        "gravity" => arguments["gravity"],
        "mass" => arguments["mass"],
        "radius" => arguments["radius"],
        "arm_length" => arguments["arm_length"],
        "force_limit" => arguments["force_limit"],
        "inertia" => arguments["inertia"]
    )
end

function initial_parameters(arguments)
    return Dict()
end

Base.@kwdef struct Drone
    gravity::Float64
    mass::Float64
    inertia::Vector{Float64}
    radius::Float64
    arm_length::Float64
    force_limit::Float64
end

get_gravity(drone::Drone) = drone.gravity
get_mass(drone::Drone) = drone.mass
get_inertia(drone::Drone) = Matrix(Diagonal(drone.inertia))
get_radius(drone::Drone) = drone.radius
get_arm_length(drone::Drone) = drone.arm_length
get_force_limit(drone::Drone) = drone.force_limit

function get_properties(drone::Drone)
    return (
        drone.gravity, drone.mass, Matrix(Diagonal(drone.inertia)), drone.radius, drone.arm_length, drone.force_limit
    )
end

function rotation_matrix(ψ, θ, ϕ)
    # Rotation matrices for each axis
    Rz = [
        cos(ψ) -sin(ψ) 0
        sin(ψ) cos(ψ) 0
        0 0 1
    ]

    Ry = [
        cos(θ) 0 sin(θ)
        0 1 0
        -sin(θ) 0 cos(θ)
    ]

    Rx = [
        1 0 0
        0 cos(ϕ) -sin(ϕ)
        0 sin(ϕ) cos(ϕ)
    ]

    # Combined rotation matrix (ZYX order)
    return Rz * Ry * Rx
end

function state_transition_3d(state, actions, drone, dt)
    # Extract properties
    g, m, I, r, L, limit = get_properties(drone)

    # Clamp motor forces
    F1, F2, F3, F4 = clamp.(actions, 0, limit)

    # Extract state
    x, y, z, vx, vy, vz, ϕ, θ, ψ, ωx, ωy, ωz = state

    # Current rotation matrix
    R = rotation_matrix(ψ, θ, ϕ)

    # Total thrust force in body frame
    F_total = sum([F1, F2, F3, F4])

    # Compute torques
    τx = L * (F2 - F4)  # roll torque
    τy = L * (F1 - F3)   # pitch torque
    τz = (F1 + F3 - F2 - F4) * r  # yaw torque

    # Forces in world frame
    F_world = R * [0, 0, F_total]

    # Accelerations
    ax = F_world[1] / m
    ay = F_world[2] / m
    az = F_world[3] / m - g

    # Angular accelerations
    α = I \ ([τx, τy, τz] - cross([ωx, ωy, ωz], I * [ωx, ωy, ωz]))

    # Update velocities
    vx_new = vx + ax * dt
    vy_new = vy + ay * dt
    vz_new = vz + az * dt

    # Update positions
    x_new = x + vx * dt + ax * dt^2 / 2
    y_new = y + vy * dt + ay * dt^2 / 2
    z_new = z + vz * dt + az * dt^2 / 2

    # Update angular velocities
    ωx_new = ωx + α[1] * dt
    ωy_new = ωy + α[2] * dt
    ωz_new = ωz + α[3] * dt

    # Update angles
    ϕ_new = ϕ + ωx * dt + α[1] * dt^2 / 2
    θ_new = θ + ωy * dt + α[2] * dt^2 / 2
    ψ_new = ψ + ωz * dt + α[3] * dt^2 / 2

    return [x_new, y_new, z_new, vx_new, vy_new, vz_new, ϕ_new, θ_new, ψ_new, ωx_new, ωy_new, ωz_new]
end

@model function drone_model_3d(drone, initial_state, goal, horizon, dt)
    # Extract properties
    g = get_gravity(drone)
    m = get_mass(drone)

    # Initial state prior
    s[1] ~ MvNormal(mean = initial_state, covariance = 1e-5 * I)

    for i in 1:horizon
        # Prior on motor actions (mean compensates for gravity)
        hover_force = m * g / 4
        u[i] ~ MvNormal(μ = [hover_force, hover_force, hover_force, hover_force], Σ = 1e-1 * diageye(4))

        # State transition
        s[i + 1] ~ MvNormal(μ = state_transition_3d(s[i], u[i], drone, dt), Σ = 1e-10 * I)
    end

    s[end] ~ MvNormal(mean = goal, covariance = 1e-3 * diageye(12))
end

@meta function drone_meta_3d()
    # approximate the state transition function using the Unscented transform
    state_transition_3d() -> Unscented()
end

function move_to_target_3d(drone, start, target, horizon, dt)
    results = infer(
        model = drone_model_3d(drone = drone, horizon = horizon, dt = dt),
        data = (initial_state = start, goal = [target[1], target[2], target[3], 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        meta = drone_meta_3d(),
        returnvars = (s = KeepLast(), u = KeepLast())
        # options = (limit_stack_depth = 200,)
    )

    states = mean.(results.posteriors[:s])
    actions = mean.(results.posteriors[:u])

    next_state = state_transition_3d(start, actions[1], drone, dt)

    return Dict(
        "actions" => actions,
        "states" => states,
        "next_state" => next_state
        # "next_state" => states[2]
    )
end

function run_inference(state, parameters, data)
    current_state = Float64.(data["current_state"])
    target = data["target"]
    horizon = state["horizon"]
    dt = state["dt"]
    drone = Drone(
        gravity = state["gravity"],
        mass = state["mass"],
        inertia = state["inertia"],
        radius = state["radius"],
        force_limit = state["force_limit"],
        arm_length = state["arm_length"]
    )
    results = move_to_target_3d(drone, current_state, target, horizon, dt)
    return results, state
end

function run_learning(state, parameters, events)
    error("Not available for this model")
end