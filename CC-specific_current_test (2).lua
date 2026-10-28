---------------------------------------------------------------------------------
--                             PAT-Tester-Script                               --
--                    using script-base version 2026-07-09                     --
--                    requires channel-firmware 158 or higher                  --
---------------------------------------------------------------------------------

--#############################################################################--
--##                                                                         ##--
--##            P A R T  1 :     S T A T E   M A C H I N E                   ##--
--##                                                                         ##--
--#############################################################################--

-------------------- Generate Step Configuration --------------------------------
-- This function contains the definition of the script steps.
-- It is called before every step transition, to re-calculate math expressions.
---------------------------------------------------------------------------------
function Generate_StepConfiguration()

    -- configuration section --
    m1 = m1 or ec.GetInputVariable("m1") or 1.0 -- Mass of active material of electrode 1
    m2 = m2 or ec.GetInputVariable("m2") or 1.0 -- Mass of active material of electrode 2
    mR = mR or ec.GetInputVariable("mR") or 1.0 -- Mass of active material of reference electrode

    specific_capacity = 400 -- Specific capacity of active material in mAh/g
    
    step_transitions_estimated = 6
    safetylimits = { V12_min = -10, V12_max = 10, i = 0.11 }
    stepconf =
    {
    	[10] = {
    		step_type = "Rest",
    		record = { V12 = 0.001, V1R = 0.001, V2R = 0.001, i = 99.999, t = 600 },
    		limits = {
    			[0] = function(limit) if step_t > 5 then SwitchNext() end end
    		}
    	},
    	[20] = {
    		step_type = "CC",
    		i = 0.02 * m2,
    		con = "i12",
    		range = "auto",
    		diffcap_dV = 0.001,
    		bw = "fast",
    		record = { V12 = 0.001, V1R = 0.001, V2R = 0.001, i = 0.00001, t = 600 },
    		limits = {
    			[0] = function(limit) if V12 > 1 then SwitchNext() end end
    		}
    	},
    	[30] = {
    		step_type = "CC",
    		i = -0.02 * m2,
    		con = "i12",
    		range = "auto",
    		diffcap_dV = 0.001,
    		bw = "fast",
    		record = { V12 = 0.001, V1R = 0.001, V2R = 0.001, i = 0.00001, t = 600 },
    		limits = {
    			[0] = function(limit) if V12 < 0 then
    					IncLoops(limit)
    					if limit.loops < 2 then SwitchTo(20) else limit.loops = 0 SwitchNext() end
    				end end
    		}
    	},
    	[40] = {
    		step_type = "Rest",
    		record = { V12 = 0.001, V1R = 0.001, V2R = 0.001, i = 99.999, t = 600 },
    		limits = {
    			[0] = function(limit) if step_t > 5 then SwitchNext() end end
    		}
    	}
    }
    -- end of configuration section --

end

-------------------- Init StateMachine ------------------------------------------
-- Initializes the state machine state before start
---------------------------------------------------------------------------------
function Init_StateMachine()

    -- script runtime data --
    t            = 0.0    -- * statemachine time since script init / Seconds
    step_n       = -1     --   statemachine step number, switches from -1 to e.g. step 0 at start
    step_t       = 0.0    -- * statemachine step time, for use as PAT-Composer limit only
    cycle_n      = 0      -- * statemachine cycle number
    cycle_t      = 0.0    -- * statemachine cycle time, for use as PAT-Composer limit only
    spectrum_n   = 0      --   EIS spectrum index within the current cycle
    step_tstart  = 0.0    --   statemachine time when the step was started / Seconds
    cycle_tstart = 0.0    --   statemachine time when the cycle was started / Seconds
    started      = false  --   statemachine has not yet started
    finished     = false  --   statemachine is not finished
    processing   = false  --   script is not processing data
    paused       = false  --   script is not paused
    stopped      = false  --   script is not aborted
    transition_counter = 0  -- count of statemachine step transitions, for script progress
    progress_estimate = 0.0 -- script progress in percent, estimate, based on step_transitions_estimated
    progress_accurate = nil -- script progress in percent, is "nil" if not used (in favor of progress_estimate)

    -- step runtime data --
    -- Explanation of the config structures:
    -- "stepconf":  The "stepconf" structure contains the step config provided by the user.
    --              It can be overwritten by the user at any time during script execution.
    --              All math expressions are repeatedly evaluated before every step transition.
    --              The script itself shall not modify "stepconf" - all changes would be lost.
    -- "stepstate": The "stepstate" structure is private to the script.
    --              It acts as a state memory, e.g. for loop counters.
    stepstate = {}  -- create step state for non-constant values
end

-------------------- Start Measurement ------------------------------------------
-- Does some more initialization and then starts the state machine
---------------------------------------------------------------------------------
function StartMeasurement()

    -- load steps --
    Generate_StepConfiguration()

    AddMissingTablesInAllSteps()

    -- count steps --
    local stepcount = 0
    for n,step in pairs(stepconf) do
        stepcount = stepcount + 1
    end
    -- init count of total estimated transitions, if not provided in config section --
    step_transitions_estimated = step_transitions_estimated or stepcount

    CheckFreeMemory()

    ec.SetSafetyLimits( safetylimits.V12_min,
                        safetylimits.V12_max,
                        safetylimits.i,
                        safetylimits.delay_count or 10)

    -- reset time to 0 seconds --
    ec.ResetSeconds()

    -- set execution state to "Running" --
    ec.SetScriptExecutionState("Running")  -- this makes the firmware call NewSample(...) a thousand times per second
end

function AddMissingTablesInAllSteps()

    for n,step in pairs(stepconf) do
        AddMissingTables(n)
    end
end

function AddMissingTables(n)

    -- stepconf --
    if stepconf[n].record == nil then stepconf[n].record = rec_default end
    if stepconf[n].limits == nil then stepconf[n].limits = {} end

    -- stepstate --
    if stepstate[n]        == nil then stepstate[n] = {} end
    if stepstate[n].limits == nil then stepstate[n].limits = {[0] = {loops = 0}} end
end

function CheckFirmwareVersion()
    -- check channelboard firmware version --
    board_type, board_rev, firmw_vers = ec.GetHardwareInfo()
    if firmw_vers == nil or firmw_vers < 158 then
        ec.print(0, "Please update channel firmware to >=158")
        ec.SetScriptExecutionState("Aborted")
    end
end

function CheckFreeMemory()
    -- check if enough memory is left --
    -- stops execution here if memory is insufficient--
    for n = 1, 20 do _G["dummy"..n] = "dummy" end  -- allocate some string variables to trigger resize of Lua globals table
    for n = 1, 20 do _G["dummy"..n] = nil     end  -- free again
    long_string1 = string.rep("1", 20000)          -- allocate one memory block
    long_string2 = string.rep("2", 20000)          -- allocate one memory block
    long_string1 = nil                             -- free again
    long_string2 = nil                             -- free again
    Init_SampleProcessing = nil                    -- free unused function
    Init_StateMachine = nil                        -- free unused function
    collectgarbage('collect')                      -- run Lua GC
end

------------------- Check Limits / invoke the state machine ---------------------
--  Checks the step limits and switches to the specified step if a limit is exceeded.
---------------------------------------------------------------------------------
function CheckLimits()

    t       = ec.GetSeconds()      -- * statemachine time since script init / Seconds
    step_t  = t - step_tstart      -- * statemachine step time, for use as PAT-Composer limit only
    cycle_t = t - cycle_tstart     -- * statemachine cycle time, for use as PAT-Composer limit only

    -- return if sample is from old step --
    if (sample_t > step_tstart) then  -- "if (sample_step_n == step_n)" would not work if step loops to itself

        -- call limit functions in stepconf[n].limits --
        if stepconf[sample_step_n].limits then
            for m, Limitfunction in pairs(stepconf[sample_step_n].limits) do
                -- shorter pointer name for stepstate limits table
                local l = stepstate[sample_step_n].limits
                -- create empty limit tables if not yet existing
                if not l[m] then l[m] = {} end
                -- initialize limit loop counter if not yet existing
                l[m].loops = l[m].loops or 0
                -- call limit functions
                Limitfunction(l[m])  -- checks limit and eventually calls SwitchNext() or SwitchTo()
            end
        end
    end
end

----------------------------- Increment Loops -----------------------------------
--  This function counts the loops of a step limit.
--  It is usually called from a limit function in stepconf.
---------------------------------------------------------------------------------
function IncLoops(limit)
    limit.loops = limit.loops + 1
