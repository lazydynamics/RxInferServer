import numpy as np
from scipy.spatial.transform import Rotation as R

def euler_to_rotation_matrix(phi, theta, psi):
    """Converts Euler angles (roll, pitch, yaw) to a rotation matrix."""
    # Assuming ZYX convention (yaw, pitch, roll) common in aerospace
    return R.from_euler('zyx', [psi, theta, phi]).as_matrix()

def quaternion_to_rotation_matrix(q):
    """Converts a quaternion [q0, q1, q2, q3] (scalar-first) or [q1, q2, q3, q0] (scalar-last) to a rotation matrix."""
    # Scipy expects scalar-last [x, y, z, w]
    # Assuming input is scalar-first [w, x, y, z] like in the Julia code example state[7:10]
    if len(q) == 4:
        # Convert [q0, q1, q2, q3] to [q1, q2, q3, q0] for scipy
        q_scipy = [q[1], q[2], q[3], q[0]]
        return R.from_quat(q_scipy).as_matrix()
    else:
        raise ValueError("Quaternion must have 4 elements.")

import matplotlib.pyplot as plt

# Assume DroneParameters is a simple class or object with attributes l and r
class DroneParameters:
    def __init__(self, l, R_radius): # Renamed R to R_radius to avoid conflict with rotation matrix
        self.l = l
        self.R_radius = R_radius # Radius of motors/props, not used in Julia code but kept name

def plot_drone_3d(ax, drone_params: DroneParameters, state, color='black', label_suffix=''):
    """Plots a 3D representation of the drone on the given matplotlib axes."""
    # Extract state variables (adjust indices for 0-based Python)
    # Assumes state vector format: [x,y,z, vx,vy,vz, (orientation), angular_velocities, ...]
    pos = np.array(state[0:3])
    x, y, z = pos

    # Determine orientation representation and compute rotation matrix
    rot_matrix = np.identity(3) # Default to identity
    # State length checks adjusted for Python's 0-based indexing and typical lengths
    if len(state) == 16:  # Euler representation [x,y,z, vx,vy,vz, φ,θ,ψ, ωx,ωy,ωz, Ω1,Ω2,Ω3,Ω4] -> indices 6,7,8
        phi, theta, psi = state[6:9]
        rot_matrix = euler_to_rotation_matrix(phi, theta, psi)
    elif len(state) >= 17: # Quaternion representation [x,y,z, vx,vy,vz, q0,q1,q2,q3, ωx,ωy,ωz, Ω1,Ω2,Ω3,Ω4] -> indices 6:10
        quat = state[6:10] # Indices 6, 7, 8, 9
        rot_matrix = quaternion_to_rotation_matrix(quat)
    elif len(state) == 13: # Simplified Quaternion model [x,y,z, vx,vy,vz, q0,q1,q2,q3, ωx,ωy,ωz] -> indices 6:10
        quat = state[6:10] # Indices 6, 7, 8, 9
        rot_matrix = quaternion_to_rotation_matrix(quat)
    # Add more conditions if other state representations are possible

    # Drone parameters
    l = drone_params.l  # arm length

    # Define arm endpoints in body frame (relative to center)
    # Using common '+' configuration for visualization consistency
    arm_endpoints_body = np.array([
        [l, 0, 0],   # Right arm
        [-l, 0, 0],  # Left arm
        [0, l, 0],   # Front arm
        [0, -l, 0]   # Back arm
    ])

    # Transform arm endpoints to world frame
    # Apply rotation (matrix multiplication) and then translation
    world_endpoints = (rot_matrix @ arm_endpoints_body.T).T + pos

    # Plot center (use a slightly larger marker for visibility)
    ax.scatter([x], [y], [z], color=color, marker='o', s=50, label=f'Drone Center{label_suffix}' if label_suffix else None)

    # Plot arms and motors
    for i, endpoint in enumerate(world_endpoints):
        # Draw arm
        ax.plot([x, endpoint[0]], [y, endpoint[1]], [z, endpoint[2]],
                color=color, linewidth=2, label=f'Arm {i+1}{label_suffix}' if i==0 and label_suffix else None)
        # Draw motor (small scatter point)
        ax.scatter([endpoint[0]], [endpoint[1]], [endpoint[2]],
                   color=color, marker='o', s=25, label=f'Motor {i+1}{label_suffix}' if i==0 and label_suffix else None)


import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np


