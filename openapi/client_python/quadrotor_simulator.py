"""
Python implementation of the Julia quadrotor dynamics simulation.
"""

import numpy as np
import math

# --- Constants (0-based Python indexing) ---
POS_DIM = 3
VEL_DIM = 3
QUAT_DIM = 4
ANG_VEL_DIM = 3
ROTOR_DIM = 4
STATE_DIM_TOTAL = POS_DIM + VEL_DIM + QUAT_DIM + ANG_VEL_DIM + ROTOR_DIM # 17
CONTROL_DIM_TOTAL = ROTOR_DIM # 4

# Slices for accessing state vector parts
POS_SLICE = slice(0, POS_DIM)                       # 0:3
VEL_SLICE = slice(POS_DIM, POS_DIM + VEL_DIM)       # 3:6
QUAT_SLICE = slice(POS_DIM + VEL_DIM, POS_DIM + VEL_DIM + QUAT_DIM) # 6:10
ANG_VEL_SLICE = slice(POS_DIM + VEL_DIM + QUAT_DIM,
                      POS_DIM + VEL_DIM + QUAT_DIM + ANG_VEL_DIM) # 10:13
ROTOR_SLICE = slice(POS_DIM + VEL_DIM + QUAT_DIM + ANG_VEL_DIM,
                    STATE_DIM_TOTAL)                # 13:17

# --- Helper Functions ---

def saturation(u, ubar):
    """Apply saturation to a value or array."""
    return np.sign(u) * np.minimum(np.abs(u), ubar)

def deadzone(u, ubar):
    """Apply deadzone to a value or array."""
    return u - saturation(u, ubar)

def saturation_deadzone(u, ubar1, ubar2):
    """Apply deadzone then saturation."""
    # Note: Julia implementation uses saturation(deadzone(u, ubar1), ubar2)
    # This seems different from typical usage where saturation limits output range.
    # Replicating Julia logic: apply deadzone first, then saturate the result.
    dz_output = deadzone(u, ubar1)
    return saturation(dz_output, ubar2)

def quaternion_to_rotation_matrix(q):
    """
    Convert a quaternion (q0, q1, q2, q3) to a 3x3 rotation matrix.
    q0 is the scalar part. NumPy array input/output.
    """
    q0, q1, q2, q3 = q[0], q[1], q[2], q[3]
    R = np.array([
        [1 - 2*(q2**2 + q3**2), 2*(q1*q2 - q0*q3),   2*(q1*q3 + q0*q2)],
        [2*(q1*q2 + q0*q3),   1 - 2*(q1**2 + q3**2), 2*(q2*q3 - q0*q1)],
        [2*(q1*q3 - q0*q2),   2*(q2*q3 + q0*q1),   1 - 2*(q1**2 + q2**2)]
    ])
    return R

def quaternion_derivative(q, omega):
    """
    Calculate the time derivative of a quaternion given angular velocity.
    q = [q0, q1, q2, q3], omega = [wx, wy, wz]. NumPy array input/output.
    """
    q0, q1, q2, q3 = q[0], q[1], q[2], q[3]
    wx, wy, wz = omega[0], omega[1], omega[2]

    dq0 = -0.5 * (q1*wx + q2*wy + q3*wz)
    dq1 =  0.5 * (q0*wx + q2*wz - q3*wy)
    dq2 =  0.5 * (-q1*wz + q0*wy + q3*wx)
    dq3 =  0.5 * (q1*wy - q2*wx + q0*wz)

    return np.array([dq0, dq1, dq2, dq3])

def at_time(x, t):
    """Evaluate x at time t if x is callable, otherwise return x."""
    return x(t) if callable(x) else x

def at_position(x, p):
    """Evaluate x at position p if x is callable, otherwise return x."""
    return x(p) if callable(x) else x

# --- Parameters ---