end

------------------------- Switch To Next Step -----------------------------------
--  Switches to the next step.
--  This function is usually called when a limit has been exceeded.
---------------------------------------------------------------------------------
function SwitchNext()
    for next_step_n = step_n + 1, 1000000 do   -- look for next step
        if stepconf[next_step_n] then
            SwitchTo(next_step_n)
            return
        end
    end
    -- if no next step exists
    SwitchTo(step_n + 1)  -- ends the script
end

------------------------- Switch To Step n --------------------------------------
--  Switches to the step number specified in the argument.
--  This function is usually called when a limit has been exceeded.
---------------------------------------------------------------------------------
function SwitchTo(n_newstep)

    sample_rec = true  -- keep the sample that triggered the limit (even though it may not be the last sample of the step)

    -- execute user code here --
    if stepconf[step_n] and stepconf[step_n].doAtStepEnd then
       stepconf[step_n].doAtStepEnd(step_n)
    end
    if stepconf[n_newstep] and stepconf[n_newstep].doPreInit then
       stepconf[n_newstep].doPreInit(n_newstep)
    end

    -- assign "last-step" values from previous step, can be used in Generate_StepConfiguration()
    V12_last_step = V12
    V1R_last_step = V1R
    V2R_last_step = V2R
    i12_last_step = i12
    i1R_last_step = i1R
    i2R_last_step = i2R

    -- rebuild stepconf, re-evaluate expressions --
    stepconf = nil
    collectgarbage('collect')
    Generate_StepConfiguration()

    if not stepconf[n_newstep] then
        -- if new step does not exist, go into OFF mode and stop --
        ec.print(SEV_INFO, "Step "..n_newstep.." does not exist. Switching OFF.")
        stepconf[n_newstep] = {step_type = "OFF"}
    end

    AddMissingTables(n_newstep)

    -- apply step configuration to PGSTAT hardware
    ApplyStepConfig(n_newstep, false)

    -- remember step start time --
    step_tstart = ec.GetSeconds()

    step_n = n_newstep

	-- detect start and end of cycle --
    CycleDetection(n_newstep)

    -- output script progress --
    AddProgressEstimate()
    ec.SetScriptProgress(cycle_n, step_n, progress_accurate or progress_estimate)

    -- if step has special activities, start them here --
    if step_type == "VS" then
        ec.ArbGenRamp(step_v_ctrl, step_slope)
    elseif step_type == "PEIS" or step_type == "GEIS" then
        spectrum_n = spectrum_n + 1
        StartEIS()
    elseif step_type == "OFF" and #(stepconf[n_newstep].limits) == 0 then
        -- if OFF step has no limits, then statemachine is finished --
        ec.print(SEV_INFO, "Script finished")
        finished = true
        -- state machine has finished, but processing continues until all
        -- remaining samples are processed and the last cycle data is output
    end

    collectgarbage('collect')
end

function CycleDetection(n_newstep)

    cds_user = stepconf[n_newstep].cycle_start or "auto" -- cycle starts with charge "c" or discharge "d"
    cd_user  = stepconf[n_newstep].cd          or "auto" -- cycle is charge "c" or discharge "d"
    cd_guess = nil
    if step_type == "CC" or step_type == "GEIS" then
        if step_i_ctrl > 0 then cd_guess = "c" end
        if step_i_ctrl < 0 then cd_guess = "d" end
    elseif step_type == "VS" then
        if step_slope > 0 then cd_guess = "c" end
        if step_slope < 0 then cd_guess = "d" end
    end
    -- remember settings of previous step --
    cds_prev_step = step_cds or "auto"
    cd_prev_step  = step_cd  or "auto"
    -- at this point, only allowed values are "c" and "d" and nil ("auto" equals nil) --
    if cds_user ~= "c" and cds_user ~= "d" then cds_user = nil end
    if cd_user  ~= "c" and cd_user  ~= "d" then cd_user  = nil end
    if step_cds ~= "c" and step_cds ~= "d" then step_cds = nil end
    if step_cd  ~= "c" and step_cd  ~= "d" then step_cd  = nil end
    -- select detection source, depending on priority
    step_cds = cds_user  -- prio 1: user cds value, if existing
            or step_cds  -- prio 2: previous step value, if existing (remain unchanged)
            or cd_user   -- prio 3: user cd value, if existing
            or cd_guess  -- prio 4: guessed cd value, if existing (based on CC set current or CV set slope)
            or "auto"    -- prio 5: default value
    step_cd =  cd_user   -- prio 1: user value, if existing
            or cd_guess  -- prio 2: guessed value, if existing (based on CC set current or CV set slope)
            or step_cd   -- prio 3: previous step value, if existing (remain unchanged)
            or "auto"    -- prio 4: default value
    if step_cds ~= cds_prev_step then
        ec.print(SEV_INFO, "Cycles start with '"..step_cds.."' (c=charge, d=discharge)")
    end
    -- new step will start a new cycle? --
    if((step_cds == "c" and cycle_n == 0 and step_cd == "c")                       -- start of first c-d cycle
    or (step_cds == "d" and cycle_n == 0 and step_cd == "d")                       -- start of first d-c cycle
    or (step_cds == "c" and cd_prev_step == "d" and step_cd ~= cd_prev_step)       -- start of successive c-d cycle
    or (step_cds == "d" and cd_prev_step == "c" and step_cd ~= cd_prev_step)) then -- start of successive d-c cycle
        -- update statemachine cycle state
        cycle_n = cycle_n + 1
        cycle_tstart = step_tstart
        ec.print(SEV_INFO, "Cycle "..cycle_n.." start")
    end
end

function ApplyStepConfig(n, is_edit_on_the_fly)

    -- get stepconf parameters or use default
    step_type                = stepconf[n].step_type           or "Rest"
    step_con                 = stepconf[n].con                 or "i12_V12"
    step_v_ctrl              = stepconf[n].v
    step_i_ctrl              = stepconf[n].i
    step_range               = stepconf[n].range               or "auto"
    step_bw                  = stepconf[n].bw                  or "fast"
    step_slope               = stepconf[n].slope               or 0
    step_diffcap_dV          = stepconf[n].diffcap_dV          or 0.001
    step_diffcap_startdelayR = stepconf[n].diffcap_startdelayR or 5
    step_diffcap_startdelay  = stepconf[n].diffcap_startdelay  or 5

    -- configure step type and connection --
    cd_guess = nil
    if step_type == "OFF" then
        step_pg = "-"
        step_con = "OFF"

    elseif step_type == "Rest" or step_type == "OCV" then  -- open circuit voltage
        step_pg = "-"
        step_con = "Rest"

    elseif step_type == "CC" or step_type == "GEIS" then
        step_pg = "g"
        ec.SetConstCurrent(step_i_ctrl)  -- current in Amps, not Milliamps

    elseif step_type == "CV" or step_type == "PEIS" or step_type == "VS" then
        step_pg = "p"
        ec.SetConstVoltage(step_v_ctrl)

    else
        ec.print(SEV_WARN, "step_type '"..step_type.."' not recognized. Switching to 'Rest' instead.")
        step_pg = "-"
        step_con = "Rest" -- open circuit voltage
    end

    -- execute user code here --
    if stepconf[n].doPostInit then stepconf[n].doPostInit(n) end

    -- firmware calls --
    -- (configure new hardware state as pending changes only, until ec.SwitchNow is called)
    ec.SetCon(step_con)
    ec.SetCurrentRange(step_range)
    ec.SetBandwidth(step_bw)
    ec.ADC_RecStepDelay(stepconf[n].rec_delay_ms or 0)
    ec.ADC_RecDelta(stepconf[n].record.V12   or rec_default.V12,
                    stepconf[n].record.V1R   or rec_default.V1R,
                    stepconf[n].record.V2R   or rec_default.V2R,
                    stepconf[n].record.i     or rec_default.i,
                    stepconf[n].record.t     or rec_default.t)
    ec.RequestTemperature(stepconf[n].temperatureRequest)

    -- apply the new hardware configuration now (switch cell connection and PSTAT/GSTAT into new state) --
    if is_edit_on_the_fly then
        if step_type == "CC" or step_type == "CV" then
            ec.SwitchNow()  -- apply pending changes
            ec.print(SEV_INFO, "Edit-on-the-fly: PGSTAT changes applied")
        else
            ec.print(SEV_INFO, "Edit-on-the-fly: PGSTAT changes are ignored during Rest/EIS/VS/ArbGen")
        end
        ec.SetSafetyLimits( safetylimits.V12_min,
                            safetylimits.V12_max,
                            safetylimits.i,
                            safetylimits.delay_count or 10)
        ec.print(SEV_INFO, "Edit-on-the-fly: Modified script applied")
    else
        ec.print(SEV_INFO, string.format("SwitchTo(%1.0f): %s (triggered at %1.3f s - switching at %1.3f s)", n, step_type, sample_t, ec.GetSeconds()))
        sample_step_tlast = ec.SwitchNow()   -- Firmware returns timestamp of last acquired A/D-sample before switching.
                                             -- At the time of switching, this sample still resides in the A/D-sample-queue.
    end
