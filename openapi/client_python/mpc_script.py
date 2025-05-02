# --- Setup (Includes previous setup: client init, model creation) ---
from rxinferclient import RxInferClient
import numpy as np
import matplotlib.pyplot as plt
from quadrotor_simulator import (
    simulate_step,
    default_parameters,
    STATE_DIM_TOTAL,
    CONTROL_DIM_TOTAL,
    POS_SLICE,
    VEL_SLICE,
    QUAT_SLICE,
    POS_DIM
)
import time # For timing calls

# Initialize client
client = RxInferClient()

# Model instance parameters
model_name = "Drone-MPC-Planner-v1"
horizon = 10
dt = 0.1
verbose = True
response = client.models.create_model_instance({
    "model_name": model_name,
    "arguments": {
        "horizon": horizon,
        "dt": dt,
        "verbose": verbose
        # Can add measurement_matrix/covariance here if needed to override defaults
    }
})
instance_id = response.instance_id
print(f"Created model instance: {instance_id}")



# --- Simulation Setup ---
drone_params = default_parameters()
simulation_duration = 1.0 # seconds
num_steps = int(simulation_duration / dt)
t = 0.0

# Initial state for the simulator
initial_state = np.zeros(STATE_DIM_TOTAL)
initial_state[7] = 1.0

# Goal state
goal_state_vec = np.array([2.0, 3.0, 5.0])

# Target Covariance (Required for planning, should be 17x17)
# Example: Low covariance for position, higher for others
target_covariance_mat = np.diag(np.ones(3) * 1e-2) # Default moderate covariance
target_covariance_list = target_covariance_mat.tolist()

# --- Simulation Loop ---
current_sim_state = initial_state


history = {'t': [], 'state': [], 'control': [], 'goal': [], 'plan_time': [], 'update_time': []}

print("Starting simulation loop...")

planning_event = {
    "modality": "planning",
    "target": goal_state_vec.tolist(),
    "target_covariance": target_covariance_list,
    "t": t
}

plan_start_time = time.time()

plan_response = client.models.run_inference(
    instance_id,
    {"data": planning_event} # Pass request dict as second positional arg
)
print(plan_response.model_dump)
       