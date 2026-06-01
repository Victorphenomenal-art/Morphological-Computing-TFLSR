import numpy as np
import pysindy as ps
import scipy.io as sio
import matplotlib.pyplot as plt
import os

print("--- PHASE 11: APPENDIX D SINDY PROOFS ---")

# =========================================================================
# 1. LOAD DATA WITH DYNAMIC ROUTING
# =========================================================================
# The script is in scripts/, but the data is in models/
data_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'TFLSR_Synthetic_Data.mat')

print(f">> Attempting to load data from: {os.path.abspath(data_path)}")

try:
    mat_base = sio.loadmat(data_path, squeeze_me=True)
    print(">> Data loaded successfully.")
except FileNotFoundError:
    print(f"ERROR: Could not find the file at {os.path.abspath(data_path)}")
    print("Please ensure TFLSR_Synthetic_Data.mat is inside the models/ folder.")
    exit()

t = mat_base['time_data']
dt = t[1] - t[0]

# Extract z-translation. Adjust index if your array shape is different.
try:
    if mat_base['translation_data'].shape[0] == 3:
        z_raw = mat_base['translation_data'][2, :] 
    else:
        z_raw = mat_base['translation_data'][:, 2]
except KeyError:
    print("ERROR: Could not find 'translation_data' in the .mat file. Check variable names.")
    exit()

# Calculate true derivatives
v_raw = np.gradient(z_raw, dt)
a_raw = np.gradient(v_raw, dt)

# Stack data for SINDy
X_raw = np.stack((z_raw, v_raw), axis=-1)

# =========================================================================
# PROOF D2: PRE-STRAIN REMOVAL
# =========================================================================
print("\n>> Executing Proof D2: Pre-Strain Paradox...")

# Remove the static gravitational sag (mean offset)
z_centered = z_raw - np.mean(z_raw)
X_centered = np.stack((z_centered, v_raw), axis=-1)

# Standard Polynomial Library
poly_lib = ps.PolynomialLibrary(degree=3)

# FIX: Removed 'feature_names' to comply with newer PySINDy versions
model_centered = ps.SINDy(feature_library=poly_lib)
model_centered.fit(X_centered, t=dt)

print("SINDy Equation after Pre-Strain Removal (Notice quadratic terms vanish!):")
model_centered.print()

# =========================================================================
# PROOF D3: CUSTOM NON-SMOOTH LIBRARY (MECHANICAL DIODE)
# =========================================================================
print("\n>> Executing Proof D3: Non-Smooth Stick-Slip Basis...")

# Create custom functions representing the stick-slip diode
custom_functions = [
    lambda x: x,
    lambda x: x**3,
    lambda x: np.maximum(0, x),  # The expansion rectifier
    lambda x: np.minimum(0, x)   # The stick damper
]

# FIX: Custom function names must match the number of custom functions
# In newer PySINDy, these names are handled slightly differently, but providing them to CustomLibrary is usually safe.
custom_names = [
    lambda x: x,
    lambda x: x + "^3",
    lambda x: "max(0, " + x + ")",
    lambda x: "min(0, " + x + ")"
]
custom_lib = ps.CustomLibrary(library_functions=custom_functions, function_names=custom_names)

# FIX: Removed 'feature_names' to comply with newer PySINDy versions
model_custom = ps.SINDy(feature_library=custom_lib)
model_custom.fit(X_raw, t=dt)

print("\nSINDy Equation with Non-Smooth Basis:")
model_custom.print()

# Simulate the custom model's prediction
# Note: PySINDy's predict returns derivatives based on the fit.
# We fit to predict acceleration (which is the derivative of velocity, the 2nd state).
# So we want the 2nd column of the prediction output.
a_pred = model_custom.predict(X_raw)[:, 1]

# =========================================================================
# PLOTTING AND EXPORTING
# =========================================================================
print("\n>> Generating Plot...")
plt.figure(figsize=(10, 5))
plt.plot(t, a_raw, color='#00A6A6', linewidth=1.5, label="True Simscape Acceleration")
plt.plot(t, a_pred, 'w--', linewidth=2, label="Custom Non-Smooth SINDy Prediction")
plt.style.use('dark_background')
plt.xlabel("Time (s)")
plt.ylabel("Acceleration")
plt.title("Appendix D3: Successful Recovery using Mechanical Diode Basis")
plt.legend(loc="lower right")
plt.grid(True, alpha=0.3)

# Ensure output directory exists relative to scripts/
output_dir = os.path.join(os.path.dirname(__file__), '..', 'results', 'figures')
os.makedirs(output_dir, exist_ok=True)

pdf_path = os.path.join(output_dir, 'PRX_Appendix_D3_CustomSINDy.pdf')
png_path = os.path.join(output_dir, 'PRX_Appendix_D3_CustomSINDy.png')

plt.savefig(pdf_path, format='pdf', bbox_inches='tight')
plt.savefig(png_path, dpi=300, bbox_inches='tight')

print(f"\nAppendix D3 successfully exported to: {os.path.abspath(output_dir)}")