end

----------------------------- Init EIS ------------------------------------------
-- Initialize the PEIS/GEIS Step and start the spectrum scan
---------------------------------------------------------------------------------
function StartEIS()    

    ec.EIS_Spectrum(stepconf[step_n].eis_amplitude,
                    stepconf[step_n].eis_fstart                          or 100000.0,
                    stepconf[step_n].eis_fend                            or 1.0,
                    stepconf[step_n].eis_fcount_per_ordermagnitude       or 3 ,
                    stepconf[step_n].eis_ordermagnitude                  or 10,
                    stepconf[step_n].eis_averages                        or 1 ,
                    stepconf[step_n].eis_precycles                       or 1 ,
                    stepconf[step_n].eis_record_waveform_up_to_frequency or   -- obsolete since 2026-01-01
                    stepconf[step_n].eis_record_waveform_below_frequency or 1.0,
                    stepconf[step_n].eis_apply_drift_correction          or 1 ,
                    stepconf[step_n].geis_limit_V12_amplitude            or 0 ,
                    stepconf[step_n].geis_limit_V1R_amplitude            or 0 ,
                    stepconf[step_n].geis_limit_V2R_amplitude            or 0 ,
                    stepconf[step_n].peis_limit_i_amplitude              or 0 ,
                    stepconf[step_n].eis_sweep_back                      or 0 ,
                    stepconf[step_n].eis_measure_Z_AUX                   or 0 )
end

--------------------------- Add Progress ----------------------------------------
-- Adds script progress, in percent. Overrides progress_estimate.
-- Gives more accurate script progress than AddProgressEstimate()
-- Can be called from step limit functions.
---------------------------------------------------------------------------------
function AddProgress(val)
    if progress_accurate == nil then
        progress_accurate = 0   -- init variable. "progress_accurate" now has higher priority than "progress_estimate"
    end
    progress_accurate = progress_accurate + val
end

--------------------------- Add Progress Estimate -------------------------------
-- Adds Script Progress automatically, based on an estimation of total step transitions.
-- The variable step_transitions_estimated can be specified in the config section.
---------------------------------------------------------------------------------
function AddProgressEstimate()
    transition_counter = transition_counter + 1

    if transition_counter >= step_transitions_estimated then
        step_transitions_estimated = transition_counter + 1
    end

    progress_estimate = transition_counter / step_transitions_estimated * 100
end


--#############################################################################--
--##                                                                         ##--
--##       P A R T  2 :   A / D   S A M P L E   P R O C E S S I N G          ##--
--##                                                                         ##--
--#############################################################################--

