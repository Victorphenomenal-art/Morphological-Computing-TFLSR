import scipy.io as sio
import numpy as np
import matplotlib.pyplot as plt
import pysindy as ps
from scipy.fft import rfft, rfftfreq
from scipy.signal import savgol_filter, square, lfilter

print("--- PHASE 13: FLUID-DYNAMIC PRESSURE COUPLING ---")

# We lower the smoothing window so we don't accidentally cut off the sharp physical peaks!
window = 7  
poly = 3

# ==========================================
# 1. BASE DATA PROCESSING (1kg Payload)
# ==========================================
import os

# Dynamically route the path up one level and into the models folder
data_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'TFLSR_Synthetic_Data.mat')
mat_base = sio.loadmat(data_path, squeeze_me=True)
t_base = mat_base['time_data']
dt = t_base[1] - t_base[0]

X_base = np.transpose(mat_base['translation_data'])
z_base = savgol_filter(X_base[:, 2], window_length=window, polyorder=poly)
vz_base = savgol_filter(np.gradient(z_base, dt), window_length=window, polyorder=poly)

yf = rfft(vz_base - np.mean(vz_base))
xf = rfftfreq(len(vz_base), dt)
peak_idx = np.argmax(np.abs(yf) * (xf > 0.5))

pump_freq = xf[peak_idx]
omega = 2.0 * np.pi * pump_freq
phase_shift = np.angle(yf[peak_idx])

State_base = vz_base.reshape(-1, 1)

# --- THE BREAKTHROUGH: PNEUMATIC CAPACITANCE ---
# We generate the raw electrical valve command
raw_valve_base = square(omega * t_base + phase_shift)

# We pass the electrical command through a fluid-dynamic filter to simulate air pressure buildup!
# alpha represents how fast the air fills the chamber (0.15 is a standard pneumatic time constant)
alpha_air = 0.15 
pressure_curve_base = lfilter([alpha_air], [1, -(1 - alpha_air)], raw_valve_base)

U_base = np.column_stack((z_base, np.ones(len(t_base)) * 1.0, pressure_curve_base))
Accel_base = np.gradient(vz_base, dt).reshape(-1, 1)


# ==========================================
# 2. HEAVY DATA PROCESSING (2kg Payload)
# ==========================================
# Dynamically route the path for the heavy data file
heavy_data_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'TFLSR_Heavy_Data.mat')
mat_heavy = sio.loadmat(heavy_data_path, squeeze_me=True)
t_heavy = mat_heavy['time_data']
X_heavy = np.transpose(mat_heavy['translation_data'])

z_heavy = savgol_filter(X_heavy[:, 2], window_length=window, polyorder=poly)
vz_heavy = savgol_filter(np.gradient(z_heavy, dt), window_length=window, polyorder=poly)

State_heavy = vz_heavy.reshape(-1, 1)

raw_valve_heavy = square(omega * t_heavy + phase_shift)
pressure_curve_heavy = lfilter([alpha_air], [1, -(1 - alpha_air)], raw_valve_heavy)

U_heavy = np.column_stack((z_heavy, np.ones(len(t_heavy)) * 2.0, pressure_curve_heavy))
Accel_heavy = np.gradient(vz_heavy, dt).reshape(-1, 1)


# ==========================================
# 3. TRAINING THE CHIBUEZE EQUATION
# ==========================================
State_train = [State_base, State_heavy]
U_train = [U_base, U_heavy]
Accel_train = [Accel_base, Accel_heavy] 

print("Training SINDy with Thermodynamic Fluid Coupling...")

# We use cubic polynomials for the hyperelastic silicone rubber
feature_library = ps.PolynomialLibrary(degree=3, include_interaction=True)

# 0.0 threshold guarantees the AI uses the massive physical spikes
optimizer = ps.STLSQ(threshold=0.0, alpha=0.0, normalize_columns=False)

model = ps.SINDy(optimizer=optimizer, feature_library=feature_library)
model.fit(State_train, x_dot=Accel_train, u=U_train, t=dt)

print("\n==================================================")
print("THE CHIBUEZE EQUATION (FLUID-COUPLED KINEMATICS):")
print("==================================================")
model.print()
print("==================================================\n")


# ==========================================
# 4. THE ULTIMATE PROOF
# ==========================================
print("Generating Final Fluid-Dynamic Proof...")
Predicted_Acceleration_Heavy = model.predict(State_heavy, u=U_heavy)

plt.figure(figsize=(12, 6))
plt.style.use('dark_background')

plt.plot(t_heavy, Accel_heavy, 'c-', label='True Z-Acceleration (Simscape)', linewidth=2.5)
plt.plot(t_heavy, Predicted_Acceleration_Heavy, 'w--', label='SINDy Prediction (Thermodynamic Pressure Curve)', linewidth=1.5)

plt.title('Phase 13: The Chibueze Equation (Fluid-Dynamic Coupling)', fontsize=14)
plt.xlabel('Time (s)', fontsize=12)
plt.ylabel('Acceleration (m/s^2)', fontsize=12)
plt.legend(loc='upper right')
plt.grid(True, linestyle='--', alpha=0.3)
plt.tight_layout()
import os
import matplotlib.pyplot as plt

# 1. Define the target export directory relative to the SINDy folder
output_dir = os.path.join(os.path.dirname(__file__), '..', 'results', 'figures')
os.makedirs(output_dir, exist_ok=True)

# 2. Define the file paths
pdf_path = os.path.join(output_dir, 'Fig7_SINDy_Limit.pdf')
png_path = os.path.join(output_dir, 'Fig7_SINDy_Limit.png')

# 3. Export as high-resolution PDF (for PRX) and PNG (for GitHub)
print("Exporting SINDy Kinetic Stiffness Limit plot to results/figures/ ...")
plt.savefig(pdf_path, format='pdf', bbox_inches='tight')
plt.savefig(png_path, dpi=300, bbox_inches='tight')
print("SINDy Figure successfully exported!")

# Keep the plot open if you want to view it
# plt.show()
plt.show()
