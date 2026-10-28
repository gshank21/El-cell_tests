---@meta

-- EL-CELL PAT Tester: global variable declarations for EmmyLua.
-- Source: CC-advanced.lua (script-base 2025-02-13).
-- Target installation: EL-Software server/controller 3.1.3.15886.
--
-- IDE-ONLY: This file must NEVER be uploaded to or executed by the PAT tester.
-- The = nil declarations exist solely to make globals visible to the IDE.
-- Runtime variables are initialized and updated by CC-advanced.lua / PAT firmware.
-- Numeric units are the script's INTERNAL units, not necessarily the output file units.
-- Some measurements initialize as NaN (0/0) until real readings arrive.

-- ==================================================================
-- Logging severity
-- ==================================================================

---Error severity (0).
---@type integer
SEV_ERR = nil

---Warning severity (1).
---@type integer
SEV_WARN = nil

---Information severity (2).
---@type integer
SEV_INFO = nil

-- ==================================================================
-- State-machine timing and status
-- ==================================================================

---State-machine elapsed time (s).
---@type number
t = nil

---Current state-machine step number.
---@type integer
step_n = nil

---Elapsed time in the current step (s).
---@type number
step_t = nil

---Current state-machine cycle number.
---@type integer
cycle_n = nil

---Elapsed time in the current cycle (s).
---@type number
cycle_t = nil

---State-machine time at step start (s).
---@type number
step_tstart = nil

---State-machine time at cycle start (s).
---@type number
cycle_tstart = nil

---Whether the state machine has started.
---@type boolean
started = nil

---Whether the state machine has finished.
---@type boolean
finished = nil

---Whether samples are being processed.
---@type boolean
processing = nil

---Whether execution is paused.
---@type boolean
paused = nil

---Whether execution has been stopped.
---@type boolean
stopped = nil

---Count of state-machine transitions.
---@type integer
transition_counter = nil

---Estimated progress (%).
---@type number
progress_estimate = nil

---Cycle-based progress (%), if available.
---@type number|nil
progress_accurate = nil

---Estimated number of step transitions.
---@type integer
step_transitions_estimated = nil

---Step configuration indexed by step number; rebuilt at transitions.
---@type table
stepconf = nil

---State-memory tables for limits and loop counters.
---@type table
stepstate = nil

---Active step type (e.g., CC, CV, Rest, PEIS, GEIS).
---@type string
step_type = nil

---Active electrode connection.
---@type string
step_con = nil

---Active current range.
---@type string
step_range = nil

---Active bandwidth.
---@type string
step_bw = nil

---Potentiostatic/galvanostatic mode marker.
---@type string
step_pg = nil

---Charge/discharge marker for the active step.
---@type string
step_cd = nil

---Charge/discharge marker defining cycle start.
---@type string
step_cds = nil

---Voltage setpoint (V).
---@type number
step_v_ctrl = nil

---Current setpoint (A).
---@type number
step_i_ctrl = nil

---Voltage scan slope; units depend on API configuration.
---@type number
step_slope = nil

---Differential-capacity voltage increment (V).
---@type number
step_diffcap_dV = nil

---Differential-capacity reset delay (s).
---@type number
step_diffcap_startdelayR = nil

---Differential-capacity start delay (s).
---@type number
step_diffcap_startdelay = nil

-- ==================================================================
-- Measured analog signals and derived currents
-- ==================================================================

---Voltage between electrodes 1 and 2 (V).
---@type number
V12 = nil

---Voltage between electrode 1 and reference R (V).
---@type number
V1R = nil

---Voltage between electrode 2 and reference R (V).
---@type number
V2R = nil

---Measured current (A).
---@type number
i = nil

---Auxiliary voltage (V).
---@type number
Vaux = nil

---Current between electrodes 1 and 2 (A).
---@type number
i12 = nil

---Current between electrode 1 and R (A).
---@type number
i1R = nil

---Current between electrode 2 and R (A).
---@type number
i2R = nil

---Calculated electrical power (W).
---@type number
P = nil

---Overrange flag (string i, v or iv; initially NaN).
---@type string|number
sample_over = nil

---Current-range code reported by the potentiostat.
---@type number
sample_i_range = nil

-- ==================================================================
-- Charge, energy and efficiency
-- ==================================================================

---Signed charge accumulated in the step (A·s).
---@type number
Qstep = nil