------------------------- Init Sample Processing --------------------------------
-- Initialize global variables for measurement data.
-- All variables must be initialized (set to some value) before they can be used. Options are:
-- 1) Initialize variables to NaN  (Not a Number) if their value is unknown yet and is allowed to be unknown at the beginning.
--                                 A NaN value will not be plotted in diagrams (no marker, connecting line is disconnected).
-- 2) Initialize variables to 0.0  if their value always starts from zero (e.g. charge Q).
--                                 In EL-Software, floating point numbers are exported with 6 decimal digits.
-- 3) Initialize variables to 0    if their value always starts from zero and shall be treated as integer.
--                                 In EL-Software, integer numbers are exported without decimal digits.
-- 4) Initialize variables to MAX  if you want the highest possible value (e.g. time span that never ends)
-- 5) Initialize variables to MIN  if you want the  most  negative  value (e.g. time in the very past)
-- 6) Initialize variables to nil  which means 'not initialized', if the variable must get initialized later on and you want
--                                 the script to abort with an error if the variable does not get initialized later on.
---------------------------------------------------------------------------------
function Init_SampleProcessing()

    -- first some constants
    MAX = math.huge      -- highest positive number
    MIN = math.huge * -1 -- lowest negative number
    NaN = 0/0            -- "Not a Number": Output value 'nan', will not be plotted in diagrams.
    SEV_ERR  = 0         -- info message severity:  E R R O R
    SEV_WARN = 1         -- info message severity:  W A R N I N G
    SEV_INFO = 2         -- info message severity:  I N F O

    -------- GLOBAL VARIABLES --------

    -- A star * means that this variable is selectable in EL-Composer limits.

    -- SAMPLE DATA --
    -- A/D-converter measured data:
    V12              = NaN   -- * A/D sample voltage full cell   / Volt
    V1R              = NaN   -- * A/D sample voltage half cell 1 / Volt
    V2R              = NaN   -- * A/D sample voltage half cell 2 / Volt
    i                = NaN   -- * A/D sample current             / Ampere
    Vaux             = NaN   -- * A/D sample auxiliary voltage   / Volt
    sample_t         = NaN   --   A/D sample time, counted since script start (seconds with microsecond-resolution)
    sample_over      = NaN   --   A/D sample overrange warning (string "i", "v" or "iv")
    sample_i_range   = NaN   --   A/D PGSTAT current range (1="100mA", 2="10mA", 3="1mA", 4="0.1mA")
    -- derived data:
    i12              = NaN   -- * current between electrode 1 and 2
    i1R              = NaN   -- * current between electrode 1 and R
    i2R              = NaN   -- * current between electrode 2 and R
    P                = NaN   -- * power (in any electrode configuration)
    -- accumulated charge, per step:
    Qstep            = 0.0   --   step charge
    Qstep_abs        = 0.0   -- * step charge, absolute value (always positive)
    -- accumulated charge and energy, per cycle:
    Qcd              = 0.0   -- * cycle charge
    Qcd_abs          = 0.0   -- * cycle charge absolute value (always positive), often called "capacity"
    Qc               = 0.0   -- * cycle charged charge,    always positive
    Wc               = 0.0   -- * cycle charged energy,    always positive
    Qd               = 0.0   -- * cycle discharged charge, always positive
    Wd               = 0.0   -- * cycle discharged energy, always positive
    EffQ             = NaN   -- * Qd / Qc
    EffW             = NaN   -- * Wd / Wc
    -- accumulated charge and energy, total:
    Q12              = 0.0   --   total charge flown between electrodes 1 and 2
    Q1R              = 0.0   --   total charge flown between electrodes 1 and R
    Q2R              = 0.0   --   total charge flown between electrodes 2 and R
    Q1               = 0.0   -- * total charge on electrode 1
    Q2               = 0.0   -- * total charge on electrode 2
    QR               = 0.0   -- * total charge on electrode R
    W12              = 0.0   -- * total energy flown between electrodes 1 and 2
    -- differential capacity:
    dQ_C12           = NaN   --   change in charge
    dQ_C1R           = NaN   --   change in charge
    dQ_C2R           = NaN   --   change in charge
    dQ_C1            = NaN   --   change in charge
    dQ_C2            = NaN   --   change in charge
    dQ_CR            = NaN   --   change in charge
    C12              = NaN   --   differential capacity dQ12/dV12 (with current i12)
    C1R              = NaN   --   differential capacity dQ1R/dV1R (with current i1R)
    C2R              = NaN   --   differential capacity dQ2R/dV2R (with current i2R)
    C1               = NaN   --   differential capacity dQ1/dV1R (with current i12) or dQ1/dV12 (with current i1R)
    C2               = NaN   --   differential capacity dQ2/dV2R (with current i12) or dQ2/dV12 (with current i2R)
    CR               = NaN   --   differential capacity dQR/dV2R (with current i1R) or dQR/dV1R (with current i2R)
    -- last voltage and current from previous step:
    V12_last_step    = NaN   --   last measured V12 from step, can be used to init next step
    V1R_last_step    = NaN   --   last measured V1R from step, can be used to init next step
    V2R_last_step    = NaN   --   last measured V2R from step, can be used to init next step
    i12_last_step    = 0.0   --   last measured i12 from step, can be used to init next step
    i1R_last_step    = 0.0   --   last measured i1R from step, can be used to init next step
    i2R_last_step    = 0.0   --   last measured i2R from step, can be used to init next step
    -- lowpass filter --
    V12_avg          = NaN   --   voltage average over e.g. one second
    V1R_avg          = NaN   --   voltage average over e.g. one second
    V2R_avg          = NaN   --   voltage average over e.g. one second
    avg_counter      = 0     --   average filter sample counter
    -- voltage slope |dV/dt| --
    dV12_dt_abs      = NaN   -- * |dV12/dt|
    dV1R_dt_abs      = NaN   -- * |dV1R/dt|
    dV2R_dt_abs      = NaN   -- * |dV2R/dt|
    dVdt_dt_min      = 1.0   --   minimum time interval dt used to calculate slope dV/dt, in seconds
    dVdt_dt_max      = MAX   --   maximum time interval dt used to calculate slope dV/dt, in seconds
    -- sensor data --
    T_cell           = NaN   -- * temperature measured in PAT-Cell-Force and ECD-4
    T_press          = NaN   --   temperature measured in digital pressure sensor of PAT-Cell-Force and ECD-4
    T_board          = NaN   --   temperature measured on channelboard
    T_set            = NaN   --   temperature setpoint of PAT-Tester-i-16 chamber
    T_chamber        = NaN   -- * temperature measured in PAT-Tester-i-16 chamber
    T_ambient        = NaN   --   temperature measured in PAT-Tester-i-16 ambient air
    Pressure         = NaN   -- * gas pressure [bar] in PAT-Cell-Press
    Force            = NaN   -- * cell stack force [N] in PAT-Cell-Force
    Dilation         = NaN   -- * cell stack dilation in [m] in ECD-4
    -- EIS data --
    EIS_freq         = NaN   --   frequency
    EIS_t            = NaN   --   time
    EIS_i_range      = NaN   --   PGSTAT current range
    EIS_V12_dc       = NaN   --   average voltage (DC)
    EIS_V1R_dc       = NaN   --   average voltage (DC)
    EIS_V2R_dc       = NaN   --   average voltage (DC)
    EIS_i12_dc       = NaN   --   average current (DC)
    EIS_i1R_dc       = NaN   --   average current (DC)
    EIS_i2R_dc       = NaN   --   average current (DC)
    EIS_dV12         = NaN   --   amplitude of voltage (AC)
    EIS_dV1R         = NaN   --   amplitude of voltage (AC)
    EIS_dV2R         = NaN   --   amplitude of voltage (AC)
    EIS_di12         = NaN   --   amplitude of current (AC)
    EIS_di1R         = NaN   --   amplitude of current (AC)
    EIS_di2R         = NaN   --   amplitude of current (AC)
    EIS_Z12_re       = NaN   --   impedance between electrode 1 and 2 - real part Re(Z)
    EIS_Z12_im       = NaN   --   impedance between electrode 1 and 2 - imaginary part Im(Z)
    EIS_Z12_mag      = NaN   -- * impedance between electrode 1 and 2 - magnitude |Z|
    EIS_Z12_phi      = NaN   --   impedance between electrode 1 and 2 - phase angle phi(Z)
    EIS_Z12_SFDR     = NaN   --   SFDR      between electrode 1 and 2 - Spurious Free Dynamic Range is a measure for impedance measurement quality
    EIS_Z1R_re       = NaN   --   impedance between electrode 1 and R
    EIS_Z1R_im       = NaN   --   impedance between electrode 1 and R
    EIS_Z1R_mag      = NaN   -- * impedance between electrode 1 and R
    EIS_Z1R_phi      = NaN   --   impedance between electrode 1 and R
    EIS_Z1R_SFDR     = NaN   --   SFDR      between electrode 1 and R
    EIS_Z2R_re       = NaN   --   impedance between electrode 2 and R
    EIS_Z2R_im       = NaN   --   impedance between electrode 2 and R
    EIS_Z2R_mag      = NaN   -- * impedance between electrode 2 and R
    EIS_Z2R_phi      = NaN   --   impedance between electrode 2 and R
    EIS_Z2R_SFDR     = NaN   --   SFDR      between electrode 2 and R
    EIS_Z1_re        = NaN   --   impedance of electrode 1
    EIS_Z1_im        = NaN   --   impedance of electrode 1
    EIS_Z1_mag       = NaN   -- * impedance of electrode 1
    EIS_Z1_phi       = NaN   --   impedance of electrode 1
    EIS_Z1_SFDR      = NaN   --   SFDR      of electrode 1
    EIS_Z2_re        = NaN   --   impedance of electrode 2
    EIS_Z2_im        = NaN   --   impedance of electrode 2
    EIS_Z2_mag       = NaN   -- * impedance of electrode 2
    EIS_Z2_phi       = NaN   --   impedance of electrode 2
    EIS_Z2_SFDR      = NaN   --   SFDR      of electrode 2
    EIS_ZR_re        = NaN   --   impedance of electrode R
    EIS_ZR_im        = NaN   --   impedance of electrode R
    EIS_ZR_mag       = NaN   -- * impedance of electrode R
    EIS_ZR_phi       = NaN   --   impedance of electrode R
    EIS_ZR_SFDR      = NaN   --   SFDR      of electrode R
    EIS_Cs           = NaN   --   capacitance calculated using an R+C (series) equivalent circuit
    EIS_Cp           = NaN   --   capacitance calculated using an R|C (parallel) equivalent circuit
    EIS_precycles    = NaN   --   count of sine-cycles generated before the start of each EIS single-frequency measurement
    EIS_averages     = NaN   --   count of sine-cycles avaraged during each EIS single-frequency-measurement
    EIS_DAC          = NaN   --   for debug only
    EIS_A            = NaN   --   for debug only
    EIS_n            = NaN   --   for debug only
    EIS_m            = NaN   --   for debug only
    EIS_f_err        = NaN   --   for debug only
    EIS_dt           = NaN   --   for debug only
    EIS_finished     = 0     -- * this variable is    0    until spectrum scan is finished (to be used as step limit in EL-Composer)
    eis_finished     = false --   this variable is 'false' until spectrum scan is finished (to be used as step limit in config section)

    -- more variables corresponding to the A/D sample:
    -- note:
    --   All A/D samples are sent to this script through a buffered stream. This has an important consequence:
    --   When they are processed in this script, their step and cycle number can differ from the statemachine state.
    --   This script compares the time stamp "sample_t" of the sample to know which step it originated from.
    --   The time "sample_t" is the true timepoint of A/D-sampling, not the time of the sample processing.
    -- time data:
    sample_t_prev         = 0.0  --   sample time of previous sample (for calculation of dt)
    sample_t_prev_display = MIN  --   sample time of previous Output.txt live view sample (live plot update rate)
    sample_t_prev_rec_sen = MIN  --   sample time of previous sensordata sample (saved to Output-Sensordata.txt)
    sample_t_prev_diffcap = MIN  --   sample time of previous differential-capacity calculation (to print 1 sps maximum)
    sample_step_tstart    = NaN  --   sample time of the first sample of the step
    sample_step_tlast     = NaN  --   sample time of the last sample of the step
    sample_cycle_tstart   = NaN  --   sample time of the first sample of the cycle
    sample_step_t         = NaN  --   sample time in step
    sample_cycle_t        = NaN  --   sample time in cycle
    -- step config:
    sample_step_n         = NaN  --   sample step number
    sample_cycle_n        = NaN  --   sample cycle number
    sample_spectrum_n     = NaN  --   sample EIS spectrum index within the current cycle
    sample_step_type      = ""   --   step type can be: "OFF", "Rest", "CC", "CV", "VS", "PEIS", "GEIS", ...
    sample_step_pg        = ""   --   potentiostat "p" or galvanostat "g"
    sample_cds            = ""   --   cycle starts with charge "c" or discharge "d" (this defines the begin of the first cycle)
    sample_cd             = ""   --   step is charge "c" or discharge "d" (user-defined or auto-detected, used for cycle increments)
    sample_step_con       = ""   --   electrode connection (also called switch matrix), e.g. "i12_V12", "i12_V1R", ...
    sample_step_dV        = nil  --   differential capacity: definition of the smallest dV that allows calculation of "dQ/dV" with good SNR
    -- reduction algorithm:
    rec_default = {V12 = 0.001, V1R = 0.001, V2R = 0.001, i = 0.00001, t = 600}
    sample_rec            = false--   flag: record a sample (true) or do not record the sample (false) to Output.txt
    sample_buf            = NaN  --   buffer fill level of A/D sample buffer stream (in Output.txt, for debugging only)
    display_maximum_dt    = 1.0  --   Display Rate: Show at least one live sample every N seconds in EL-Software cell graphs ("Live View" feature)
    record_sensor_dt      = 60.0 --   Recording Rate: Save at least one sample of sensor data every N seconds (to Output-Sensordata.txt)

    -- placeholder for NewSample and NewEISData argument table --
    arg     = string.rep(" ", 500)   -- NewSample() arguments
    imp_arg = string.rep(" ", 2000)  -- NewEISData() arguments