def default_parameters():
    """Return a dictionary containing the default drone parameters."""
    return {
        "m": 0.65,       # Mass [kg]
        "g": 9.81,       # Gravity [m/s²]
        "l": 0.232,      # Arm length [m]
        "rho": 1.293,    # Air density [kg/m³]
        "d": 1.5e-4,     # Rotor drag coefficient [Nm s²] (Corrected from Julia name 'd')
        "Jx": 7.5e-3,    # Inertia moment around x-axis [kg m²]
        "Jy": 7.5e-3,    # Inertia moment around y-axis [kg m²]
        "Jz": 1.3e-2,    # Inertia moment around z-axis [kg m²]
        "Kt": 0.4,       # Translational drag coefficient [Ns/m]? - Check units/usage
        "Kr": 0.4,       # Rotational drag coefficient [Nms/rad]? - Check units/usage
        "CT": 0.055,     # Thrust coefficient (dimensionless)
        "CQ": 0.024,     # Torque coefficient (dimensionless)
        "R": 0.15,       # Rotor radius [m]
        "Vg": 14.0,      # Generator voltage [V] ? - Check meaning/usage
        "Rm": 0.036,     # Motor resistance [Ω]
        "Jtotal": 4e-4 + 6e-3, # Total rotor inertia (motor + propeller) [kg m²]
        "km": 0.01433,   # Motor torque constant [Nm/A] or Back-EMF constant [Vs/rad]
        "deadzone": 0.0, # Control deadzone threshold
        "saturation": 1.0 # Control saturation limit
    }

def parameters_to_vector(p_dict):
    """Convert parameter dictionary to NumPy vector in the standard order."""
    return np.array([
        p_dict["m"], p_dict["g"], p_dict["l"], p_dict["rho"], p_dict["d"],
        p_dict["Jx"], p_dict["Jy"], p_dict["Jz"], p_dict["Kt"], p_dict["Kr"],
        p_dict["CT"], p_dict["CQ"], p_dict["R"], p_dict["Vg"], p_dict["Rm"],
        p_dict["Jtotal"], p_dict["km"], p_dict["deadzone"], p_dict["saturation"]
    ])

def vector_to_parameters(p_vec):
    """Convert parameter vector (NumPy) back to a dictionary."""
    keys = [
        "m", "g", "l", "rho", "d", "Jx", "Jy", "Jz", "Kt", "Kr",
        "CT", "CQ", "R", "Vg", "Rm", "Jtotal", "km", "deadzone", "saturation"
    ]
    return dict(zip(keys, p_vec))


# --- Hover Calculation ---
def calculate_hover_control(parameters):
    """
    Calculates the steady-state rotor speed (rad/s) and control input (e.g., PWM)
    required for hovering.

    Args:
        parameters: Drone parameters dictionary or vector.

    Returns:
        Tuple: (hover_control_input, hover_rotor_speed)
    """
    if isinstance(parameters, dict):
        p_vec = parameters_to_vector(parameters)
    elif len(parameters) == 19:
        p_vec = np.asarray(parameters)
    else:
        raise ValueError("Parameters must be a dictionary or a 19-element vector/list.")

    # Extract necessary parameters using vector indices
    m, g, _, rho, d, _, _, _, _, _, CT, _, R_prop, Vg, Rm, Jtotal, km, *_ = p_vec

    # Calculate total thrust needed for hover (Thrust = Weight)
    thrust_hover = m * g

    # Calculate required sum of squared rotor speeds
    # thrust = rho * CT * A * R^2 * sum(Omega^2), where A = pi*R^2
    A = math.pi * R_prop**2
    sum_omega_squared = thrust_hover / (rho * CT * A * R_prop**2)

    # For symmetric hover, all rotors spin at the same speed (Omega)
    # 4 * Omega^2 = sum_omega_squared
    omega_hover = math.sqrt(sum_omega_squared / 4.0)

    # Calculate the f2 term (rotor dynamics without control) at hover speed
    # f2 = (-km^2/(Rm*Jtotal))*omega - (d/Jtotal)*omega^2
    f2_at_hover = (-km**2 / (Rm * Jtotal)) * omega_hover - (d / Jtotal) * omega_hover**2

    # Calculate the g2 constant
    # g2(u) = constant * processed_u, where constant = km*Vg / (Rm*Jtotal)
    g2_constant = (km * Vg) / (Rm * Jtotal)

    # At steady state hover, d(rotor_speed)/dt = 0 => f2 + g2 = 0
    # f2_at_hover + g2_constant * processed_u_hover = 0
    # Assuming hover control is within linear range (no saturation/deadzone applied)
    # processed_u_hover = u_hover
    # control_hover = -f2_at_hover / g2_constant
    if abs(g2_constant) < 1e-10:
        raise ValueError("g2_constant is too small, cannot calculate hover control.")

    control_hover = -f2_at_hover / g2_constant

    # Return the required control input (same for all rotors) and the hover speed
    # The control input here assumes it's the value *before* saturation/deadzone
    return np.full(CONTROL_DIM_TOTAL, control_hover), omega_hover