---Absolute step charge (A·s).
---@type number
Qstep_abs = nil

---Signed cycle charge (A·s).
---@type number
Qcd = nil

---Absolute cycle charge (A·s).
---@type number
Qcd_abs = nil

---Charge passed during charging (A·s).
---@type number
Qc = nil

---Charge passed during discharging (A·s).
---@type number
Qd = nil

---Energy accumulated during charging (J).
---@type number
Wc = nil

---Energy accumulated during discharging (J).
---@type number
Wd = nil

---Charge efficiency ratio (not percent).
---@type number
EffQ = nil

---Energy efficiency ratio (not percent).
---@type number
EffW = nil

---Charge-cycle CC capacity (A·s).
---@type number
Qcc_cyc = nil

---Discharge-cycle CC capacity (A·s).
---@type number
Qdd_cyc = nil

---Net charge transferred across electrodes 1–2 (A·s).
---@type number
Q12 = nil

---Net charge transferred across electrodes 1–R (A·s).
---@type number
Q1R = nil

---Net charge transferred across electrodes 2–R (A·s).
---@type number
Q2R = nil

---Net charge of electrode 1 (A·s).
---@type number
Q1 = nil

---Net charge of electrode 2 (A·s).
---@type number
Q2 = nil

---Net charge of reference electrode (A·s).
---@type number
QR = nil

---Total energy transferred across electrodes 1–2 (J).
---@type number
W12 = nil

-- ==================================================================
-- Sample timing and acquisition state
-- ==================================================================

---ADC sample time since start (s).
---@type number
sample_t = nil

---Previous sample timestamp (s).
---@type number
sample_t_prev = nil

---Previous displayed sample time (s).
---@type number
sample_t_prev_display = nil

---Previous recorded sample time (s).
---@type number
sample_t_prev_record = nil

---Previous recorded sensor timestamp (s).
---@type number
sample_t_prev_rec_sen = nil

---Previous differential-capacity output time (s).
---@type number
sample_t_prev_diffcap = nil

---Timestamp at which the sample step started (s).
---@type number
sample_step_tstart = nil

---Timestamp of the last sample of the step (s).
---@type number
sample_step_tlast = nil

---Timestamp at which the sample cycle started (s).
---@type number
sample_cycle_tstart = nil

---Sample time within the step (s).
---@type number
sample_step_t = nil

---Sample time within the cycle (s).
---@type number
sample_cycle_t = nil

---Step number associated with buffered sample.
---@type integer
sample_step_n = nil

---Cycle number associated with buffered sample.
---@type integer
sample_cycle_n = nil

---Type of the buffered sample step.
---@type string
sample_step_type = nil

---P/G mode of the buffered sample step.
---@type string
sample_step_pg = nil

---Cycle-start direction associated with sample.
---@type string
sample_cds = nil

---Charge/discharge direction associated with sample.
---@type string
sample_cd = nil

---Electrode connection for buffered sample.
---@type string
sample_step_con = nil

---Differential-capacity voltage increment (V).
---@type number|nil
sample_step_dV = nil

---Whether the sample is selected for recording.
---@type boolean
sample_rec = nil

---ADC sample-buffer fill level.
---@type number
sample_buf = nil

---Maximum time between display updates (s).
---@type number
display_maximum_dt = nil

---Interval between sensor records (s).
---@type number
record_sensor_dt = nil

-- ==================================================================
-- Filtered voltages and voltage slopes
-- ==================================================================

---Filtered V12 (V).
---@type number
V12_avg = nil

---Filtered V1R (V).
---@type number
V1R_avg = nil

---Filtered V2R (V).
---@type number
V2R_avg = nil

---Low-pass filter counter.
---@type integer
avg_counter = nil

---Absolute slope of V12 (V/s).
---@type number
dV12_dt_abs = nil

---Absolute slope of V1R (V/s).
---@type number
dV1R_dt_abs = nil

---Absolute slope of V2R (V/s).
---@type number
dV2R_dt_abs = nil

---Minimum interval for voltage slope calculation (s).
---@type number
dVdt_dt_min = nil

---Maximum interval for voltage slope calculation (s).
---@type number
dVdt_dt_max = nil

---Last sampled V12 from previous step (V).
---@type number
V12_last_step = nil

---Last sampled V1R from previous step (V).
---@type number
V1R_last_step = nil