end


------------------ New Sample (function called by firmware) ---------------------
--  * Sample processing starts here - this is the entry point of sample processing.
--  * The channel firmware calls this routine 1042 times per second to pass measurement
--    data from the A/D-converter sample buffer to this script.
--    The flag "sample_rec" is a boolean variable that flags only some of the samples
--    to be worth saving (recording) in Output.txt.
--    The flag is set by firmware, based upon the recording parameters from this script.
--    It is not possible to save all samples to Output.txt, but all 1042 samples
--    per second will be fully processed here in this script.
--  * To achieve this high throughput, the A/D-samples are buffered in a firmware queue (buffer).
--    As a consequence, the processing of the A/D-samples is not always synchronous to
--    the state of the "state machine" (see "Part I" above).
--    In effect, "Part II" of this script (Sample Processing) always lags behind
--    "Part I" of this script (State Machine) by a few milliseconds.
--    "Part II" should be treated like a separate "thread". The two "threads" can be in
--    different step states: "statemachine step state" and "sample processing step state".
--    The script "Part II" checks the time stamps of the arriving samples:
--    As soon as the last sample of a step has been processed, "Part II" transitions to
--    the next step state.
--    (See variables sample_t, sample_step_tlast, sample_step_n, and sample_cycle_n)
---------------------------------------------------------------------------------
function NewSample(new_t, new_V12, new_V1R, new_V2R, new_i, new_Vaux, _, _, new_over, new_i_range, new_rec, new_buf)

    sample_t       = new_t
    V12            = new_V12
    V1R            = new_V1R
    V2R            = new_V2R
    i              = new_i
    Vaux           = new_Vaux
    sample_over    = new_over     -- string
    sample_i_range = new_i_range  -- integer
    sample_rec     = new_rec      -- boolean flag: record this sample
    sample_buf     = new_buf      -- integer

    if not started then
        ec.print(SEV_INFO, string.format("Initial resting voltages: V12=%1.3fV, V1R=%1.3fV, V2R=%1.3fV)", V12, V1R, V2R))
        SwitchNext()  -- start the first step, possibly using the voltages from above
        InitSamplingStepState()
        started = true
        processing = true
    end

    if started and processing and not paused then

        -- call subroutines to process the sample --

        -- do calculations on sample data
        CalculateSampleValues()

        -- execute user calculations and code
        if stepconf[sample_step_n].doPerSample then stepconf[sample_step_n].doPerSample(sample_step_n) end

        -- execute limit functions (run the state machine)
        CheckLimits()

        -- check if dV is sufficient to calculate differential capacity
        DiffCap()

        -- record sample to database and export file ('Output' table) if the internal reduction
        -- algorithm has flagged the sample as "important", based on the record parameters.
        -- display but not record a new sample at least once every second (display_maximum_dt)
        sample_rec = sample_rec or IsFirstSampleOfStep() or IsLastSampleOfStep()  -- override sample_rec flag to always record first and last sample of a step
        if sample_rec or ((sample_t - sample_t_prev_display) > display_maximum_dt) then
            PrintOutput()
            sample_t_prev_display = sample_t
        end

        -- record sensordata every record_sensor_dt seconds
        if (sample_t - sample_t_prev_rec_sen) > record_sensor_dt then
            PrintOutputSensordata()
            sample_t_prev_rec_sen = sample_t
        end

        -- advance step and/or cycle? --
        if IsLastSampleOfStep() then
            -- this was the last sample of the step
            -- check if it is also the last sample of the cycle --
            if sample_cycle_n == 0 and cycle_n == 1 then
                InitNewCycle()    -- begin processing the first cycle
            elseif (sample_cycle_n < cycle_n) or finished then  -- cycle transition
                OutputCycleData() -- print to Output-Cycles.txt
                InitNewCycle()    -- begin processing the next cycle
            end

            if not finished then
                InitSamplingStepState()  -- init the next sample step
                ec.print(SEV_INFO, "Step "..step_n.." ("..step_type..") is processing")
            else
                -- statemachine has finished the last step
                -- (there is no next step or the next step is "OFF" and has no limits)
                processing = false  -- do not accept any more new samples
                ec.SetScriptExecutionState("Finished")  -- this has to be the very last message
            end
        end
    end
end

----------------- IsLastSampleOfStep --------------------------------------------
-- Checks if A/D sample is the last of the step
---------------------------------------------------------------------------------
function IsLastSampleOfStep()
    return (sample_t == sample_step_tlast)
end

function IsFirstSampleOfStep()
    local isfirstsample = next_sample_is_first_sample_of_step
    next_sample_is_first_sample_of_step = false  -- reset
    return isfirstsample
end

-------------------- CurrentPath ------------------------------------------------
-- Returns "i12", "i1R" or "i2R"
---------------------------------------------------------------------------------
function CurrentPath()
    if (string.sub(sample_step_con, 1, 3) == "i12"
     or sample_step_con == "1vs2"
     or sample_step_con == "1vsR"
     or sample_step_con == "2vsR") then return "i12"
    elseif (string.sub(sample_step_con, 1, 3)) == "i1R"
     or sample_step_con == "Rvs1" then return "i1R"
    elseif (string.sub(sample_step_con, 1, 3)) == "i2R"
     or sample_step_con == "Rvs2" then return "i2R"
    end
end

-------------------- Init Sampling Step State -----------------------------------
-- Updates the sample step state.
-- Since the processing of the A/D-samples lags behind of the state of the
-- state machine, the correct state that belongs to the A/D-samples is set here.
---------------------------------------------------------------------------------
function InitSamplingStepState()

    -- update sample step state
    sample_step_n       = step_n
    sample_step_tstart  = step_tstart    -- time of PGSTAT switching via ec.SwitchNow()
    sample_cycle_tstart = cycle_tstart   -- time of PGSTAT switching via ec.SwitchNow()
    sample_step_type    = step_type        or "-"
    sample_step_pg      = step_pg          or "-"
    sample_step_con     = step_con         or "-"
    sample_step_dV      = step_diffcap_dV  or 0.001
    sample_cds          = step_cds         or "-"
    sample_cd           = step_cd          or "-"
    sample_cycle_n      = cycle_n
    sample_spectrum_n   = spectrum_n

    next_sample_is_first_sample_of_step = true  -- always record the first sample of a new step

    -- reset step charge to zero
    Qstep = 0

    -- execute user code here --
    if DoAtStepStart then DoAtStepStart() end
    if stepconf[sample_step_n].doAtStepStart then stepconf[sample_step_n].doAtStepStart(sample_step_n) end
end