# --- Dynamics Components (using parameter vector p_vec internally) ---

def f0_quaternion(vel, q, p_vec, velocity_wind):
    """Translational dynamics without control input."""
    m, g, _, _, _, _, _, _, Kt, *_ = p_vec
    G = np.array([0, 0, g])
    R_mat = quaternion_to_rotation_matrix(q)
    # Note: Julia uses R * Kt * R' * (vel - v_wind). Assuming Kt is scalar here.
    # If Kt is a matrix, R @ Kt @ R.T should be used. Based on default_params, it's scalar.
    drag_term = (1.0 / m) * R_mat @ (Kt * R_mat.T @ (vel - velocity_wind))
    return -G - drag_term

def f1_quaternion(q, omega, p_vec):
    """Rotational dynamics without control input."""
    _, _, _, _, _, Jx, Jy, Jz, _, Kr, *_ = p_vec
    J = np.diag([Jx, Jy, Jz])
    J_inv = np.diag([1/Jx, 1/Jy, 1/Jz])
    # Explicit cross product: -omega x (J @ omega)
    omega_cross_Jomega = np.cross(-omega, J @ omega)
    return J_inv @ (omega_cross_Jomega - Kr * omega)

def f2_quaternion(rotor_speeds, p_vec):
    """Rotor dynamics without control input."""
    # Use explicit indices for safety
    d = p_vec[4]
    Rm = p_vec[14]
    Jtotal = p_vec[15]
    km = p_vec[16]

    # km^2/(Rm*Jtotal) vs km^2/(Rm*(Jm+Jr)) in comments -> using Jtotal
    term1 = (-km**2 / (Rm * Jtotal)) * rotor_speeds
    term2 = (d / Jtotal) * (rotor_speeds**2)
    return term1 - term2

def g0_quaternion(q, rotor_speeds, p_vec):
    """Control effect on translational dynamics (Thrust)."""
    m, _, _, rho, _, _, _, _, _, _, CT, _, R_prop, *_ = p_vec # Corrected R -> R_prop
    A = math.pi * R_prop**2
    thrust_magnitude = rho * CT * A * (R_prop**2) * np.sum(rotor_speeds**2)
    R_mat = quaternion_to_rotation_matrix(q)
    thrust_vec = R_mat @ np.array([0, 0, thrust_magnitude])
    return thrust_vec / m

def g1_quaternion(q, rotor_speeds, p_vec):
    """Control effect on rotational dynamics (Torques)."""
    _, _, l, rho, _, Jx, Jy, Jz, _, _, CT, CQ, R_prop, *_ = p_vec # Corrected R -> R_prop
    J = np.diag([Jx, Jy, Jz])
    J_inv = np.diag([1/Jx, 1/Jy, 1/Jz])
    A = math.pi * R_prop**2
    l_rho_CT_A_R2_sqrt2 = l * rho * CT * A * (R_prop**2) / math.sqrt(2.0)
    rho_CQ_A_R3 = rho * CQ * A * (R_prop**3)

    rs_sq = rotor_speeds**2
    tau_x = l_rho_CT_A_R2_sqrt2 * (rs_sq[0] - rs_sq[1] - rs_sq[2] + rs_sq[3])
    # Corrected indices for tau_y based on standard quad + config
    tau_y = l_rho_CT_A_R2_sqrt2 * (-rs_sq[0] - rs_sq[1] + rs_sq[2] + rs_sq[3])
    tau_z = rho_CQ_A_R3 * (-rs_sq[0] + rs_sq[1] - rs_sq[2] + rs_sq[3]) # Assuming + config

    torques = np.array([tau_x, tau_y, tau_z])
    return J_inv @ torques