def animate_drone_3d_multi(drone_params: DroneParameters, states, targets,
                           estimated_states=None, observations=None, fps=30, filename="drone_3d_multi.gif"):
    """
    Generates and saves a 3D animation of drone flight with waypoints,
    optionally showing estimated trajectory and noisy observations.
    """
    states = np.array(states)
    targets = np.array(targets)
    if estimated_states is not None:
        estimated_states = np.array(estimated_states)
    if observations is not None:
        observations = np.array(observations)

    # Determine dynamic plot bounds
    all_x = np.concatenate([states[:, 0], targets[:, 0]])
    all_y = np.concatenate([states[:, 1], targets[:, 1]])
    all_z = np.concatenate([states[:, 2], targets[:, 2]])

    if observations is not None:
        all_x = np.concatenate([all_x, observations[:, 0]])
        all_y = np.concatenate([all_y, observations[:, 1]])
        all_z = np.concatenate([all_z, observations[:, 2]])
    
    if estimated_states is not None:
         all_x = np.concatenate([all_x, estimated_states[:, 0]])
         all_y = np.concatenate([all_y, estimated_states[:, 1]])
         all_z = np.concatenate([all_z, estimated_states[:, 2]])

    x_min, x_max = np.min(all_x) - 1.0, np.max(all_x) + 1.0 # Increased margin
    y_min, y_max = np.min(all_y) - 1.0, np.max(all_y) + 1.0
    z_min, z_max = np.min(all_z) - 1.0, np.max(all_z) + 1.0

    # Ensure minimum plot size
    x_range = max(x_max - x_min, 5.0) # Increased min size
    y_range = max(y_max - y_min, 5.0)
    z_range = max(z_max - z_min, 5.0)

    # Center the plot
    x_center = (x_min + x_max) / 2
    y_center = (y_min + y_max) / 2
    z_center = (z_min + z_max) / 2

    x_min, x_max = x_center - x_range / 2, x_center + x_range / 2
    y_min, y_max = y_center - y_range / 2, y_center + y_range / 2
    z_min, z_max = z_center - z_range / 2, z_center + z_range / 2

    fig = plt.figure(figsize=(10, 8)) # Adjust figure size if needed
    ax = fig.add_subplot(111, projection='3d')

    num_frames = len(states)

    def update(k):
        ax.cla() # Clear previous frame

        # Set limits and labels for each frame
        ax.set_xlim(x_min, x_max)
        ax.set_ylim(y_min, y_max)
        ax.set_zlim(z_min, z_max)
        ax.set_xlabel("X")
        ax.set_ylabel("Y")
        ax.set_zlabel("Z")
        ax.set_title(f"Multi-Waypoint Drone Flight (Frame {k+1}/{num_frames})")
        # ax.view_init(elev=30., azim=45) # Set view angle if needed

        # --- Plotting elements ---

        # Plot all targets and connecting lines
        ax.scatter(targets[:, 0], targets[:, 1], targets[:, 2],
                   color='red', marker='x', s=50, label='Waypoints' if k == 0 else "")
        if len(targets) > 1:
            ax.plot(targets[:, 0], targets[:, 1], targets[:, 2],
                    color='red', linestyle='--', linewidth=1, label='Waypoint Path' if k == 0 else "")

        # Plot true drone state
        current_state = states[k]
        plot_drone_3d(ax, drone_params, current_state, color='blue', label_suffix=' (True)' if k==0 else None) # Pass drone parameters

        # Add true trajectory trace (last 100 points or fewer)
        trace_start = max(0, k - 100 + 1) # Adjusted for Python slicing
        if k > 0:
            ax.plot(states[trace_start:k+1, 0], states[trace_start:k+1, 1], states[trace_start:k+1, 2],
                    color='blue', linewidth=1, alpha=0.7, label='True Trajectory' if k == 0 else "")

        # Plot estimated trajectory trace if provided
        if estimated_states is not None and k < len(estimated_states):
            est_trace_start = max(0, k - 100 + 1)
            if k > 0:
                 ax.plot(estimated_states[est_trace_start:k+1, 0],
                         estimated_states[est_trace_start:k+1, 1],
                         estimated_states[est_trace_start:k+1, 2],
                         color='green', linewidth=1, linestyle='-', alpha=0.7,
                         label='Estimated Trajectory' if k == 0 else "")
            # Optionally plot the estimated drone pose itself
            # plot_drone_3d(ax, drone_params, estimated_states[k], color='green', label_suffix=' (Est)' if k==0 else None)


        # Plot noisy observations if provided (last 20 points or fewer)
        if observations is not None and k < len(observations):
             obs_trace_start = max(0, k - 20 + 1)
             if k >= 0: # Plot even if only one observation exists
                 ax.scatter(observations[obs_trace_start:k+1, 0],
                            observations[obs_trace_start:k+1, 1],
                            observations[obs_trace_start:k+1, 2],
                            color='purple', marker='.', s=30, alpha=0.6,
                            label='Noisy Observations' if k == 0 else "")

        # Add legend only once
        if k == 0:
            ax.legend()

        print(f"Rendering frame {k+1}/{num_frames}", end='\r') # Progress indicator

    # Create animation
    ani = animation.FuncAnimation(fig, update, frames=num_frames, interval=1000/fps, blit=False)

    # Save animation
    print(f"\nSaving animation to {filename}...")
    try:
        # You might need to install 'imagemagick' or 'ffmpeg'
        # Pillow writer is often built-in but might be lower quality/slower for gifs
        ani.save(filename, writer='pillow', fps=fps) 
        print(f"Animation saved successfully to {filename}")
    except Exception as e:
        print(f"\nError saving animation: {e}")
        print("You might need to install an animation writer like 'imagemagick' or 'ffmpeg'.")
        print("Alternatively, try saving with writer='pillow' (might require 'pip install Pillow').")


    plt.close(fig) # Close the plot figure after saving
    return ani # Optionally return the animation object