-------------------- Calculate Sample Values ------------------------------------
-- This subroutine calculates power, charge and energy.
---------------------------------------------------------------------------------
function CalculateSampleValues()

    sample_step_t  = sample_t - sample_step_tstart
    sample_cycle_t = sample_t - sample_cycle_tstart

    local dt  = sample_t - sample_t_prev    -- delta t
    local dQ  = i * dt                      -- delta Q (charge)
    local dW  = NaN                         -- delta W (energy)

    -- calculate variables that depend on the electrode connection setting "con" --
    if CurrentPath() == "i12" then
        i12 = i
        i1R = 0.0
        i2R = 0.0
        P   = V12 * i   -- P12
        dW  = P   * dt
        Q12 = Q12 + dQ
        W12 = W12 + dW

    elseif CurrentPath() == "i1R" then
        i12 = 0.0
        i1R = i
        i2R = 0.0
        P   = V1R * i   -- P1R
        dW  = P   * dt  -- for half cell energy efficiency "Eff_W" only
        Q1R = Q1R + dQ

    elseif CurrentPath() == "i2R" then
        i12 = 0.0
        i1R = 0.0
        i2R = i
        P   = V2R * i   -- P2R
        dW  = P   * dt  -- for half cell energy efficiency "Eff_W" only
        Q2R = Q2R + dQ

    else -- Rest (PGstat not connected)
        i12 = 0.0
        i1R = 0.0
        i2R = 0.0
        P   = 0.0
        dW  = 0.0
    end

    -- calculate electrode charge --
    Q1 =  Q12 + Q1R
    Q2 = -Q12 + Q2R
    QR = -Q1R - Q2R

    -- calculate variables that are independent of "con" --
    if sample_cd == "c" then
        --charging--
        Qc  = Qc + dQ  -- add positive charge --> Qc is always positive
        Wc  = Wc + dW  -- add positive energy --> Wc is always positive
        Qcd = Qc
    elseif sample_cd == "d" then
        --discharging--
        Qd  = Qd - dQ  -- subtract negative charge --> Qd is always positive
        Wd  = Wd - dW  -- subtract negative energy --> Wd is always positive
        Qcd = -Qd
    end
    Qstep = Qstep + dQ
    Qstep_abs = math.abs(Qstep)
    Qcd_abs = math.abs(Qcd)


    -- calculate low-pass-filtered values --
    LowpassFilter()

    -- calculate |dV/dt| if sample_rec or after dVdt_dt_max seconds --
    local _dt = sample_t - (dvdt_t_prev or -math.huge)
    if (sample_rec and (_dt > dVdt_dt_min)) or (_dt > dVdt_dt_max) then
        sample_rec = true
        local dV12 = V12_avg - (V12_avg_prev or V12_avg)
        local dV1R = V1R_avg - (V1R_avg_prev or V1R_avg)
        local dV2R = V2R_avg - (V2R_avg_prev or V2R_avg)
        dV12_dt_abs = math.abs(dV12 / _dt) -- |dV12/dt|
        dV1R_dt_abs = math.abs(dV1R / _dt) -- |dV1R/dt|
        dV2R_dt_abs = math.abs(dV2R / _dt) -- |dV2R/dt|
        V12_avg_prev = V12_avg
        V1R_avg_prev = V1R_avg
        V2R_avg_prev = V2R_avg
        dvdt_t_prev = sample_t
    end

    sample_t_prev = sample_t   -- remember sample time for next delta t
end

-------------------- Lowpass Filter  --------------------------------------------
-- Averages the voltages over one second.
-- Used for e.g. Differential Capacity.
---------------------------------------------------------------------------------
function LowpassFilter()

    -- 1000 milliseconds filter time constant
    if avg_counter < (avg_counter_max or 1000) then avg_counter = avg_counter + 1 end

    if avg_counter == 1 then
        V12_avg = V12 -- start value
        V1R_avg = V1R
        V2R_avg = V2R
    else
        V12_avg = V12_avg - (V12_avg / avg_counter)
        V1R_avg = V1R_avg - (V1R_avg / avg_counter)
        V2R_avg = V2R_avg - (V2R_avg / avg_counter)

        V12_avg = V12_avg + (V12 / avg_counter)
        V1R_avg = V1R_avg + (V1R / avg_counter)
        V2R_avg = V2R_avg + (V2R / avg_counter)
    end
end

-------------------- Differential Capacity (dQ/dV) ------------------------------
--  (Re-)Initialize variables:
--  Remember last (previous) voltage and charge (on which dQ/dV has been calculated and saved).
---------------------------------------------------------------------------------
function DiffCap_i12_Init()
    last_V_C12 = V12_avg   last_V_C1 = V1R_avg   last_V_C2 = V2R_avg
    last_Q_C12 = Q12       last_Q_C1 = Q1        last_Q_C2 = Q2
    diffcap_i12_inited = true
end
function DiffCap_i1R_Init()
    last_V_C1R = V1R_avg   last_V_C1 = V12_avg   last_V_CR = V2R_avg
    last_Q_C1R = Q1R       last_Q_C1 = Q1        last_Q_CR = QR
    diffcap_i1R_inited = true
end
function DiffCap_i2R_Init()
    last_V_C2R = V2R_avg   last_V_C2 = V12_avg   last_V_CR = V1R_avg
    last_Q_C2R = Q2R       last_Q_C2 = Q2        last_Q_CR = QR
    diffcap_i2R_inited = true
end

---------- Check if dV has become large enough to calculate dQ/|dV| -------------
function DiffCap()

    if  (sample_step_dV)  -- check if variable is defined
    and (sample_step_type == "CC" or sample_step_type == "VS") then  -- diff cap makes no sense when in "CV" modes and is skipped during GEIS

        if sample_step_t < step_diffcap_startdelayR then

            -- reset variables if diffcap_startdelayR is larger than zero
            -- and keep variables in reset for diffcap_startdelayR seconds
            if CurrentPath() == "i12" then
                DiffCap_i12_Init()
                diffcap_i1R_inited = false
                diffcap_i2R_inited = false
            elseif CurrentPath() == "i1R" then
                diffcap_i12_inited = false
                DiffCap_i1R_Init()
                diffcap_i2R_inited = false
            elseif CurrentPath() == "i2R" then
                diffcap_i12_inited = false
                diffcap_i1R_inited = false
                DiffCap_i2R_Init()
            end

        else
            if sample_t > (sample_t_prev_diffcap + 1)  -- call this code only once per second
            and sample_step_t > step_diffcap_startdelay then
                DiffCap_Check_Calculate_Print()
            end
        end

    end
end

---------- Calculate and Print dQ/|dV| ------------------------------------------
function DiffCap_Check_Calculate_Print()

    -- this code is called only once per second --
    sample_t_prev_diffcap = sample_t
    local dV

    if CurrentPath() == "i12" then
        if not diffcap_i12_inited then DiffCap_i12_Init() end
        -- C12 --
        dV = math.abs(V12_avg - last_V_C12)
        dQ_C12 = Q12 - last_Q_C12
        if dV > sample_step_dV then
            C12 = dQ_C12 / dV
            PrintOutputC12()
            last_V_C12 = V12_avg
            last_Q_C12 = Q12
        end
        -- C1 --
        dV = math.abs(V1R_avg - last_V_C1)
        dQ_C1 = Q1 - last_Q_C1
        if dV > sample_step_dV then
            C1 = dQ_C1 / dV
            PrintOutputC1()
            last_V_C1 = V1R_avg
            last_Q_C1 = Q1
        end
        -- C2 --
        dV = math.abs(V2R_avg - last_V_C2)
        dQ_C2 = Q2 - last_Q_C2
        if dV > sample_step_dV then
            C2 = dQ_C2 / dV
            PrintOutputC2()
            last_V_C2 = V2R_avg
            last_Q_C2 = Q2
        end

    elseif CurrentPath() == "i1R" then
        if not diffcap_i1R_inited then DiffCap_i1R_Init() end
        -- C1R --
        dV = math.abs(V1R_avg - last_V_C1R)
        dQ_C1R = Q1R - last_Q_C1R
        if dV > sample_step_dV then
            C1R = dQ_C1R / dV
            PrintOutputC1R()
            last_V_C1R = V1R_avg
            last_Q_C1R = Q1R
        end
        -- C1 --
        dV = math.abs(V12_avg - last_V_C1)
        dQ_C1 = Q1 - last_Q_C1
        if dV > sample_step_dV then
            C1 = dQ_C1 / dV
            PrintOutputC1()
            last_V_C1 = V12_avg
            last_Q_C1 = Q1
        end
        -- CR --
        dV = math.abs(V2R_avg - last_V_CR)
        dQ_CR = QR - last_Q_CR
        if dV > sample_step_dV then
            CR = dQ_CR / dV
            PrintOutputCR()
            last_V_CR = V2R_avg
            last_Q_CR = QR
        end

    elseif CurrentPath() == "i2R" then
        if not diffcap_i2R_inited then DiffCap_i2R_Init() end
        -- C2R --
        dV = math.abs(V2R_avg - last_V_C2R)
        dQ_C2R = Q2R - last_Q_C2R
        if dV > sample_step_dV then
            C2R = dQ_C2R / dV
            PrintOutputC2R()
            last_V_C2R = V2R_avg
            last_Q_C2R = Q2R
        end
        -- C2 --
        dV = math.abs(V12_avg - last_V_C2)
        dQ_C2 = Q2 - last_Q_C2
        if dV > sample_step_dV then
            C2 = dQ_C2 / dV
            PrintOutputC2()
            last_V_C2 = V12_avg
            last_Q_C2 = Q2
        end
        -- CR --
        dV = math.abs(V1R_avg - last_V_CR)
        dQ_CR = QR - last_Q_CR
        if dV > sample_step_dV then
            CR = dQ_CR / dV
            PrintOutputCR()
            last_V_CR = V1R_avg
            last_Q_CR = QR
        end
    end