def g2_quaternion(control_input, p_vec):
    """Control effect on rotor dynamics."""
    # Use explicit indices for safety
    Vg = p_vec[13]
    Rm = p_vec[14]
    Jtotal = p_vec[15]
    km = p_vec[16]
    deadzone_param = p_vec[17]
    saturation_param = p_vec[18]

    constant = (km * Vg) / (Rm * Jtotal)
    # Apply saturation_deadzone element-wise
    processed_control = np.array([
        saturation_deadzone(u, deadzone_param, saturation_param)
        for u in control_input
    ])
    return constant * processed_control


# --- Full Dynamics Function ---

def quadrotor_dynamics_quaternion(u, control, p, t, velocity_wind=None):
    """
    Out-of-place ODE function for quaternion-based quadrotor dynamics.
    Returns the state derivatives as a new vector.

    State vector layout u (17 elements):
    - u[0:3]: position (x, y, z)
    - u[3:6]: linear velocity (vx, vy, vz)
    - u[6:10]: quaternion (q0, q1, q2, q3) - scalar first
    - u[10:13]: angular velocity (wx, wy, wz)
    - u[13:17]: rotor speeds (O1, O2, O3, O4)

    Control vector control (4 elements):
    - control[0:4]: PWM/normalized inputs

    Parameters p: dictionary or 19-element vector/list
    Time t: current time
    velocity_wind: Wind velocity vector [vx, vy, vz] or callable(pos) -> [vx, vy, vz]
                   Defaults to zero wind.
    """
    # Ensure parameters are a vector
    if isinstance(p, dict):
        p_vec = parameters_to_vector(p)
    elif len(p) == 19:
        p_vec = np.asarray(p)
    else:
        raise ValueError("Parameters 'p' must be a dictionary or a 19-element vector/list.")

    # Extract state components using slices
    pos = u[POS_SLICE]
    vel = u[VEL_SLICE]
    quat = u[QUAT_SLICE]
    omega = u[ANG_VEL_SLICE]
    rotor_speeds = u[ROTOR_SLICE]

    # Normalize quaternion
    q_norm = np.linalg.norm(quat)
    if q_norm > 1e-10:
        q_normalized = quat / q_norm
    else:
        # Avoid division by zero, reset to identity quaternion
        q_normalized = np.array([1.0, 0.0, 0.0, 0.0])

    # Get control input for current time
    current_control = at_time(control, t)
    if len(current_control) != CONTROL_DIM_TOTAL:
         raise ValueError(f"Control input must have dimension {CONTROL_DIM_TOTAL}")

    # Get wind velocity for current time and position
    if velocity_wind is None:
        current_velocity_wind = np.zeros(POS_DIM)
    else:
        wind_at_t = at_time(velocity_wind, t)
        current_velocity_wind = at_position(wind_at_t, pos)
        if len(current_velocity_wind) != POS_DIM:
             raise ValueError(f"Wind velocity must have dimension {POS_DIM}")


    # Calculate derivatives
    du = np.zeros(STATE_DIM_TOTAL)

    du[POS_SLICE] = vel
    du[VEL_SLICE] = f0_quaternion(vel, q_normalized, p_vec, current_velocity_wind) + \
                    g0_quaternion(q_normalized, rotor_speeds, p_vec)
    du[QUAT_SLICE] = quaternion_derivative(q_normalized, omega)
    du[ANG_VEL_SLICE] = f1_quaternion(q_normalized, omega, p_vec) + \
                        g1_quaternion(q_normalized, rotor_speeds, p_vec)
    du[ROTOR_SLICE] = f2_quaternion(rotor_speeds, p_vec) + \
                      g2_quaternion(current_control, p_vec)

    return du