---Last sampled V2R from previous step (V).
---@type number
V2R_last_step = nil

---Last i12 from previous step (A).
---@type number
i12_last_step = nil

---Last i1R from previous step (A).
---@type number
i1R_last_step = nil

---Last i2R from previous step (A).
---@type number
i2R_last_step = nil

-- ==================================================================
-- Differential-capacity measurements
-- ==================================================================

---Charge increment for C12 calculation (A·s).
---@type number
dQ_C12 = nil

---Charge increment for C1R calculation (A·s).
---@type number
dQ_C1R = nil

---Charge increment for C2R calculation (A·s).
---@type number
dQ_C2R = nil

---Charge increment for C1 calculation (A·s).
---@type number
dQ_C1 = nil

---Charge increment for C2 calculation (A·s).
---@type number
dQ_C2 = nil

---Charge increment for CR calculation (A·s).
---@type number
dQ_CR = nil

---Differential capacity between electrodes 1–2 (A·s/V).
---@type number
C12 = nil

---Differential capacity between electrode 1–R (A·s/V).
---@type number
C1R = nil

---Differential capacity between electrode 2–R (A·s/V).
---@type number
C2R = nil

---Differential capacity for electrode 1 (A·s/V).
---@type number
C1 = nil

---Differential capacity for electrode 2 (A·s/V).
---@type number
C2 = nil

---Differential capacity for reference electrode (A·s/V).
---@type number
CR = nil

-- ==================================================================
-- Temperature, pressure, force, and dilation
-- ==================================================================

---Cell temperature (°C).
---@type number
T_cell = nil

---Pressure sensor temperature (°C).
---@type number
T_press = nil

---Channel-board temperature (°C).
---@type number
T_board = nil

---Chamber temperature setpoint (°C).
---@type number
T_set = nil

---Chamber temperature (°C).
---@type number
T_chamber = nil

---Ambient temperature (°C).
---@type number
T_ambient = nil

---Gas pressure (bar).
---@type number
Pressure = nil

---Cell stack force (N).
---@type number
Force = nil

---Cell stack dilation (m).
---@type number
Dilation = nil

-- ==================================================================
-- Electrochemical impedance spectroscopy
-- ==================================================================

---EIS frequency (Hz).
---@type number
EIS_freq = nil

---EIS measurement time (s).
---@type number
EIS_t = nil

---EIS current-range code.
---@type number
EIS_i_range = nil

---Mean V12 during EIS (V).
---@type number
EIS_V12_dc = nil

---Mean V1R during EIS (V).
---@type number
EIS_V1R_dc = nil

---Mean V2R during EIS (V).
---@type number
EIS_V2R_dc = nil

---Mean i12 during EIS (A).
---@type number
EIS_i12_dc = nil

---Mean i1R during EIS (A).
---@type number
EIS_i1R_dc = nil

---Mean i2R during EIS (A).
---@type number
EIS_i2R_dc = nil

---EIS AC voltage amplitude V12 (V).
---@type number
EIS_dV12 = nil

---EIS AC voltage amplitude V1R (V).
---@type number
EIS_dV1R = nil

---EIS AC voltage amplitude V2R (V).
---@type number
EIS_dV2R = nil

---EIS AC current amplitude i12 (A).
---@type number
EIS_di12 = nil

---EIS AC current amplitude i1R (A).
---@type number
EIS_di1R = nil

---EIS AC current amplitude i2R (A).
---@type number
EIS_di2R = nil

---EIS series-equivalent capacitance (F).
---@type number
EIS_Cs = nil

---EIS parallel-equivalent capacitance (F).
---@type number
EIS_Cp = nil

---EIS waveform precycle count.
---@type number
EIS_precycles = nil

---EIS waveform average count.
---@type number
EIS_averages = nil

---EIS spectrum completion flag (0 while running).
---@type number
EIS_finished = nil

---Boolean spectrum completion flag.
---@type boolean
eis_finished = nil

---Real impedance component for Z12 (Ω).
---@type number
EIS_Z12_re = nil

---Imaginary impedance component for Z12 (Ω).
---@type number
EIS_Z12_im = nil

---Impedance magnitude for Z12 (Ω).
---@type number
EIS_Z12_mag = nil

---Impedance phase angle for Z12 (degrees).
---@type number
EIS_Z12_phi = nil

