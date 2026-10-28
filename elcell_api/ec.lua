
---@meta

-- EL-CELL PAT System API Definitions
-- EL-Software: 3.1.3.15886
-- IDE-only declarations. Do not execute on PAT hardware.

---@class ELCellAPI
ec = {}

---Returns the measurement time in seconds.
---@return number seconds
function ec.GetSeconds() end

---Resets the measurement time counter.
function ec.ResetSeconds() end

---Configures the constant-current setpoint.
---@param current number Current in amperes (A)
function ec.SetConstCurrent(current) end

---Configures the constant-voltage setpoint.
---@param voltage number Voltage in volts (V)
function ec.SetConstVoltage(voltage) end

---Configures the hardware safety limits.
---@param voltage_min number Minimum V12 (V)
---@param voltage_max number Maximum V12 (V)
---@param current_max number Current safety limit (A)
---@param delay_count number Safety delay count
function ec.SetSafetyLimits(
    voltage_min,
    voltage_max,
    current_max,
    delay_count
) end

---Retrieves a named input variable.
---@param name string Variable name
---@return any
function ec.GetInputVariable(name) end

---Sets a named output variable.
---@param name string Variable name
---@param value any Variable value
function ec.SetOutputVariable(name, value) end

---Prints a message through the EL-CELL logging system.
---@param severity integer Message severity
---@param message string Message text
function ec.print(severity, message) end


-- ============================================================
-- Hardware Information and Calibration
-- ============================================================

---Returns channel-board hardware information.
---@return any board_type
---@return number board_revision
---@return number firmware_version
function ec.GetHardwareInfo() end

---Performs a hardware self-calibration.
function ec.SelfCal() end


-- ============================================================
-- Hardware Configuration
-- ============================================================

---Sets the electrode connection configuration.
---@param connection string
function ec.SetCon(connection) end

---Sets the current measurement range.
---@param range string
function ec.SetCurrentRange(range) end

---Sets the control bandwidth.
---@param bandwidth string
function ec.SetBandwidth(bandwidth) end

---Sets the recording delay after a step transition.
---@param delay_ms number Delay in milliseconds
function ec.ADC_RecStepDelay(delay_ms) end

---Configures data recording thresholds.
---@param dV12 number V12 threshold (V)
---@param dV1R number V1R threshold (V)
---@param dV2R number V2R threshold (V)
---@param di number Current threshold (A)
---@param dt number Time threshold (s)
function ec.ADC_RecDelta(dV12, dV1R, dV2R, di, dt) end

---Configures temperature data requests.
---@param request any
function ec.RequestTemperature(request) end

---Applies the pending hardware configuration.
---@return number last_sample_time
function ec.SwitchNow() end


-- ============================================================
-- Electrochemical Measurements
-- ============================================================

---Starts a voltage ramp.
---@param voltage number Initial voltage (V)
---@param slope number Voltage ramp slope
function ec.WaveGenRamp(voltage, slope) end

---Starts an impedance spectrum measurement.
---Parameter names follow the PAT script configuration.
---@param amplitude number
---@param fstart number
---@param fend number
---@param points_per_decade number
---@param order_magnitude number
---@param averages number
---@param precycles number
---@param record_waveform number
---@param drift_correction number
---@param limit_V12 number
---@param limit_V1R number
---@param limit_V2R number
---@param limit_current number
---@param sweep_back number
---@param measure_aux number
function ec.EIS_Spectrum(
    amplitude,
    fstart,
    fend,
    points_per_decade,
    order_magnitude,
    averages,
    precycles,
    record_waveform,
    drift_correction,
    limit_V12,
    limit_V1R,
    limit_V2R,
    limit_current,
    sweep_back,
    measure_aux
) end


-- ============================================================
-- Script Execution and Progress
-- ============================================================

---Updates the script execution state.
---@param state string
function ec.SetScriptExecutionState(state) end

---Updates the displayed measurement progress.
---@param cycle number
---@param step number
---@param progress number Percentage
function ec.SetScriptProgress(cycle, step, progress) end


-- ============================================================
-- Output Files
-- ============================================================

---Writes column definitions to an output file.
---@param filename string
---@param header string Column definitions
function ec.Write_CSV_Header(filename, header) end

---Writes a row of measurement data.
---@param filename string
---@param record boolean
---@param data string Tab-separated data
function ec.Write_CSV_Data(filename, record, data) end