end

-------------------- Output Cycle Data ------------------------------------------
-- This subroutine is called when a complete cycle has been finished.
---------------------------------------------------------------------------------
function OutputCycleData()
    -- calculate charge efficiency --
    if sample_cds == "d" then
        -- cycles start with discharge --
        EffQ = Qc / Qd
        EffW = Wc / Wd
    else
        -- cycles start with charge --
        EffQ = Qd / Qc
        EffW = Wd / Wc
    end

    -- print cycle data to Output-Cycles table --
    PrintOutputCycles()

    -- do a check on electrode charge: Q1+Q2+QR = 0 ? --
    if math.abs(Q1 + Q2 + QR) > 0.00001 then
        ec.print(SEV_WARN, "Q1+Q2+QR does not equal zero.")
    end
end

function InitNewCycle()

    Qc = 0.0  -- null charge
    Qd = 0.0  -- null charge
    Wc = 0.0  -- null energy
    Wd = 0.0  -- null energy
    spectrum_n = 0

    if not finished then ec.print(SEV_INFO, "Cycle "..cycle_n.." is processing") end
end

----------------- New EIS Data (function called by firmware) --------------------
-- The channel firmware calls this routine after every single EIS frequency measurement.
-- See above for variable definitions
---------------------------------------------------------------------------------
function NewEISData_V2(...)

    imp_arg = {...}   -- argument is an array of impedance data values

    EIS_freq     = imp_arg[1]
    EIS_t        = imp_arg[2]
    EIS_i_range  = imp_arg[5]
    EIS_V12_dc   = imp_arg[6]
    EIS_V1R_dc   = imp_arg[7]
    EIS_V2R_dc   = imp_arg[8]
    EIS_i12_dc   = imp_arg[9]
    EIS_i1R_dc   = imp_arg[10]
    EIS_i2R_dc   = imp_arg[11]
    EIS_dV12     = imp_arg[12]
    EIS_dV1R     = imp_arg[13]
    EIS_dV2R     = imp_arg[14]
    EIS_di12     = imp_arg[15]
    EIS_di1R     = imp_arg[16]
    EIS_di2R     = imp_arg[17]
    EIS_Z12_re   = imp_arg[18]  EIS_Z12_im = imp_arg[19]  EIS_Z12_mag = imp_arg[20]  EIS_Z12_phi = imp_arg[21]  EIS_Z12_SFDR = imp_arg[22]
    EIS_Z1R_re   = imp_arg[23]  EIS_Z1R_im = imp_arg[24]  EIS_Z1R_mag = imp_arg[25]  EIS_Z1R_phi = imp_arg[26]  EIS_Z1R_SFDR = imp_arg[27]
    EIS_Z2R_re   = imp_arg[28]  EIS_Z2R_im = imp_arg[29]  EIS_Z2R_mag = imp_arg[30]  EIS_Z2R_phi = imp_arg[31]  EIS_Z2R_SFDR = imp_arg[32]
    EIS_Z1_re    = imp_arg[33]  EIS_Z1_im  = imp_arg[34]  EIS_Z1_mag  = imp_arg[35]  EIS_Z1_phi  = imp_arg[36]  EIS_Z1_SFDR  = imp_arg[37]
    EIS_Z2_re    = imp_arg[38]  EIS_Z2_im  = imp_arg[39]  EIS_Z2_mag  = imp_arg[40]  EIS_Z2_phi  = imp_arg[41]  EIS_Z2_SFDR  = imp_arg[42]
    EIS_ZR_re    = imp_arg[43]  EIS_ZR_im  = imp_arg[44]  EIS_ZR_mag  = imp_arg[45]  EIS_ZR_phi  = imp_arg[46]  EIS_ZR_SFDR  = imp_arg[47]
    EIS_Cs       = imp_arg[48]
    EIS_Cp       = imp_arg[49]
    EIS_precycles= imp_arg[50]
    EIS_averages = imp_arg[51]
    EIS_DAC      = imp_arg[56] -- for debug only
    EIS_A        = imp_arg[57] -- for debug only
    EIS_n        = imp_arg[58] -- for debug only
    EIS_m        = imp_arg[59] -- for debug only
    EIS_f_err    = imp_arg[60] -- for debug only
    EIS_dt       = imp_arg[61] -- for debug only

    collectgarbage('collect')

    PrintOutputImpedance(false)
end


--#############################################################################--
--##                                                                         ##--
--##               P A R T  3 :   O U T P U T   T A B L E S                  ##--
--##                                                                         ##--
--#############################################################################--

---------------- Send Output.txt Data to EL-Software Server -----------------------
--  Plotted as y over x=time, with variable time interval (see reduction algorithm).
-----------------------------------------------------------------------------------
function PrintOutput()
    ec.WriteOutputData("Output.txt", sample_rec,
    "t"       , "s"   , sample_t,
    "t_cycle" , "s"   , sample_cycle_t,
    "t_step"  , "s"   , sample_step_t,
    "over"    , ""    , sample_over,
    "cycle"   , ""    , sample_cycle_n,
    "step"    , ""    , sample_step_n,
    "type"    , ""    , sample_step_type,
    "p/g"     , ""    , sample_step_pg,
    "c/d"     , ""    , sample_cd,
    "con"     , ""    , sample_step_con,
    "I-Range" , ""    , sample_i_range,
    "V12"     , "V"   , V12,
    "V1R"     , "V"   , V1R,
    "V2R"     , "V"   , V2R,
    "I12"     , "mA"  , i12 * 1000,
    "I1R"     , "mA"  , i1R * 1000,
    "I2R"     , "mA"  , i2R * 1000,
    "|Qstep|" , "mAh" , Qstep_abs / 3.6,
    "Qcd"     , "mAh" , Qcd       / 3.6,
    "|Qcd|"   , "mAh" , Qcd_abs   / 3.6,
    "Qc"      , "mAh" , Qc  / 3.6,
    "Qd"      , "mAh" , Qd  / 3.6,
    "Q1"      , "mAh" , Q1  / 3.6,
    "Q2"      , "mAh" , Q2  / 3.6,
    "QR"      , "mAh" , QR  / 3.6,
    "P"       , "mW"  , P   * 1000,
    "W12"     , "mWh" , W12 / 3.6,
    "Vaux"    , "V"   , Vaux,
    "T_cell"  , "degC", T_cell,
    "Pressure", "mbar", Pressure * 1000,
    "Dilation", "um"  , Dilation * 1000000,
    "Force"   , "N"   , Force,
    "buf"     , ""    , sample_buf)
end

-------------------- Send Output-Sensordata.txt Data ----------------------------
--  Plotted as y over x=time, with constant time interval 'record_sensor_dt'.
--  This is send once every 'record_sensor_dt' seconds, independent from the reduction algorithm.
---------------------------------------------------------------------------------
function PrintOutputSensordata()
    ec.WriteOutputData("Output-Sensordata.txt", true,
    "t"        , "s"   , sample_t,
    "t_cycle"  , "s"   , sample_cycle_t,
    "t_step"   , "s"   , sample_step_t,
    "T_set"    , "degC", T_set,
    "T_chamber", "degC", T_chamber,
    "T_cell"   , "degC", T_cell,
    "T_press"  , "degC", T_press,  -- temperature of pressure sensor
    "Pressure" , "mbar", Pressure * 1000,
    "Dilation" , "um"  , Dilation * 1000000,
    "Force"    , "N"   , Force,
    "T_board"  , "degC", T_board,
    "T_ambient", "degC", T_ambient)
end

-------------------- Send Differential Capacity Data ----------------------------
--  Plotted as y = C12 over x = V12
---------------------------------------------------------------------------------
function PrintOutputC12()
    ec.WriteOutputData("Output-C12.txt", true,
    "t"    , "s"    , sample_t,
    "cycle", ""     , sample_cycle_n,
    "step" , ""     , sample_step_n,
    "V12"  , "V"    , V12_avg,
    "dQ12" , "uAh"  , dQ_C12 / 0.0036,
    "C12"  , "mAh/V", C12    / 3.6)
