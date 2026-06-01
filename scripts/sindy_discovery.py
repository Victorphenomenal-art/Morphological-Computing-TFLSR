import scipy.io as sio
import numpy as np
import matplotlib.pyplot as plt
import pysindy as ps

print("--- PHASE 6: PIML DISCOVERY INITIALIZED ---")

filepath = 'TFLSR_Synthetic_Data.mat'
mat_data = sio.loadmat(filepath, squeeze_me=True)

time = mat_data['time_data']
X_train = np.transpose(mat_data['translation_data'])
dt = time[1] - time[0]

print(f"Data ingested. Training SINDy on {X_train.shape[0]} spatial frames...")

# We use a balanced optimizer to let the thermodynamics shine through
optimizer = ps.STLSQ(threshold=0.1, alpha=0.05, normalize_columns=True)
model = ps.SINDy(optimizer=optimizer)

# Train the Model
model.fit(X_train, t=dt)

print("\n==================================================")
print("SINDy HAS DISCOVERED THE GOVERNING EQUATIONS:")
print("==================================================")
model.print()
print("==================================================\n")

# --- THE  PROOF: VECTOR FIELD VALIDATION ---
print("Generating Vector Field Proof (Instantaneous Physics)...")

# Calculate the True physical velocity using pure NumPy calculus (Foolproof!)
x_dot_true = np.gradient(X_train, dt, axis=0)

# Ask the AI to calculate the velocity using ITS discovered math
x_dot_predict = model.predict(X_train)

# Plot the Final Proof (Focusing on the Z-Axis Thermodynamic Heave)
plt.figure(figsize=(12, 6))
plt.style.use('dark_background')

# Plot True Velocity (Thick Green Line)
plt.plot(time, x_dot_true[:, 2], 'g-', label='True Z-Axis Velocity (Simscape Physics)', linewidth=2.5)

# Plot AI Predicted Velocity (Dotted White Line)
plt.plot(time, x_dot_predict[:, 2], 'w--', label='SINDy Predicted Velocity (Discovered Math)', linewidth=1.5)

plt.title('Phase 6 Proof: Instantaneous Thermodynamic Vector Field Matching', fontsize=14)
plt.xlabel('Time (s)', fontsize=12)
plt.ylabel('Velocity (m/s)', fontsize=12)
plt.legend(loc='upper right')
plt.grid(True, linestyle='--', alpha=0.3)
plt.tight_layout()
plt.show()