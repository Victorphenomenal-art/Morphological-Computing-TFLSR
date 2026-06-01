import scipy.io as sio
import numpy as np
import matplotlib.pyplot as plt
import os

def load_clean_data(filepath: str):
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Data file not found at: {filepath}")
        
    print("Opening the vault...")
    mat_data = sio.loadmat(filepath, squeeze_me=True)
    
    # Extract our pure matrices directly!
    time = mat_data['time_data']
    
    # Transpose the 3D data to match the time vector
    translation_matrix = np.transpose(mat_data['translation_data'])
    
    return time, translation_matrix

def plot_trajectory(time: np.ndarray, translation: np.ndarray):
    plt.figure(figsize=(10, 5))
    plt.style.use('dark_background') # Setting it dark to match your vibe
    
    plt.plot(time, translation[:, 0], label='X-Axis Translation', color='#4A90E2', linewidth=1.5)
    plt.plot(time, translation[:, 1], label='Y-Axis Translation', color='#F5A623', linewidth=1.5)
    plt.plot(time, translation[:, 2], label='Z-Axis Translation', color='#7ED321', linewidth=1.5)
    
    plt.title('Phase 6: PIML Data Ingestion Verification', fontsize=14)
    plt.xlabel('Time (s)', fontsize=12)
    plt.ylabel('Displacement (m)', fontsize=12)
    plt.grid(True, linestyle='--', alpha=0.3)
    plt.legend(loc='best')
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    DATA_PATH = 'TFLSR_Synthetic_Data.mat'
    
    try:
        t_array, trans_matrix = load_clean_data(DATA_PATH)
        print(f"Extraction Successful!")
        print(f"Data Shape: {trans_matrix.shape} (Time Steps x 3 Dimensions)")
        print("Rendering Graph...")
        plot_trajectory(t_array, trans_matrix)
    except KeyError as e:
        print(f"Error: Could not find the specific variable in the vault. Did the MATLAB save script run correctly?")