end
function PrintOutputC1R(header)
    ec.WriteOutputData("Output-C1R.txt", true,
    "t"    , "s"    , sample_t,
    "cycle", ""     , sample_cycle_n,
    "step" , ""     , sample_step_n,
    "V1R"  , "V"    , V1R_avg,
    "dQ1R" , "uAh"  , dQ_C1R / 0.0036,
    "C1R"  , "mAh/V", C1R    / 3.6)
end
function PrintOutputC2R(header)
    ec.WriteOutputData("Output-C2R.txt", true,
    "t"    , "s"    , sample_t,
    "cycle", ""     , sample_cycle_n,
    "step" , ""     , sample_step_n,
    "V2R"  , "V"    , V2R_avg,
    "dQ2R" , "uAh"  , dQ_C2R / 0.0036,
    "C2R"  , "mAh/V", C2R    / 3.6)
end
function PrintOutputC1(header)
    ec.WriteOutputData("Output-C1.txt", true,
    "t"    , "s"    , sample_t,
    "cycle", ""     , sample_cycle_n,
    "step" , ""     , sample_step_n,
    "V12"  , "V"    , V12_avg,
    "V1R"  , "V"    , V1R_avg,
    "dQ1"  , "uAh"  , dQ_C1 / 0.0036,
    "C1"   , "mAh/V", C1    / 3.6)
end
function PrintOutputC2(header)
    ec.WriteOutputData("Output-C2.txt", true,
    "t"    , "s"    , sample_t,
    "cycle", ""     , sample_cycle_n,
    "step" , ""     , sample_step_n,
    "V12"  , "V"    , V12_avg,
    "V2R"  , "V"    , V2R_avg,
    "dQ2"  , "uAh"  , dQ_C2 / 0.0036,
    "C2"   , "mAh/V", C2    / 3.6)
end
function PrintOutputCR(header)
    ec.WriteOutputData("Output-CR.txt", true,
    "t"    , "s"    , sample_t,
    "cycle", ""     , sample_cycle_n,
    "step" , ""     , sample_step_n,
    "V1R"  , "V"    , V1R_avg,
    "V2R"  , "V"    , V2R_avg,
    "dQR"  , "uAh"  , dQ_CR / 0.0036,
    "CR"   , "mAh/V", CR    / 3.6)
end

----------------------- Send Output-Cycles.txt Data -----------------------------
--  Plotted as y over x = cycle number
---------------------------------------------------------------------------------
function PrintOutputCycles()
    ec.WriteOutputData("Output-Cycles.txt", true,
    "t"         , "s"   , sample_t,
    "t_start"   , "s"   , sample_cycle_tstart,
    "t_duration", "s"   , sample_cycle_t,
    "cycle"     , ""    , sample_cycle_n,
    "Qc_cyc"    , "mAh" , Qc / 3.6,
    "Qd_cyc"    , "mAh" , Qd / 3.6,
    "Wc_cyc"    , "mWh" , Wc / 3.6,
    "Wd_cyc"    , "mWh" , Wd / 3.6,
    "Eff_Q"     , ""    , EffQ,
    "Eff_W"     , ""    , EffW)
end

---------------------- Send Output-Impedance.txt Data ---------------------------
--  Plotted as y over x=time or as Bode plot or as Nyquist plot.
---------------------------------------------------------------------------------
function PrintOutputImpedance(header)
    t = {
    "freq"       , "Hz"  , EIS_freq,
    "t"          , "s"   , EIS_t,
    "t_cycle"    , "s"   , EIS_t - cycle_tstart,
    "cycle"      , ""    , sample_cycle_n,
    "spectrum"   , ""    , sample_spectrum_n,
    "step"       , ""    , sample_step_n,
    "type"       , ""    , sample_step_type,
    "p/g"        , ""    , sample_step_pg,
    "c/d"        , ""    , sample_cd,
    "con"        , ""    , sample_step_con,
    "V12"        , "V"   , EIS_V12_dc,
    "V1R"        , "V"   , EIS_V1R_dc,
    "V2R"        , "V"   , EIS_V2R_dc,
    "dV12"       , "mV"  , EIS_dV12   * 1000,
    "dV1R"       , "mV"  , EIS_dV1R   * 1000,
    "dV2R"       , "mV"  , EIS_dV2R   * 1000,
    "I12"        , "mA"  , EIS_i12_dc * 1000,
    "I1R"        , "mA"  , EIS_i1R_dc * 1000,
    "I2R"        , "mA"  , EIS_i2R_dc * 1000,
    "dI12"       , "mA"  , EIS_di12   * 1000,
    "dI1R"       , "mA"  , EIS_di1R   * 1000,
    "dI2R"       , "mA"  , EIS_di2R   * 1000,
    "I-Range"    , ""    , EIS_i_range,
    "Q1"         , "mAh" , Q1      / 3.6,
    "Q2"         , "mAh" , Q2      / 3.6,
    "QR"         , "mAh" , QR      / 3.6,
    "Qcd"        , "mAh" , Qcd     / 3.6,
    "|Qcd|"      , "mAh" , Qcd_abs / 3.6,
    "Qc"         , "mAh" , Qc      / 3.6,
    "Qd"         , "mAh" , Qd      / 3.6,
    "Re(Z12)"    , "Ohm" , EIS_Z12_re,
    "Im(Z12)"    , "Ohm" , EIS_Z12_im,
    "|Z12|"      , "Ohm" , EIS_Z12_mag,
    "phi(Z12)"   , "deg" , EIS_Z12_phi,
    "SFDR(Z12)"  , "dB"  , EIS_Z12_SFDR,
    "Re(Z1)"     , "Ohm" , EIS_Z1_re,
    "Im(Z1)"     , "Ohm" , EIS_Z1_im,
    "|Z1|"       , "Ohm" , EIS_Z1_mag,
    "phi(Z1)"    , "deg" , EIS_Z1_phi,
    "SFDR(Z1)"   , "dB"  , EIS_Z1_SFDR,
    "Re(Z2)"     , "Ohm" , EIS_Z2_re,
    "Im(Z2)"     , "Ohm" , EIS_Z2_im,
    "|Z2|"       , "Ohm" , EIS_Z2_mag,
    "phi(Z2)"    , "deg" , EIS_Z2_phi,
    "SFDR(Z2)"   , "dB"  , EIS_Z2_SFDR,
    "Re(ZR)"     , "Ohm" , EIS_ZR_re,
    "Im(ZR)"     , "Ohm" , EIS_ZR_im,
    "|ZR|"       , "Ohm" , EIS_ZR_mag,
    "phi(ZR)"    , "deg" , EIS_ZR_phi,
    "SFDR(ZR)"   , "dB"  , EIS_ZR_SFDR,
    "Re(Z1R)"    , "Ohm" , EIS_Z1R_re,
    "Im(Z1R)"    , "Ohm" , EIS_Z1R_im,
    "|Z1R|"      , "Ohm" , EIS_Z1R_mag,
    "phi(Z1R)"   , "deg" , EIS_Z1R_phi,
    "SFDR(Z1R)"  , "dB"  , EIS_Z1R_SFDR,
    "Re(Z2R)"    , "Ohm" , EIS_Z2R_re,
    "Im(Z2R)"    , "Ohm" , EIS_Z2R_im,
    "|Z2R|"      , "Ohm" , EIS_Z2R_mag,
    "phi(Z2R)"   , "deg" , EIS_Z2R_phi,
    "SFDR(Z2R)"  , "dB"  , EIS_Z2R_SFDR,
    "Cs"         , "uF"  , EIS_Cs * 1000000,
    "Cp"         , "uF"  , EIS_Cp * 1000000,
    "A"          , ""    , EIS_A  * 1000,
    "n"          , ""    , EIS_n,
    "m"          , ""    , EIS_m,
    "f_err"      , "%"   , EIS_f_err,
    "dt"         , "s"   , EIS_dt,
    "pre"        , ""    , EIS_precycles,
    "avg"        , ""    , EIS_averages,
    "DA"         , ""    , EIS_DACm}
    ec.WriteOutputData("Output-Impedance.txt", true, table.unpack(t))
end


-- Now that all Lua script functions have been defined --
if not started then
    -- init:
    ec.SetScriptExecutionState("Init")
    CheckFirmwareVersion()
    Init_StateMachine()
    Init_SampleProcessing()  -- must be called before stepconf, to init variables used in stepconf
    -- start:
    StartMeasurement()
else
    -- update only ("edit-on-the-fly"):
    Generate_StepConfiguration()
    AddMissingTablesInAllSteps()
    ApplyStepConfig(sample_step_n, true)
end

-- End of Script --