# --- RK4 Integrator ---

def rk4_step(dynamics_func, x, u, params, t, dt, **kwargs):
    """
    Performs a single RK4 integration step.

    Args:
        dynamics_func: The function defining the system dynamics f(x, u, p, t).
                       Must accept state x, control u, parameters p, time t,
                       and optionally other kwargs (like velocity_wind).
        x: Current state vector.
        u: Control input vector (or callable).
        params: System parameters.
        t: Current time.
        dt: Time step.
        **kwargs: Additional arguments passed to dynamics_func (e.g., velocity_wind).

    Returns:
        The state vector at time t + dt.
    """
    k1 = dynamics_func(x, u, params, t, **kwargs)
    k2 = dynamics_func(x + 0.5 * dt * k1, u, params, t + 0.5 * dt, **kwargs)
    k3 = dynamics_func(x + 0.5 * dt * k2, u, params, t + 0.5 * dt, **kwargs)
    k4 = dynamics_func(x + dt * k3, u, params, t + dt, **kwargs)

    x_next = x + (dt / 6.0) * (k1 + 2 * k2 + 2 * k3 + k4)
    return x_next

# --- Unified Discrete Dynamics ---

def discrete_quadrotor_model_dynamics(x, u, parameters, t, dt, v_wind=None):
    """
    Unified discrete-time dynamics using RK4 for the quaternion model.

    Args:
        x: State vector.
        u: Control input vector (or callable).
        parameters: Drone parameters (dict or vector).
        t: Current time.
        dt: Time step.
        v_wind: Wind velocity vector or callable (optional).

    Returns:
        Next state vector.
    """
    if len(x) != STATE_DIM_TOTAL:
         raise ValueError(f"State dimension ({len(x)}) does not match model state dimension ({STATE_DIM_TOTAL})")

    # Integrate using RK4
    x_next = rk4_step(quadrotor_dynamics_quaternion, x, u, parameters, t, dt, velocity_wind=v_wind)

    # Normalize quaternion part
    quat_next = x_next[QUAT_SLICE]
    norm_q = np.linalg.norm(quat_next)
    if norm_q > 1e-10:
        x_next[QUAT_SLICE] = quat_next / norm_q
    else:
        # Reset to identity if norm is zero
        x_next[QUAT_SLICE] = np.array([1.0, 0.0, 0.0, 0.0])

    return x_next

# --- Simulation Step Wrapper (similar to Julia's simulate_step) ---

def simulate_step(actual_state, control, drone_parameters, t, dt, wind=None):
    """
    Simulates one discrete step of the drone dynamics.
    This wraps discrete_quadrotor_model_dynamics for convenience.
    """
    return discrete_quadrotor_model_dynamics(
        actual_state,
        control,
        drone_parameters,
        t,
        dt,
        v_wind=wind
    )