---Spurious-free dynamic range for Z12 (dB).
---@type number
EIS_Z12_SFDR = nil

---Real impedance component for Z1R (Ω).
---@type number
EIS_Z1R_re = nil

---Imaginary impedance component for Z1R (Ω).
---@type number
EIS_Z1R_im = nil

---Impedance magnitude for Z1R (Ω).
---@type number
EIS_Z1R_mag = nil

---Impedance phase angle for Z1R (degrees).
---@type number
EIS_Z1R_phi = nil

---Spurious-free dynamic range for Z1R (dB).
---@type number
EIS_Z1R_SFDR = nil

---Real impedance component for Z2R (Ω).
---@type number
EIS_Z2R_re = nil

---Imaginary impedance component for Z2R (Ω).
---@type number
EIS_Z2R_im = nil

---Impedance magnitude for Z2R (Ω).
---@type number
EIS_Z2R_mag = nil

---Impedance phase angle for Z2R (degrees).
---@type number
EIS_Z2R_phi = nil

---Spurious-free dynamic range for Z2R (dB).
---@type number
EIS_Z2R_SFDR = nil

---Real impedance component for Z1 (Ω).
---@type number
EIS_Z1_re = nil

---Imaginary impedance component for Z1 (Ω).
---@type number
EIS_Z1_im = nil

---Impedance magnitude for Z1 (Ω).
---@type number
EIS_Z1_mag = nil

---Impedance phase angle for Z1 (degrees).
---@type number
EIS_Z1_phi = nil

---Spurious-free dynamic range for Z1 (dB).
---@type number
EIS_Z1_SFDR = nil

---Real impedance component for Z2 (Ω).
---@type number
EIS_Z2_re = nil

---Imaginary impedance component for Z2 (Ω).
---@type number
EIS_Z2_im = nil

---Impedance magnitude for Z2 (Ω).
---@type number
EIS_Z2_mag = nil

---Impedance phase angle for Z2 (degrees).
---@type number
EIS_Z2_phi = nil

---Spurious-free dynamic range for Z2 (dB).
---@type number
EIS_Z2_SFDR = nil

---Real impedance component for ZR (Ω).
---@type number
EIS_ZR_re = nil

---Imaginary impedance component for ZR (Ω).
---@type number
EIS_ZR_im = nil

---Impedance magnitude for ZR (Ω).
---@type number
EIS_ZR_mag = nil

---Impedance phase angle for ZR (degrees).
---@type number
EIS_ZR_phi = nil

---Spurious-free dynamic range for ZR (dB).
---@type number
EIS_ZR_SFDR = nil

-- ==================================================================
-- Config variables from CC-advanced.lua
-- ==================================================================

---Active parameter-table column.
---@type integer
NN = nil

---Configured cycle count; increments by half cycles.
---@type number
CycleCounter = nil

---Total cycles requested.
---@type integer
N_tot_cycles = nil

---Reference cell capacity (A·s).
---@type number
Q0 = nil

---Current corresponding to reference 1C (A).
---@type number
i0 = nil

---Run self-calibration at test start.
---@type boolean
SelfCal = nil

---Whether the cell includes a reference electrode.
---@type boolean
cell_with_R = nil

---Whether the first half-cycle is charge.
---@type boolean
start_with_charge = nil

---Hardware safety limits.
---@type table
safetylimits = nil

---Standard recording thresholds.
---@type table
r_0 = nil

---Reduced recording thresholds.
---@type table
r_off = nil

---Sine-wave recording thresholds.
---@type table
r_sine = nil

---Voltage signal to control for each parameter column.
---@type table
Vcontrol = nil

---Current path to control for each parameter column.
---@type table
Icontrol = nil

---Low-voltage limits by parameter column (V).
---@type table
VLo = nil

---High-voltage limits by parameter column (V).
---@type table
VHi = nil

---Charge current by parameter column (A).
---@type table
i_charge = nil

---Discharge current magnitudes by parameter column (A).
---@type table
i_disch = nil

---Cycles assigned to each parameter column.
---@type table
N_sub_cycles = nil

---Reset constant-current timing on entering CC.
---@type boolean
reset_dt_CC = nil

---Time at CC start (s).
---@type number|nil
t_CC_start = nil

---Time at CC termination (s).
---@type number|nil
t_CC_end = nil

---Absolute charge at CC start (A·s).
---@type number|nil
Q_CC_start = nil