# --- Example Usage (Optional) ---
if __name__ == '__main__':
    # --- Setup ---
    params = default_parameters()
    params_vec = parameters_to_vector(params)

    # Calculate hover conditions
    hover_control_input, hover_rotor_speed = calculate_hover_control(params)
    print(f"Calculated Hover Control Input: {hover_control_input}")
    print(f"Calculated Hover Rotor Speed (rad/s): {hover_rotor_speed:.2f}")

    # Initial state (at hover)
    initial_state = np.zeros(STATE_DIM_TOTAL)
    initial_state[2] = 1.0  # Start at z=1m
    initial_state[QUAT_SLICE] = np.array([1.0, 0.0, 0.0, 0.0]) # w, x, y, z
    initial_state[ROTOR_SLICE] = np.full(ROTOR_DIM, hover_rotor_speed)

    print(f"\nInitial State: {initial_state}")

    # --- Debug: Check if f2 + g2 is near zero at hover ---
    # !!! This block should run ONLY ONCE before the loop !!!
    p_vec_debug = parameters_to_vector(params)
    rotor_speeds_hover = initial_state[ROTOR_SLICE] # Use explicit variable
    control_input_hover = hover_control_input    # Use explicit variable

    f2_val = f2_quaternion(rotor_speeds_hover, p_vec_debug)
    g2_val = g2_quaternion(control_input_hover, p_vec_debug) # This applies saturation/deadzone

    # Recalculate g2 term WITHOUT saturation/deadzone for comparison, using the constant from hover calc
    Vg = p_vec_debug[13]
    Rm = p_vec_debug[14]
    Jtotal = p_vec_debug[15]
    km = p_vec_debug[16]
    g2_constant_debug = (km * Vg) / (Rm * Jtotal)
    g2_linear_val = g2_constant_debug * control_input_hover

    rotor_accel_at_hover = f2_val + g2_val # The actual acceleration happening
    check_sum = f2_val + g2_linear_val # This sum *should* be zero if hover calc matches dynamics

    print(f"DEBUG: Rotor Speeds at Hover: {rotor_speeds_hover}")
    print(f"DEBUG: Control Input at Hover: {control_input_hover}")
    print(f"DEBUG: f2_val at hover: {f2_val}")
    print(f"DEBUG: g2_val at hover (with sat/dz): {g2_val}")
    print(f"DEBUG: g2_linear_val at hover (no sat/dz): {g2_linear_val}") # Should be equal to -f2_val
    print(f"DEBUG: Actual Rotor Accel (f2 + g2_with_sat_dz): {rotor_accel_at_hover}")
    print(f"DEBUG: Hover Calc Check Sum (f2 + g2_linear): {check_sum}") # Should be near zero
    # --- End Debug ---

    # Simulation parameters
    hover_control = hover_control_input

    # Simulation parameters
    t = 0.0
    dt = 0.01
    simulation_duration = 5.0 # Simulate for 5 seconds total
    num_steps = int(simulation_duration / dt)

    # Wind function (constant wind in positive x direction)
    wind_velocity = np.array([2.0, 0.0, 0.0]) # m/s
    # wind_velocity = None # Uncomment to disable wind

    # --- Simulation Loop ---
    current_state = initial_state
    history = {'t': [], 'state': [], 'control': []}

    for i in range(num_steps):
        # Determine control input based on time
        if t < 1.0:
            # Phase 1: Hover
            current_control = hover_control_input
            label = "Hovering"
        elif t < 2.5:
            # Phase 2: Increase altitude
            current_control = hover_control_input * 1.05 # Slightly increase thrust
            label = "Climbing"
        elif t < 4.0:
            # Phase 3: Induce Roll (positive roll around x-axis)
            # Increase motors 1 & 4, decrease 0 & 3 (assuming + config)
            roll_offset = 0.05
            current_control = np.copy(hover_control_input)
            current_control[1] += roll_offset # Front right
            current_control[2] += roll_offset # Rear left
            current_control[0] -= roll_offset # Front left
            current_control[3] -= roll_offset # Rear right
            # Ensure control stays within bounds [0, 1] roughly
            current_control = np.clip(current_control, 0.0, 1.0)
            label = "Rolling"
        else:
            # Phase 4: Return to hover control
            current_control = hover_control_input
            label = "Returning to Hover"

        # Store history
        history['t'].append(t)
        history['state'].append(current_state)
        history['control'].append(current_control)

        # Simulate one step
        current_state = simulate_step(current_state, current_control, params, t, dt, wind=wind_velocity)
        t += dt

        # Optional: print state at intervals
        if i % 50 == 0: # Print every 0.5 seconds
            pos = current_state[POS_SLICE]
            quat = current_state[QUAT_SLICE]
            print(f"Time: {t:.2f}s ({label}), Pos: [{pos[0]:.2f}, {pos[1]:.2f}, {pos[2]:.2f}], QuatW: {quat[0]:.3f}")

    # Store final state
    history['t'].append(t)
    history['state'].append(current_state)
    history['control'].append(current_control)

    print(f"\nFinal State (t={t:.2f}s): {current_state}")

    # --- Optional: Basic Plotting (requires matplotlib) ---
    try:
        import matplotlib.pyplot as plt

        # Convert history to numpy arrays for easier plotting
        times = np.array(history['t'])
        states = np.array(history['state'])
        controls = np.array(history['control'])

        fig, axs = plt.subplots(3, 1, figsize=(10, 8), sharex=True)

        # Plot Position (X, Y, Z)
        axs[0].plot(times, states[:, 0], label='X')
        axs[0].plot(times, states[:, 1], label='Y')
        axs[0].plot(times, states[:, 2], label='Z')
        axs[0].set_ylabel('Position (m)')
        axs[0].legend()
        axs[0].grid(True)
        axs[0].set_title('Quadrotor Simulation')

        # Plot Orientation (Quaternion Scalar Part - q0)
        axs[1].plot(times, states[:, QUAT_SLICE.start], label='q0 (Scalar)') # Plot q0
        axs[1].set_ylabel('Quaternion q0')
        axs[1].grid(True)
        axs[1].legend()
        # You could add plots for q1, q2, q3 or convert to Euler angles if needed

        # Plot Control Inputs
        axs[2].plot(times, controls[:, 0], label='Motor 1')
        axs[2].plot(times, controls[:, 1], label='Motor 2')
        axs[2].plot(times, controls[:, 2], label='Motor 3')
        axs[2].plot(times, controls[:, 3], label='Motor 4')
        axs[2].set_ylabel('Control Input')
        axs[2].set_xlabel('Time (s)')
        axs[2].legend()
        axs[2].grid(True)

        plt.tight_layout()
        plt.show()

    except ImportError:
        print("\nMatplotlib not found. Skipping plotting.")
        print("Install it with: pip install matplotlib")

    # --- Debug: Check if f2 + g2 is near zero at hover ---
    p_vec_debug = parameters_to_vector(params)
    rotor_speeds_hover = initial_state[ROTOR_SLICE] # Use explicit variable
    control_input_hover = hover_control_input    # Use explicit variable

    f2_val = f2_quaternion(rotor_speeds_hover, p_vec_debug)
    g2_val = g2_quaternion(control_input_hover, p_vec_debug) # This applies saturation/deadzone

    # Recalculate g2 term WITHOUT saturation/deadzone for comparison, using the constant from hover calc
    Vg = p_vec_debug[13]
    Rm = p_vec_debug[14]
    Jtotal = p_vec_debug[15]
    km = p_vec_debug[16]
    g2_constant_debug = (km * Vg) / (Rm * Jtotal)
    g2_linear_val = g2_constant_debug * control_input_hover


    rotor_accel_at_hover = f2_val + g2_val # The actual acceleration happening
    check_sum = f2_val + g2_linear_val # This sum *should* be zero if hover calc matches dynamics

    print(f"DEBUG: Rotor Speeds at Hover: {rotor_speeds_hover}")
    print(f"DEBUG: Control Input at Hover: {control_input_hover}")
    print(f"DEBUG: f2_val at hover: {f2_val}")
    print(f"DEBUG: g2_val at hover (with sat/dz): {g2_val}")
    print(f"DEBUG: g2_linear_val at hover (no sat/dz): {g2_linear_val}") # Should be equal to -f2_val
    print(f"DEBUG: Actual Rotor Accel (f2 + g2_with_sat_dz): {rotor_accel_at_hover}")
    print(f"DEBUG: Hover Calc Check Sum (f2 + g2_linear): {check_sum}") # Should be near zero
    # --- End Debug ---

    # Simulation parameters
    hover_control = hover_control_input

    t = 0.0
    dt = 0.01
    simulation_time = 1.0

    # Simulate
    print(f"Initial State: {initial_state}")
    current_state = initial_state
    for i in range(int(simulation_time / dt)):
        current_state = simulate_step(current_state, hover_control, params, t, dt)
        t += dt
        # Optional: print state at intervals
        if i % 10 == 0:
             print(f"Time: {t:.2f}, Z: {current_state[2]:.3f}, Quat W: {current_state[6]:.3f}")

    print(f"Final State: {current_state}") 