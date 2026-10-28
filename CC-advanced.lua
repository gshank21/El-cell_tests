---------------------------------------------------------------------------------
--                             PAT-Tester-Script                               --
--                    using script-base version 2025-02-13                     --
--                    requires channel-firmware 145 or higher                  --
---------------------------------------------------------------------------------

--#############################################################################--
--##                                                                         ##--
--##            P A R T  1 :     S T A T E   M A C H I N E                   ##--
--##                                                                         ##--
--#############################################################################--

-------------------- Generate Step Configuration --------------------------------
-- This function contains the defintion of the script steps.
-- It is called before every step transition, to re-calculate any math expressions.
-- Edit-on-the-fly: This function can be changed at any time during the experiment.
--   * Changes that become effective immediately include:
--     * Recording criteria
--     * Step limits (i.e. limit conditions and loop counts)
--     * Safety limits
--     * Constant voltage and constant current in CV and CC steps
--     * Current range and bandwidth settings in CV and CC steps
--   * Changes that do not become effective immediately (wait for next step call):
--     * Constant voltage and constant current in EIS and VS steps
--     * EIS AC parameters
--     * Slope of voltage scan (VS)
--     * Halfcycle definition (= step belongs to 'charge' or 'discharge' halfcycle?)
--     * Script progress definition
--   * Hint: Use a step limit like 'step_t > 0' to end a step immediately.
---------------------------------------------------------------------------------
function Generate_StepConfiguration()

-- configuration section --
safetylimits = {V12_min = -10, V12_max = 10, i = 0.11, delay_count = 10}

SelfCal = false				-- true: test starts with Self Calibration
cell_with_R = true			-- true/false: cell is with/without R electrode 
start_with_charge = true	-- true/false: start cycle with positive/negative current

Q0 = Q0 or ec.GetInputVariable("Q0") or 0.3	-- capacity in As
i0 = Q0/3600				-- current at 1C rate
cycle_Q0_calc = 1			-- up to this cycle Q0 is being updated

dt_OCV_ini = 5				-- initial rest time
dt_OCV_final = 5			-- final rest time 

-- global recording criteria
r_0 = {V12 = 0.001, V1R = 0.001, V2R = 0.001, i = 0.00001, t = 60}
r_off = {V12 = 999, V1R = 999, V2R = 999, i = 999, t = 1e6}
r_sine = {V12 = 999, V1R = 999, V2R = 999, i = 999, t = 0.1}

if not cell_with_R then
	r_0 = {V12 = 0.001, V1R = 999, V2R = 999, i = 0.00001, t = 60}
end

record_sensor_dt = 60
display_maximum_dt = 1

NN = NN or 1    -- parameter table column
-- Cycle-specific parameters (can be modified during runtime)
-- NN =				 1			2			3			4			5			-- parameter column
N_sub_cycles =		{10,		0,			0,			0,			0}			-- number of cycles to be run with below given parameters. Set 0 to skip column
Vcontrol =			{"V12",		"V1R",		"V2R",		"V12",		"V12"}		-- the voltage to be controlled: V12, V1R or V2R
Icontrol =			{"i12",		"i12",		"i12",		"i12",		"i12"}		-- the current to be controlled: i12, i1R or i2R
VLo =				{0,			0,			-0.5,		0,			0}			-- lower voltage limit (given for Vcontrol)  
VHi =				{1,			0.5,		0,			1,			1}			-- upper voltage limit  
i_charge =			{i0*100,	i0*100,		i0*100,		i0*100,		i0*100}		-- charge current as multiple of i0 (unsigned)    
i_disch  =			{i0*100,	i0*100,		i0*100,		i0*100,		i0*100}		-- discharge current as multiple of i0 (unsigned)   
cap_delay =			{5,			5,			5,			5,			5}			-- delay before recording dQ/dV during CC step
cap_delay_R =		{5,			5,			5,			5,			5}			-- delay after reset..
cap_dV =			{0.001,		0.001,		0.001,		0.001,		0.001}		-- dV to calculate dQ/dV during CC step

dt_CC_max_charge =	{1e6,		1e6,		1e6,		1e6,	    1e6}		-- maximum duration of CC charge half cycle. Set high to deactivate
dt_CC_max_disch =	{1e6,		1e6,		1e6,		1e6,	    1e6}		-- maximum duration of CC discharge half cycle. Set high to deactivate

dt_hold_charge =	{10,		10,			10,			10,			10}			-- CV step at full charge ends if t(CV) > dt_hold_charge
i_limit_charge =	{0,			0,			0,			0,			0}			-- 	  or |i| < i_limit_charge

dt_hold_disch  =	{10,		10,			10,			10,			10}			-- CV step at full discharge ends if t(CV) > dt_hold_disch
i_limit_disch  =	{0,			0,			0,			0,			0}			-- 	  or |i| < i_limit_disch

dt_OCV_charge =		{0,			0,			0,			0,			0}			-- rest step at full charge ends if t(OCV) > dt_OCV_charge (Set 0 to deactivate)
dt_OCV_disch =		{0,			0,			0,			0,			0}			-- rest step at full discharge ends if t(OCV) > dt_OCV_disch (Set 0 to deactivate)

dt_GEIS =			{1e6,		1e6,		1e6,		1e6,		1e6}		-- during CC, call GEIS if t_step > dt_GEIS (Set high to disable GEIS) 
dQ_GEIS =	        {1e6,		1e6,		1e6,		1e6,		1e6}		-- 	  or dQ_step > dQ_GEIS
dV12_CC_min =		{0,			0,			0,			0,			0}			-- 	  and dV12 > dV12_CC_min
dV1R_CC_min =		{0,			0,			0,			0,			0}			-- 	  and dV1R > dV1R_CC_min
dV2R_CC_min =		{0,			0,			0,			0,			0}			-- 	  and dV2R > dV2R_CC_min

dt_PEIS =			{1e6,		1e6,		1e6,		1e6,		1e6}		-- time interval between subsequent PEIS steps during CV (Set high to disable PEIS)

i_GEIS =			{0.005,	    0.005,		0.005,		0.005,		0.005}		-- (initial) GEIS current amplitude
v_EIS =				{0.02,		0.01,		0.01,		0.02,		0.02}		-- the voltage amplitude to be controlled with PEIS and aa-GEIS (given for Vcontrol)
f0_GEIS =			{1, 		1,			1,			1,			1}			-- start GEIS freq sweep at f0_GEIS (>= fe_GEIS)
fe_GEIS =			{1,			1,			1,			1,			1}			-- end GEIS freq sweep at fe_GEIS
f0_PEIS =			{1,			1,			1,			1,			1}			-- start PEIS freq sweep at f0_PEIS (>= fe_PEIS)
fe_PEIS =			{1,			1,			1,			1,			1}			-- end PEIS freq sweep at fe_PEIS
fcount =			{6,			6,			6,			6,			6}			-- points per freq decade
aa_GEIS =			{true,		true,		true,		true,		true}		-- set true to control v_EIS during GEIS. Amplitude adaption only possible if f0 >= fe
geis_backsweep =	{0,			0,			0,			0,			0}			-- set 1 to run also GEIS backsweep f0 -> fe -> f0
peis_backsweep =	{0,			0,			0,			0,			1}			-- set 1 to run also PEIS backsweep f0 -> fe -> f0
record_sine =		{true,		true,		true,		true,		true}		-- set true to record sine in Output.txt (10 pts per sec, only if f0 == fe and if f < 1 Hz)
dVLo_clear =		{0.05,		0.025,		0.025,		0.05,		0.05}		-- do not call GEIS if Vcontrol < (VLo + dVLo_clear)
dVHi_clear =		{0.05,		0.025,		0.025,		0.05,		0.05}		-- do not call GEIS if Vcontrol > (VHi - dVHi_clear)

N_tot_cycles = 0 for i = 1, #(N_sub_cycles) do N_tot_cycles = N_tot_cycles + N_sub_cycles[i] end  -- total number of cycles

CycleCounter = CycleCounter or 0

progress_accurate = CycleCounter/N_tot_cycles*100
if progress_accurate <= 1 then progress_accurate = 1 else progress_accurate = math.floor(progress_accurate) end

if (f0_GEIS[NN] > 1 and fe_GEIS[NN] > 1) or (not record_sine[NN]) then eis_record_waveform_up_to_frequency_GEIS = 0 else eis_record_waveform_up_to_frequency_GEIS = 1 end
if (f0_PEIS[NN] > 1 and fe_PEIS[NN] > 1) or (not record_sine[NN]) then eis_record_waveform_up_to_frequency_PEIS = 0 else eis_record_waveform_up_to_frequency_PEIS = 1 end

if f0_GEIS[NN] == fe_GEIS[NN] then geis_backsweep[NN] = 0 end
if f0_PEIS[NN] == fe_PEIS[NN] then peis_backsweep[NN] = 0 end

reset_dt_CC = reset_dt_CC or true
Q_CC_start = Q_CC_start or 0

Qcc_cyc = Qcc_cyc or 0
Qdd_cyc = Qdd_cyc or 0					  
dQ_CC = (function() return ((Qcd_abs - Q_CC_start)) end)				-- dQ since CC step start
dV12_step = (function() return (math.abs(V12 - V12_last_step)) end)     -- dV12 since CC step start
dV1R_step = (function() return (math.abs(V1R - V1R_last_step)) end)     -- dV1R since CC step start
dV2R_step = (function() return (math.abs(V2R - V2R_last_step)) end)     -- dV2R since CC step start

if Vcontrol[NN] == "V12" and Icontrol[NN] == "i12" then
   conPSTAT = "1vs2" conGSTAT = "1vs2"
   V_fully_charged = VHi[NN]
   V_fully_discharged = VLo[NN]
   FullyCharged = (function() return (V12 > VHi[NN]) end)
   FullyDischarged = (function() return (V12 < VLo[NN]) end)
   AlmostCharged = (function() return (V12 > (VHi[NN] - dVHi_clear[NN])) end)
   AlmostDischarged = (function() return (V12 < (VLo[NN] + dVLo_clear[NN])) end)
elseif Vcontrol[NN] == "V1R" and Icontrol[NN] == "i12" then
   conPSTAT = "1vsR" conGSTAT = "1vs2"
   V_fully_charged = VHi[NN]
   V_fully_discharged = VLo[NN]
   FullyCharged = (function() return (V1R > VHi[NN]) end)
   FullyDischarged = (function() return (V1R < VLo[NN]) end)
   AlmostCharged = (function() return (V1R > (VHi[NN] - dVHi_clear[NN])) end)
   AlmostDischarged = (function() return (V1R < (VLo[NN] + dVLo_clear[NN])) end)
elseif Vcontrol[NN] == "V2R" and Icontrol[NN] == "i12" then
   conPSTAT = "2vsR" conGSTAT = "1vs2"
   V_fully_charged = VLo[NN]
   V_fully_discharged = VHi[NN]
   FullyCharged = (function() return (V2R < VLo[NN]) end) 
   FullyDischarged = (function() return (V2R > VHi[NN]) end)
   AlmostCharged = (function() return (V2R < (VLo[NN] + dVLo_clear[NN])) end)  
   AlmostDischarged = (function() return (V2R > (VHi[NN] - dVHi_clear[NN])) end)
elseif Vcontrol[NN] == "V1R" and Icontrol[NN] == "i1R" then  -- V1R increases with i1R > 0
   conPSTAT = "Rvs1" conGSTAT = "Rvs1"
   V_fully_charged = VHi[NN]
   V_fully_discharged = VLo[NN]
   FullyCharged = (function() return (V1R > VHi[NN]) end)
   FullyDischarged = (function() return (V1R < VLo[NN]) end)
   AlmostCharged = (function() return (V1R > (VHi[NN] - dVHi_clear[NN])) end)
   AlmostDischarged = (function() return (V1R < (VLo[NN] + dVLo_clear[NN])) end)
elseif Vcontrol[NN] == "V2R" and Icontrol[NN] == "i2R" then  -- V2R increases with i2R > 0  
   conPSTAT = "Rvs2" conGSTAT = "Rvs2"
   V_fully_charged = VHi[NN]  
   V_fully_discharged = VLo[NN]
   FullyCharged = (function() return (V2R > VHi[NN]) end)
   FullyDischarged = (function() return (V2R < VLo[NN]) end)
   AlmostCharged = (function() return (V2R > (VHi[NN] - dVHi_clear[NN])) end)
   AlmostDischarged = (function() return (V2R < (VLo[NN] + dVLo_clear[NN])) end)
else
   InvalidControlMode = true
end

------------------------- GEIS amplitude adaption --------------------------------
function Adapt_GEIS_amplitude()
    if record_sine[NN] then record = r_sine else record = r_off end
	if aa_GEIS[NN] and f0_GEIS[NN] == fe_GEIS[NN] then  -- single freq aa-GEIS
	    if GEIS_amplitude == nil then  -- if GEIS is performed the very first time
		   GEIS_amplitude = i_GEIS[NN]
	    else    -- amplitude correction; EIS_dVxx is the measured voltage amplitude of the previous EIS measurement
		   if Vcontrol[NN] == "V12" then
			 GEIS_amplitude = GEIS_amplitude * (v_EIS[NN] / EIS_dV12)
		   elseif Vcontrol[NN] == "V1R" then
			 GEIS_amplitude = GEIS_amplitude * (v_EIS[NN] / EIS_dV1R)
		   elseif Vcontrol[NN] == "V2R" then
			 GEIS_amplitude = GEIS_amplitude * (v_EIS[NN] / EIS_dV2R)
		   end 
		end
		eis_amplitude = GEIS_amplitude
		geis_limit_V12_amplitude = 0 geis_limit_V1R_amplitude = 0 geis_limit_V2R_amplitude = 0
	elseif aa_GEIS[NN] and f0_GEIS[NN] > fe_GEIS[NN]  then  -- freq sweep aa-GEIS
	   eis_amplitude = i_GEIS[NN]
	   if Vcontrol[NN] == "V12" then
		  geis_limit_V12_amplitude = v_EIS[NN] geis_limit_V1R_amplitude = 0 geis_limit_V2R_amplitude = 0
	   elseif Vcontrol[NN] == "V1R" then
		  geis_limit_V12_amplitude = 0 geis_limit_V1R_amplitude = v_EIS[NN] geis_limit_V2R_amplitude = 0   
	   elseif Vcontrol[NN] == "V2R" then
		  geis_limit_V12_amplitude = 0 geis_limit_V1R_amplitude = 0 geis_limit_V2R_amplitude = v_EIS[NN]      
	   end 
	else     -- no amplitude adaption 
	   eis_amplitude = i_GEIS[NN]
	   geis_limit_V12_amplitude = 0 geis_limit_V1R_amplitude = 0 geis_limit_V2R_amplitude = 0
	end
	Q_CC_start = Qcd_abs
end

stepconf =
{ 
[0] = { -- SelfCal
        step_type = "Rest",
        record = r_off,
        limits = {
            [0] = function(limit) if SelfCal then ec.SelfCal() SwitchNext() else SwitchNext() end end
        }
},
[5] = { -- Rest
        step_type = "Rest",
        record = r_0,
        limits = {
            [0] = function(limit) if N_tot_cycles == 0 then SwitchTo(80) end end,
			[1] = function(limit) if (step_t > dt_OCV_ini) and start_with_charge then SwitchNext() end end,
            [2] = function(limit) if (step_t > dt_OCV_ini) and not start_with_charge then SwitchTo(40) end end
        }
},
[10] = { -- CC charge with diffcap calculation
        step_type = "CC",
        doPreInit = function(step)
            ii = 1 for i = 1, #(N_sub_cycles) do ii = ii + N_sub_cycles[i] if CycleCounter < (ii - 1) then NN = i break end end -- assign parameter column to active cycle
			if reset_dt_CC then t_CC_start = t end
        end,
		i = i_charge[NN],
        con = conGSTAT,
        -- range = "auto",
        diffcap_dV = cap_dV[NN],
        -- bw = "slow",
        cd ="c",
        diffcap_startdelayR = cap_delay_R[NN],
        diffcap_startdelay = cap_delay[NN],
        record = r_0,
        limits = {
            [0] = function(limit)
					if (step_t > dt_GEIS[NN] or dQ_CC() > dQ_GEIS[NN]) and (dV12_step() > dV12_CC_min[NN]) and (dV1R_step() > dV1R_CC_min[NN]) and (dV2R_step() > dV2R_CC_min[NN]) and not AlmostCharged() then
						SwitchNext()
					end
				  end,
            [1] = function(limit) if FullyCharged() then reset_dt_CC = true t_CC_end = t Qcc_cyc = Qcd_abs SwitchTo(30) end end,
            [2] = function(limit) if (t - t_CC_start) > dt_CC_max_charge[NN] then reset_dt_CC = true t_CC_end = t SwitchTo(38) end end
		}
},
[20] = { -- GEIS charge
        step_type = "GEIS",
        doPreInit = function(step) Adapt_GEIS_amplitude() end,
        i = i_charge[NN],
        con = conGSTAT,
        -- range = "auto",
        bw = "fast",
        eis_amplitude = eis_amplitude,
        geis_limit_V12_amplitude = geis_limit_V12_amplitude,
        geis_limit_V1R_amplitude = geis_limit_V1R_amplitude,
        geis_limit_V2R_amplitude = geis_limit_V2R_amplitude,
        eis_fstart = f0_GEIS[NN], 
        eis_fend = fe_GEIS[NN],
        eis_fcount_per_ordermagnitude = fcount[NN],
        -- eis_ordermagnitude = 10,
        -- eis_averages = 1,
        -- eis_precycles = 1,
        eis_record_waveform_up_to_frequency = eis_record_waveform_up_to_frequency_GEIS,
        -- eis_apply_drift_correction = 1,
        eis_sweep_back = geis_backsweep[NN],
        record = record,
        limits = {
            [0] = function(limit) if EIS_finished > 0 or FullyCharged() then reset_dt_CC = false SwitchTo(10) end end
        }
},
[30] = { -- CV at full charge
        step_type = "CV",
        v = V_fully_charged,
        con = conPSTAT,
        -- range = "auto",
        -- bw = "slow",
        record = r_0,
        limits = {
			[0] = function(limit) if t > (t_CC_end + dt_hold_charge[NN]) or (math.abs(i12) < i_limit_charge[NN]) then SwitchTo(38) end end, --> Rest (end of half cycle)
			[1] = function(limit) if step_t > dt_PEIS[NN] then SwitchNext() end end
        }
},
[35] = { -- PEIS at full charge
        step_type = "PEIS",
        doPreInit = function(step) if record_sine[NN] then record = r_sine else record = r_off end end,
        v = V_fully_charged,
        con = conPSTAT,
        -- range = "auto",
        bw = "fast",
        eis_amplitude = v_EIS[NN],
        eis_fstart = f0_PEIS[NN],
        eis_fend = fe_PEIS[NN],
        eis_fcount_per_ordermagnitude = fcount[NN],
        -- eis_ordermagnitude = 10,
        -- eis_averages = 1,
        -- eis_precycles = 1,
        eis_record_waveform_up_to_frequency = eis_record_waveform_up_to_frequency_PEIS,
        -- eis_apply_drift_correction = 1,
        eis_sweep_back = peis_backsweep[NN],
        record = record,
        limits = {
            [0] = function(limit) if EIS_finished > 0 then SwitchTo(30) end end
        }
},
[38] = { -- Rest
        step_type = "Rest",
        record = r_0,
		limits = {
            [0] = function(limit)
                  if CycleCounter <= cycle_Q0_calc and not start_with_charge then
                     Q0 = Qcd_abs
                     ec.print(SEV_INFO, "Q0 (cycle "..cycle_n..") = "..Q0.." As (cycle starts with discharge)")
					ec.SetOutputVariable("Q0", Q0)
                  end
                  if (step_t > dt_OCV_charge[NN]) then
                     CycleCounter = CycleCounter + 0.5
                     if CycleCounter >= N_tot_cycles then
                        SwitchTo(80)
                     else
                        t_CC_start = nil
						Q_CC_start = nil
                        SwitchNext()
                     end
                  end
                end
        }
},
[40] = { -- CC discharge with diffcap calculation
        step_type = "CC",
		doPreInit = function(step)
			ii = 1 for i = 1, #(N_sub_cycles) do ii = ii + N_sub_cycles[i] if CycleCounter < (ii - 1) then NN = i break end end -- assign parameter column to active cycle
			if reset_dt_CC then t_CC_start = t end
		end,		
        i = -i_disch[NN],
        con = conGSTAT,
        -- range = "auto",
        diffcap_dV = cap_dV[NN],
        -- bw = "slow",
        cd = "d",
        diffcap_startdelayR = cap_delay_R[NN],
        diffcap_startdelay = cap_delay[NN],
        record = r_0,
        limits = {
            [0] = function(limit)
					if (step_t > dt_GEIS[NN] or dQ_CC() > dQ_GEIS[NN]) and dV12_step() > dV12_CC_min[NN] and (dV1R_step() > dV1R_CC_min[NN]) and (dV2R_step() > dV2R_CC_min[NN]) and not AlmostDischarged() then
						SwitchNext()
					end
				  end,
            [1] = function(limit) if FullyDischarged() then reset_dt_CC = true t_CC_end = t Qdd_cyc = Qcd_abs SwitchTo(60) end end,
            [2] = function(limit) if (t - t_CC_start) > dt_CC_max_disch[NN] then reset_dt_CC = true t_CC_end = t SwitchTo(68) end end
        }
},
[50] = { -- GEIS discharge
        step_type = "GEIS",
        doPreInit = function(step) Adapt_GEIS_amplitude() end,
        i = -i_disch[NN],
        con = conGSTAT,
        -- range = "auto",
        bw = "fast",
        eis_amplitude = eis_amplitude,
        geis_limit_V12_amplitude = geis_limit_V12_amplitude,
        geis_limit_V1R_amplitude = geis_limit_V1R_amplitude,
        geis_limit_V2R_amplitude = geis_limit_V2R_amplitude,
        eis_fstart = f0_GEIS[NN],
        eis_fend = fe_GEIS[NN],
        eis_fcount_per_ordermagnitude = fcount[NN],
        -- eis_ordermagnitude = 10,
        -- eis_averages = 1,
        -- eis_precycles = 1,
        eis_record_waveform_up_to_frequency = eis_record_waveform_up_to_frequency_GEIS,
        -- eis_apply_drift_correction = 1,
        eis_sweep_back = geis_backsweep[NN],
        record = record,
        limits = {
            [0] = function(limit) if EIS_finished > 0 or FullyDischarged() then reset_dt_CC = false SwitchTo(40) end end
        }
},
[60] = { -- CV at full discharge
        step_type = "CV",
        v = V_fully_discharged,
        con = conPSTAT,
        -- range = "auto",
        -- bw = "slow",
        record = r_0,
        limits = {
            [0] = function(limit)
                  if t > (t_CC_end + dt_hold_disch[NN]) or (math.abs(i12) < i_limit_disch[NN]) then
                     if CycleCounter <= cycle_Q0_calc and start_with_charge then
                        Q0 = Qcd_abs
                        ec.print(SEV_INFO, "Q0 (cycle "..cycle_n..") = "..Q0.." As (cycle starts with charge)")
						ec.SetOutputVariable("Q0", Q0)
                     end
                     SwitchTo(68)
                  end
               end,
            [1] = function(limit) if step_t > dt_PEIS[NN] then SwitchNext() end end
        }
},
[65] = { -- PEIS at full discharge
        step_type = "PEIS",
        doPreInit = function(step) if record_sine[NN] then record = r_sine else record = r_off end end,
        v = V_fully_discharged,
        con = conPSTAT,
        -- range = "auto",
        bw = "fast",
        eis_amplitude = v_EIS[NN],
        eis_fstart = f0_PEIS[NN],
        eis_fend = fe_PEIS[NN],
        eis_fcount_per_ordermagnitude = fcount[NN],
        -- eis_ordermagnitude = 10,
        -- eis_averages = 1,
        -- eis_precycles = 1,
        eis_record_waveform_up_to_frequency = eis_record_waveform_up_to_frequency_PEIS,
        -- eis_apply_drift_correction = 1,
        eis_sweep_back = peis_backsweep[NN],
        record = record,
        limits = {
            [0] = function(limit) if EIS_finished > 0 then SwitchTo(60) end end
        }
},
[68] = { -- Rest
        step_type = "Rest",
        record = r_0,
        limits = {
            [0] = function(limit)
                  if (step_t > dt_OCV_disch[NN]) then
                     CycleCounter = CycleCounter + 0.5
                     if CycleCounter >= N_tot_cycles then
                        SwitchTo(70)
                     else
                        t_CC_start = nil
						Q_CC_start = nil
                        SwitchTo(10)
                     end
                  end
              end
        }
},
[70] = { -- Rest
        step_type = "Rest",
        record = r_0,
        limits = {
            [0] = function(limit) if (step_t > dt_OCV_final) then SwitchNext() end end
        }
},
[1000] = {step_type = "OFF"}
}
-- end of configuration section --

end

-------------------- Initialization ---------------------------------------------
-- This function is called only once to configure the steps,
-- initialize all global variables, and prepare the output files.
---------------------------------------------------------------------------------
function Init_StateMachine()

    -- script runtime data --
    t            = 0      -- * statemachine time since script init / Seconds
    step_n       = 0      --   statemachine step number
    step_t       = 0      -- * statemachine step time, for use as PAT-Composer limit only
    cycle_n      = 0      -- * statemachine cycle number
    cycle_t      = 0      -- * statemachine cycle time, for use as PAT-Composer limit only
    step_tstart  = 0      --   statemachine time when the step was started / Seconds
    cycle_tstart = 0      --   statemachine time when the cycle was started / Seconds
    started      = false  --   statemachine has not yet started
    finished     = false  --   statemachine is not finished
    processing   = false  --   script is not processing data
    paused       = false  --   script is not paused
    stopped      = false  --   script is not aborted
    transition_counter = 0  -- count of statemachine step transitions, for script progress
    progress_estimate = 0   -- script progress in percent, estimate, based on step_transitions_estimated
    progress_accurate = nil -- script progress in percent, is "nil" if not used (in favor of progress_estimate)
    
    -- step runtime data --
    -- Explanation of the config structures:
    -- "stepconf":  The "stepconf" structure contains the step config provided by the user.
    --              It can be overwritten by the user at any time during script execution.
    --              All math expressions are repeatedly evaluated before every step transition.
    --              The script itself shall not modify "stepconf" - all changes would be lost.
    -- "stepstate": The "stepstate" structure is private to the script. 
    --              It acts as a state memory, i.e. for loop counters.

    -- initialize new step states --
    stepstate = {}  -- create step state for non constant values 
    
end

-------------------- Start Measurement ------------------------------------------
-- Does some self-test and more Init and then starts the state machine.
---------------------------------------------------------------------------------
function StartMeasurement()

    -- load steps --
    Generate_StepConfiguration()
  
    -- count steps and add missing step tables --
    local stepcount = 0
    for n,step in pairs(stepconf) do
        stepcount = stepcount + 1
        AddMissingTables(n)
    end
    
    -- warning on use of old parameters --
    if record_maximum_dt then 
        ec.print(SEV_WARN, "Parameter 'record_maximum_dt' is obsolete, please use recording criteria parameter 't' instead")
    else
        record_maximum_dt = 3600  -- set to default if not set yet
    end
    if delta_t_min then 
        ec.print(SEV_ERR, "Parameter 'delta_t_min' is obsolete, please write 'dVdt_dt_min' instead")
        dVdt_dt_min = delta_t_min
    end
    if delta_t_max then 
        ec.print(SEV_ERR, "Parameter 'delta_t_max' is obsolete, please write 'dVdt_dt_max' instead")
        dVdt_dt_max = delta_t_max
    end
    
    -- init count of total estimated transitions, if not provided in config section --
    step_transitions_estimated = step_transitions_estimated or stepcount
    
    DebugMemoryAllocation()

    ec.SetSafetyLimits( safetylimits.V12_min,
                        safetylimits.V12_max,
                        safetylimits.i,
                        safetylimits.delay_count or 10)

    -- reset time to 0 seconds --
    ec.ResetSeconds()
    
    -- start measurement by switching to the first step --
    step_n = -1
    SwitchNext()
    
    InitSamplingStepState()
    
    started = true
    processing = true
    ec.SetScriptExecutionState("Running")
end

function AddMissingTables(n)

    -- stepconf --
    if stepconf[n].record == nil then stepconf[n].record = {V12 = 0.0001, V1R = 0.001, V2R = 0.001, i = 0.00001, t = 999999} end
    if stepconf[n].limits == nil then stepconf[n].limits = {} end
        
    -- stepstate --
    if stepstate[n]        == nil then stepstate[n] = {} end
    if stepstate[n].limits == nil then stepstate[n].limits = {[0] = {loops = 0}} end
    
end

function CheckFirmwareVersion()
    -- check channelboard firmware version --
    if ec.GetHardwareInfo then board_type, board_rev, firmw_vers = ec.GetHardwareInfo() end
    if firmw_vers == nil or firmw_vers < 129 then ec.print(0, "Please update channel firmware to >=129") end
end

function DebugMemoryAllocation()

    -- free some memory --
    Init_SampleProcessing = nil
    Init_StateMachine = nil
    
    -- do a dry run through all steps --
    --ec.print(SEV_INFO, "Starting a dry run of the script")
    --dryrun = true
    --for n,step in pairs(stepconf) do
    --    SwitchTo(n)  -- includes GC calls
    --end
    --dryrun = false
    
    -- debug print size of globals table
    --local i = 0
    --local j = 0
    --for k,v in ipairs(_G) do i = i + 1 end
    --for k,v in pairs(_G) do j = j + 1 end
    --ec.print(SEV_INFO, "Debug: Size of Lua globals table: "..i.."+"..(j-i))
    
    -- check if enough memory is left --
    -- stops execution here if memory is insufficient--
    for i = 1, 20 do _G["dummy"..i] = "dummy" end  -- allocate some string variables to trigger resize of globals table
    long_string1 = string.rep("1", 20000)          -- allocate one memory block of 20K
    long_string2 = string.rep("2", 20000)          -- allocate one memory block of 20K
    long_string1 = nil                             -- free again
    long_string2 = nil                             -- free again
    for i = 1, 20 do _G["dummy"..i] = nil end      -- free again
    collectgarbage('collect')                      -- free again
    
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
--  Called from a function that's defined in stepconf config block,
--  this function counts the loops of a step limit.
---------------------------------------------------------------------------------
function IncLoops(limit)
    limit.loops = limit.loops + 1
end

------------------------- Switch To Next Step -----------------------------------
--  Switches to the next step.
--  This function is usually called when a limit has been exceeded.
---------------------------------------------------------------------------------
function SwitchNext()
    for next_step_n = step_n + 1, 1000 do   -- look for next step
        if stepconf[next_step_n] then
            SwitchTo(next_step_n)
            return
        end
    end
    -- if no next step exists
    SwitchTo(step_n + 1)
end

------------------------- Switch To Step n --------------------------------------
--  Switches to the step number specified in the argument.
--  This function is usually called when a limit has been exceeded.
---------------------------------------------------------------------------------
function SwitchTo(...)

    if type(...) ~= 'table' then
        n_newstep = assert(...)
    else
        local t = ...  -- table pointer
        n_newstep = assert(t[1])
    end
    
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
        ec.print(SEV_INFO, "Step does not exist. Switching OFF.")
        stepconf[n_newstep] = {}  -- create new step "OFF"
        stepconf[n_newstep].step_type = "OFF"
    end
    
    -- copy parameter list into new step configuration --
    if type(...) == 'table' then
        local t = ...  -- table pointer
        t[1] = nil     -- delete step number
        for parameter, value in pairs(t) do
            ec.print(SEV_INFO, "... overwriting parameter: "..parameter.." = "..value)
            stepconf[n_newstep][parameter] = value
        end
    end
    
    AddMissingTables(n_newstep)

    -- apply step configuration to PGStat hardware
    ApplyStepConfig(n_newstep, false)
    
    -- remember step start time --
    step_tstart = ec.GetSeconds()

    step_n = n_newstep
    
    ------ cycle autodetection ------
    cds_user = stepconf[n_newstep].cycle_start or "auto" -- cycle starts with charge "c" or discharge "d"
    cd_user  = stepconf[n_newstep].cd          or "auto" -- cycle is charge "c" or discharge "d"
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
    if((step_cds == "c" and cycle_n == 0 and step_cd == "c")                       -- start of first c-d  cycle
    or (step_cds == "d" and cycle_n == 0 and step_cd == "d")                       -- start of first d-c cycle
    or (step_cds == "c" and cd_prev_step == "d" and step_cd ~= cd_prev_step)       -- start of successive c-d cycle
    or (step_cds == "d" and cd_prev_step == "c" and step_cd ~= cd_prev_step)) then -- start of successive d-c cycle
        -- update statemachine cycle state
        cycle_n = cycle_n + 1
        cycle_tstart = step_tstart
        ec.print(SEV_INFO, "Cycle "..cycle_n.." start")
    end
    
    -- output script progress --
    AddProgressEstimate()
    ec.SetScriptProgress(cycle_n, step_n, progress_accurate or progress_estimate)
    
    -- if step has special activities, start them here --
    if step_type == "VS" then 
        ec.WaveGenRamp(step_v_ctrl, step_slope)
    elseif step_type == "PEIS" or step_type == "GEIS" then
        StartEIS()
    elseif step_type == "OFF" and #(stepconf[n_newstep].limits) == 0 then 
        -- if OFF step has no limits, then statemachine is finished --
        ec.print(SEV_INFO, "Script finished")
        finished = true  
        -- state machine has finished, but processing continues
        -- until all remaining samples are processed and the last cycle data is output
    end
    
    -- debug channelboard heap memory allocation --
    collectgarbage('collect')
    local heap_allocation = collectgarbage('count')
    if heap_allocation > 200 then
        ec.print(SEV_INFO, string.format("%1.0f KB of RAM used", heap_allocation))
    end
end

function ApplyStepConfig(n, is_edit_on_the_fly)

    -- get step parameters
    step_type         = stepconf[n].step_type    or "Rest"
    step_con          = stepconf[n].con          or "1vs2"
    step_range        = stepconf[n].range        or "auto"
    step_bw           = stepconf[n].bw           or "slow"
    step_slope               = stepconf[n].slope        or 0
    step_diffcap_dV          = stepconf[n].diffcap_dV          or 0.001
    step_diffcap_startdelayR = stepconf[n].diffcap_startdelayR or 5
    step_diffcap_startdelay  = stepconf[n].diffcap_startdelay  or 5
    
    -- create defaults for v and i (last measured values) --
    local v_last_step
    local i_last_step
    if (step_con == "1vsR") then
        v_last_step = V1R_last_step
        i_last_step = i12_last_step
    elseif (step_con == "2vsR") then
        v_last_step = V2R_last_step
        i_last_step = i12_last_step
    elseif (step_con == "Rvs1") then
        v_last_step = V1R_last_step
        i_last_step = i1R_last_step
    elseif (step_con == "Rvs2") then
        v_last_step = V2R_last_step
        i_last_step = i2R_last_step
    else
        v_last_step = V12_last_step
        i_last_step = i12_last_step
    end
    step_v_ctrl = stepconf[n].v or (v_last_step or nil)
    step_i_ctrl = stepconf[n].i or (i_last_step or 0)
    
    -- configure step type and connection --
    cd_guess = nil
    if step_type == "OFF" then
        step_pg = "-"
        step_con = "OFF"
        
    elseif step_type == "Rest" or step_type == "OCV" then  -- open circuit voltage
        step_pg = "-"
        step_con = "Rest"
        
    elseif step_type == "CC" then
        step_pg = "g"
        ec.SetConstCurrent(step_i_ctrl)  -- current in Amps, not Milliamps
        if step_i_ctrl > 0 then cd_guess = "c" end
        if step_i_ctrl < 0 then cd_guess = "d" end
        
    elseif step_type == "CV" then 
        step_pg = "p"
        ec.SetConstVoltage(step_v_ctrl)
        
    elseif step_type == "GEIS" then 
        step_pg = "g"
        ec.SetConstCurrent(step_i_ctrl)
        if step_i_ctrl > 0 then cd_guess = "c" end
        if step_i_ctrl < 0 then cd_guess = "d" end
        
    elseif step_type == "PEIS" then 
        step_pg = "p"
        ec.SetConstVoltage(step_v_ctrl)
        
    elseif step_type == "VS" then 
        step_pg = "p"
        ec.SetConstVoltage(step_v_ctrl)
        if step_slope > 0 then cd_guess = "c" end
        if step_slope < 0 then cd_guess = "d" end
        
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
    ec.ADC_RecDelta(stepconf[n].record.V12   or 0.0001, 
                    stepconf[n].record.V1R   or 0.001, 
                    stepconf[n].record.V2R   or 0.001, 
                    stepconf[n].record.i     or 0.00001, 
                    stepconf[n].record.t     or 600)
	ec.RequestTemperature(stepconf[n].temperatureRequest)
    
    -- apply the new hardware configuration now (switch matrix and PStat/GStat into new state) --
    if is_edit_on_the_fly then
        if step_type == "CC" or step_type == "CV" then
            ec.SwitchNow()  -- apply pending changes
            ec.print(SEV_INFO, "Edit-on-the-fly: PGStat changes applied")
        else
            ec.print(SEV_INFO, "Edit-on-the-fly: PGStat changes are ignored during Rest/EIS/VS")
        end
        ec.SetSafetyLimits( safetylimits.V12_min,
                            safetylimits.V12_max,
                            safetylimits.i,
                            safetylimits.delay_count or 10)
        ec.print(SEV_INFO, "Edit-on-the-fly: Modified script applied")
    else
        ec.print(SEV_INFO, string.format("SwitchTo(%1.0f): %s (triggered at %1.3fs - switching at %1.3fs)", n_newstep, step_type, sample_t, ec.GetSeconds()))
        sample_step_tlast = ec.SwitchNow()   -- Firmware returns timestamp of last acquired A/D-sample before switching.
                                             -- At the time of switching, this sample resides in the A/D-sample-queue.
    end
end

----------------------------- Init EIS ------------------------------------------
-- Initialize the PEIS/GEIS Step and start the spectrum scan
---------------------------------------------------------------------------------
function StartEIS()

    ec.EIS_Spectrum(stepconf[step_n].eis_amplitude, 
                    stepconf[step_n].eis_fstart                          or 100000,
                    stepconf[step_n].eis_fend                            or 1 ,
                    stepconf[step_n].eis_fcount_per_ordermagnitude       or 3 , 
                    stepconf[step_n].eis_ordermagnitude                  or 10, 
                    stepconf[step_n].eis_averages                        or 1 ,
                    stepconf[step_n].eis_precycles                       or 1 ,
                    stepconf[step_n].eis_record_waveform_up_to_frequency or 1 ,
                    stepconf[step_n].eis_apply_drift_correction          or 1 ,
                    stepconf[step_n].geis_limit_V12_amplitude            or 0 ,
                    stepconf[step_n].geis_limit_V1R_amplitude            or 0 ,
                    stepconf[step_n].geis_limit_V2R_amplitude            or 0 ,
                    stepconf[step_n].peis_limit_i_amplitude              or 0 ,
                    stepconf[step_n].eis_sweep_back                      or 0 ,
                    stepconf[step_n].eis_measure_Z_AUX                   or 0 )
end

--------------------------- Add Progress ----------------------------------------
-- Adds script progress, in percent.
-- Can be called from step limit functions. 
-- Gives more accurate script progress than AddProgressEstimate()
---------------------------------------------------------------------------------
function AddProgress(val)
    if progress_accurate == nil then 
        progress_accurate = 0   -- init variable. now "progress" has higher priority than "progress_estimate"
    end
    progress_accurate = progress_accurate + val
end

--------------------------- Add Progress Estimate -------------------------------
-- Adds Script Progress automatically, based on an estimation of total step transitions.
-- The variable step_transitions_estimated can be specified in the config section.
---------------------------------------------------------------------------------
function AddProgressEstimate()
    transition_counter = transition_counter + 1
    --ec.print(SEV_INFO, "Step transition counter: "..transition_counter)

    if transition_counter >= step_transitions_estimated then
        step_transitions_estimated = transition_counter + 1
        --ec.print(SEV_INFO, "Step total transitions estimate increased: "..step_transitions_estimated)
    end

    progress_estimate = transition_counter / step_transitions_estimated * 100
    --ec.print(SEV_INFO, "Progress estimate: "..progress_estimate.." %")
end

-------------------- Pause and Resume -------------------------------------------
--  Switch cell connection to 'Rest' or resume from there.
---------------------------------------------------------------------------------
function Pause()       
    if not paused and not stopped and not finished then
        ec.SetCon("Rest")
        ec.SwitchNow()
        paused = true
        ec.SetScriptExecutionState("Paused")
    end
end

function Resume()
    if paused and not stopped and not finished then
        ec.SetCon(stepconf[step_n].con)
        ec.SwitchNow()
        paused = false
        ec.SetScriptExecutionState("Resumed")
    end
end




--#############################################################################--
--##                                                                         ##--
--##       P A R T  2 :   A / D   S A M P L E   P R O C E S S I N G          ##--
--##                                                                         ##--
--#############################################################################--

---------------------------------------------------------------------------------
function Init_SampleProcessing()

    -- some constants
    MAX = math.huge       -- highest positive number 
    MIN = math.huge * -1  -- lowest negative number
    NaN = 0/0  -- "Not a Number": Output value 'nan', will not be plotted in diagrams.
    
    -- All variables must be initialized (set to some value) before they can be used:
    -- 1) Initialize variables to NaN if their value is unknown yet and may stay unknown in output data.
    --                                A NaN value will not be plotted in diagrams (neither point nor line).
    -- 2) Initialize variables to nil which means 'not initialized', if the variables must get initialized
    --                                later on and can cause unnoticed damage if accidently used with wrong 
    --                                initial value. The script will then abort with an error immediately.
    -- 3) Initialize variables to 0   if their value always starts from zero (i.e. charge).
    -- 4) Initialize variables to MAX if you want the highest possible value (i.e. infinite time span)
    -- 5) Initialize variables to MIN if you want the most negative value.   (i.e. time in very past)
   

    -------- GLOBAL VARIABLES --------
    
    -- A star * comment means that this variable is selectable in EL-Composer limits.
    
    -- SAMPLE DATA --
    -- A/D-converter measured data:
    V12              = NaN   -- * sample voltage full cell   / Volt
    V1R              = NaN   -- * sample voltage half cell 1 / Volt
    V2R              = NaN   -- * sample voltage half cell 2 / Volt
    i                = NaN   -- * sample current             / Ampere
    Vaux             = NaN   -- * sample auxiliary voltage   / Volt
    sample_t         = NaN   --   sample time, counted since script start (seconds with microsecond-resolution)
    sample_over      = NaN   --   sample overrange warning (string "i", "v" or "iv")
    sample_i_range   = NaN   --   PGStat current range (1="100mA", 2="10mA", 3="1mA", 4="0.1mA")
    -- derived data:
    i12              = NaN   -- * current between electrode 1 and 2
    i1R              = NaN   -- * current between electrode 1 and R
    i2R              = NaN   -- * current between electrode 2 and R
    P                = NaN   -- * power (in any electrode configuration)
    -- accumulated charge, per step:
    Qstep            = 0     --   step charge
    Qstep_abs        = 0     -- * step charge, absolute value (always positive)
    -- accumulated charge and energy, per cycle:
    Qcd              = 0     -- * cycle charge
    Qcd_abs          = 0     -- * cycle charge absolute value (always positive), often called "capacity"
    Qc               = 0     -- * cycle charged charge,    always positive
    Wc               = 0     -- * cycle charged energy,    always positive
    Qd               = 0     -- * cycle discharged charge, always positive
    Wd               = 0     -- * cycle discharged energy, always positive
    EffQ             = NaN   -- * Qd / Qc   
    EffW             = NaN   -- * Wd / Wc   
	Qcc_cyc          = 0     -- * Qc at end of CC charge
	Qdd_cyc          = 0     -- * Qd at end of CC discharge												 
    -- accumulated charge and energy, total:
    Q12              = 0     --   total charge flown between electrodes 1 and 2
    Q1R              = 0     --   total charge flown between electrodes 1 and R 
    Q2R              = 0     --   total charge flown between electrodes 2 and R 
    Q1               = 0     -- * total charge on electrode 1 
    Q2               = 0     -- * total charge on electrode 2 
    QR               = 0     -- * total charge on electrode R 
    W12              = 0     -- * total energy flown between electrodes 1 and 2
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
    i12_last_step    = 0     --   last measured i12 from step, can be used to init next step
    i1R_last_step    = 0     --   last measured i1R from step, can be used to init next step
    i2R_last_step    = 0     --   last measured i2R from step, can be used to init next step
    -- lowpass filter --
    V12_avg          = NaN   --   voltage average over i.e. one second
    V1R_avg          = NaN   --   voltage average over i.e. one second
    V2R_avg          = NaN   --   voltage average over i.e. one second
    avg_counter      = 0     --   average filter sample counter
    -- voltage slope |dV/dt| --
    dV12_dt_abs      = NaN   -- * |dV12/dt|
    dV1R_dt_abs      = NaN   -- * |dV1R/dt|
    dV2R_dt_abs      = NaN   -- * |dV2R/dt|
    dVdt_dt_min      = 1     --   minimum time interval dt used to calculate slope dV/dt, in seconds
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
    EIS_i_range      = NaN   --   PGStat current range
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
    sample_t_prev         = 0    --   sample time of previous sample (for calculation of dt)
    sample_t_prev_display = MIN  --   sample time of previous displayed sample (live plot update rate)
    sample_t_prev_record  = MIN  --   sample time of previous recorded sample (saved to Output.txt) (becomes obsolete in 2023, do not use)
    sample_t_prev_rec_sen = MIN  --   sample time of previous recorded sample (saved to Output-Sensordata.txt)
    sample_t_prev_diffcap = MIN  --   sample time of previous differential-capacity calculation (to print 1 sps maximum)
    sample_step_tstart    = NaN  --   sample time of the first sample of the step
    sample_step_tlast     = NaN  --   sample time of the last sample of the step
    sample_cycle_tstart   = NaN  --   sample time of the first sample of the cycle
    sample_step_t         = NaN  --   sample time in step
    sample_cycle_t        = NaN  --   sample time in cycle
    -- step config:
    sample_step_n         = NaN  --   sample step number
    sample_cycle_n        = NaN  --   sample cycle number
    sample_step_type      = ""   --   step type can be: "OFF", "Rest", "CC", "CV", "VS", "PEIS", "GEIS", ... 
    sample_step_pg        = ""   --   potentiostat "p" or galvanostat "g"
    sample_cds            = ""   --   cycle starts with charge "c" or discharge "d" (this defines the begin of the first cycle)
    sample_cd             = ""   --   step is charge "c" or discharge "d" (user-defined or auto-detected, used for cycle increments)
    sample_step_con       = ""   --   electrode connection (also called switch matrix), i.e. "1vs2", "1vsR", ...
    sample_step_dV        = nil  --   differential capacity: definition of the smallest dV that allows calculation of "dQ/dV" with good SNR
    -- reduction algorithm:
    sample_rec            = false--   flag: record a sample (true) or do not record the sample (false) to Output.txt
    sample_buf            = NaN  --   buffer fill level of A/D sample buffer stream (in Output.txt, for debugging only)
    display_maximum_dt    = 1    --   Display Rate: Show at least one live sample every N seconds in EL-Software cell graphs ("Live View" feature)
    record_sensor_dt      = 60   --   Recording Rate: Save at least one sample of sensor data every N seconds (to Output-Sensordata.txt)

    -- some constants --
    SEV_ERR     = 0          --   info message severity:  E R R O R
    SEV_WARN    = 1          --   info message severity:  W A R N I N G
    SEV_INFO    = 2          --   info message severity:  I N F O
    
    -- init output files --

    -- placeholder for NewSample and NewEISData argument table --
    arg     = string.rep(" ", 500)   -- NewSample() arguments
    imp_arg = string.rep(" ", 2000)  -- NewEISData() arguments

    -- create tables for output file rows --
    tim_data = {}  -- time based data
    sen_data = {}  -- time based sensor data (with constant interval)
    C12_data = {}  -- differential capacity data
    C1R_data = {}  -- differential capacity data
    C2R_data = {}  -- differential capacity data
    C1_data  = {}  -- differential capacity data
    C2_data  = {}  -- differential capacity data
    CR_data  = {}  -- differential capacity data
    cyc_data = {}  -- per cycle data
    imp_data = {}  -- impedance data

    -- send file column headers to EL-Software --
    local header = true
    PrintOutput(header)
    PrintOutputSensordata(header)
    PrintOutputCycles(header)
    PrintOutputImpedance(header)
    PrintOutputC12(header)
    PrintOutputC1R(header)
    PrintOutputC2R(header)
    PrintOutputC1(header)
    PrintOutputC2(header)    
    PrintOutputCR(header)

end


------------------ New Sample (function called by firmware) ---------------------
--  * Sample processing starts here - this is the entry point of sample processing.
--  * The channel firmware calls this routine 1042 times per second to pass measurement
--    data from the A/D-converter sample buffer to this script. 
--    The flag "sample_rec" is a boolean variable that flags only some of the samples 
--    to be worth saving (recording) in Output.txt.
--    The flag is set by firmare, based upon the recording criteria from this script.
--    It is not possible to save all samples to Output.txt, but all 1042 samples 
--    per second will be fully processed here in this script.
--  * To achieve this high throughput, the A/D-samples are buffered in a firmware queue (buffer).
--    As a consequence, the processing of the A/D-samples is not always synchronous to 
--    the state of the "state machine" (see "Part I" above). 
--    In effect, "Part II" of this script (Sample Processing) always lags behind
--    "Part I" of this script (State Machine) by a few milliseconds. 
--    "Part II" should be treated like a seperate "thread". The two "threads" can be in 
--    different step states: "statemachine step state" and "sample processing step state".
--    The script "Part II" checks the time stamps of the arriving samples:
--    As soon as the last sample of a step has been processed, "Part II" transitions to 
--    the next step state.
--    (See variables sample_t, sample_step_tlast, sample_step_n, and sample_cycle_n)
---------------------------------------------------------------------------------
function NewSample(...)

    if started and processing and not paused then
        
        arg = {...}  -- argument array

        sample_t       = arg[1]
        V12            = arg[2]
        V1R            = arg[3]
        V2R            = arg[4]
        i              = arg[5]
        Vaux           = arg[6]
        sample_over    = arg[9]    -- string
        sample_i_range = arg[10]   -- integer
        sample_rec     = arg[11]   -- boolean flag: record this sample
        sample_buf     = arg[12]   -- integer
        
        -- call subroutines to process the sample --
        
        -- do calculations on sample data
        CalculateSampleValues()
        
        -- execute user calculations and code
        if stepconf[sample_step_n].doPerSample then stepconf[sample_step_n].doPerSample(sample_step_n) end
        
        -- execute limit functions (run the state machine)
        CheckLimits()

        -- check if dV is sufficient to calculate differential capacity
        DiffCap()

        -- record sample if...
        sample_rec = 
               sample_rec   -- if internal reduction algorithm has flagged the sample as "important", based on the record criteria
            or ((sample_t - sample_t_prev_record) > record_maximum_dt)  -- if delta-t has become too long (this becomes obsolete in 2023, please use record criteria parameter "t")
            or IsFirstSampleOfStep() 
            or IsLastSampleOfStep() 

        -- output sample for recording to Output.txt file AND for live display
        if sample_rec then
            sample_t_prev_record = sample_t
            sample_t_prev_display = sample_t
            PrintOutput()
        -- output sample for for live display only
        elseif ((sample_t - sample_t_prev_display) > display_maximum_dt) then
            sample_t_prev_display = sample_t
            PrintOutput() 
        end
        -- record sensordata --
        if (sample_t - sample_t_prev_rec_sen) > record_sensor_dt then
            sample_t_prev_rec_sen = sample_t
            PrintOutputSensordata()
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
    local x = next_sample_is_first_sample_of_step
    next_sample_is_first_sample_of_step = false
    return x
end

-------------------- Init Sampling Step State -----------------------------------
-- Updates the sample state.
-- Since the processing of the A/D-samples lags behind of the state of the
-- state machine, the correct state that belongs to the A/D-samples is set here.
---------------------------------------------------------------------------------
function InitSamplingStepState()

    -- update sample step state
    sample_step_n       = step_n
    sample_step_tstart  = step_tstart    -- time of PGStat switching via ec.SwitchNow()
    sample_cycle_tstart = cycle_tstart   -- time of PGStat switching via ec.SwitchNow()
    sample_step_type    = step_type        or "-"
    sample_step_pg      = step_pg          or "-"
    sample_step_con     = step_con         or "-"
    sample_step_dV      = step_diffcap_dV  or 0.001
    sample_cds          = step_cds         or "-"
    sample_cd           = step_cd          or "-"
    sample_cycle_n      = cycle_n
    
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
    if sample_step_con == "1vs2" or 
       sample_step_con == "1vsR" or 
       sample_step_con == "2vsR" then
       
        i12 = i
        i1R = 0
        i2R = 0
        P   = V12 * i   -- P12
        dW  = P   * dt
        Q12 = Q12 + dQ
        W12 = W12 + dW
        
    elseif sample_step_con == "Rvs1" then
        i12 = 0
        i1R = i
        i2R = 0
        P   = V1R * i   -- P1R
        dW  = P   * dt  -- for half cell energy efficiency "Eff_W" only
        Q1R = Q1R + dQ
        
    elseif sample_step_con == "Rvs2" then
        i12 = 0
        i1R = 0
        i2R = i
        P   = V2R * i   -- P2R
        dW  = P   * dt  -- for half cell energy efficiency "Eff_W" only
        Q2R = Q2R + dQ
        
    else -- Rest
        i12 = 0
        i1R = 0
        i2R = 0
        P   = 0
        dW  = 0
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
-- Used for i.e. Differential Capacity.
---------------------------------------------------------------------------------
function LowpassFilter()

    -- 1000 milliseconds filter time constant
    
    if avg_counter < 1000 then avg_counter = avg_counter + 1 end
    
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
function DiffCap_1vsX_Init()
    last_V_C12 = V12_avg   last_V_C1 = V1R_avg   last_V_C2 = V2R_avg
    last_Q_C12 = Q12       last_Q_C1 = Q1        last_Q_C2 = Q2
    diffcap_1vsX_inited = true
end
function DiffCap_Rvs1_Init()
    last_V_C1R = V1R_avg   last_V_C1 = V12_avg   last_V_CR = V2R_avg
    last_Q_C1R = Q1R       last_Q_C1 = Q1        last_Q_CR = QR
    diffcap_Rvs1_inited = true
end
function DiffCap_Rvs2_Init()
    last_V_C2R = V2R_avg   last_V_C2 = V12_avg   last_V_CR = V1R_avg
    last_Q_C2R = Q2R       last_Q_C2 = Q2        last_Q_CR = QR
    diffcap_Rvs2_inited = true
end

---------- Check if dV has become large enough to calculate dQ/|dV| -------------
function DiffCap()

    if  (sample_step_dV)  -- check if variable is defined
    and (sample_step_type == "CC" or sample_step_type == "VS") then  -- diff cap makes no sense when in "CV" modes and is skipped during GEIS
    
        if sample_step_t < step_diffcap_startdelayR then 
        
            -- reset variables if diffcap_startdelayR is larger than zero
            -- and keep variables in reset for diffcap_startdelayR seconds
            if (sample_step_con == "1vs2"
             or sample_step_con == "1vsR"
             or sample_step_con == "2vsR") then  -- current is i12
                DiffCap_1vsX_Init()
                diffcap_Rvs1_inited = false
                diffcap_Rvs2_inited = false
            elseif (sample_step_con == "Rvs1") then  -- current is i1R
                diffcap_1vsX_inited = false
                DiffCap_Rvs1_Init()
                diffcap_Rvs2_inited = false
            elseif (sample_step_con == "Rvs2") then  -- current is i2R
                diffcap_1vsX_inited = false
                diffcap_Rvs1_inited = false
                DiffCap_Rvs2_Init()
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

    if (sample_step_con == "1vs2"
     or sample_step_con == "1vsR"
     or sample_step_con == "2vsR") then  -- current i12
        if not diffcap_1vsX_inited then DiffCap_1vsX_Init() end
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
        
    elseif (sample_step_con == "Rvs1") then  -- current i1R
        if not diffcap_Rvs1_inited then DiffCap_Rvs1_Init() end
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
        
    elseif (sample_step_con == "Rvs2") then  -- current i2R
        if not diffcap_Rvs2_inited then DiffCap_Rvs2_Init() end
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

    -- print cycle data to file --
    PrintOutputCycles()
    
    -- do a check on electrode charge: Q1+Q2+QR = 0 ? --
    if math.abs(Q1 + Q2 + QR) > 0.00001 then
        ec.print(SEV_WARN, "Q1+Q2+QR does not equal zero.")
    end
end

function InitNewCycle()
    
    Qc = 0  -- null charge
    Qd = 0  -- null charge
    Wc = 0  -- null energy
    Wd = 0  -- null energy
    
    if not finished then ec.print(SEV_INFO, "Cycle "..cycle_n.." is processing") end
end

----------------- New EIS Data (function called by firmware) --------------------
-- The channel firmware calls this routine after every single EIS frequency measurement.
-- See above for variable definitions
---------------------------------------------------------------------------------
function NewEISData_V2(...)

    imp_arg = {...}   -- argument is an array of impedance data numbers (61 arguments * 16 bytes = 976 bytes)
        
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
--##               P A R T  3 :   O U T P U T   F I L E S                    ##--
--##                                                                         ##--
--#############################################################################--

-------------------------- Send Output.txt Data ---------------------------------
--  Plotted as y over x=time, with variable time interval (see reduction algorithm).
--  Sends a complete sample to EL-Software-Server.
--  If the parameter "header" is true, then this function will only print the header.
---------------------------------------------------------------------------------
function PrintOutput(header)
    local file = "Output.txt"
    local rec = sample_rec
    if header then
        -- send CSV-file-header in JSON format --
        ec.Write_CSV_Header(file, [[
        {"Name": "t"      , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "t_cycle", "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "t_step" , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "over"   , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "cycle"  , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "step"   , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "type"   , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "p/g"    , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "c/d"    , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "con"    , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "I-Range", "Unit": ""    , "FieldType" : "integer" },
        {"Name": "V12"    , "Unit": "V"   , "FieldType" : "decimal" },
        {"Name": "V1R"    , "Unit": "V"   , "FieldType" : "decimal" },
        {"Name": "V2R"    , "Unit": "V"   , "FieldType" : "decimal" },
        {"Name": "I12"    , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "I1R"    , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "I2R"    , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "|Qstep|", "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Qcd"    , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "|Qcd|"  , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Qc"     , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Qd"     , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Q1"     , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Q2"     , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "QR"     , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "P"      , "Unit": "mW"  , "FieldType" : "decimal" },
        {"Name": "W12"    , "Unit": "mWh" , "FieldType" : "decimal" },
        {"Name": "Vaux"   , "Unit": "V"   , "FieldType" : "decimal" },
        {"Name": "T_cell" , "Unit": "degC", "FieldType" : "decimal" },
        {"Name": "Pressure","Unit": "mbar", "FieldType" : "decimal" },
        {"Name": "Dilation","Unit": "um"  , "FieldType" : "decimal" },
        {"Name": "Force"  , "Unit": "N"   , "FieldType" : "decimal" },
        {"Name": "buf"    , "Unit": ""    , "FieldType" : "integer" }]])
    end

    tim_data[1]  = sample_t
    tim_data[2]  = sample_cycle_t
    tim_data[3]  = sample_step_t
    tim_data[4]  = sample_over
    tim_data[5]  = sample_cycle_n
    tim_data[6]  = sample_step_n
    tim_data[7]  = sample_step_type
    tim_data[8]  = sample_step_pg
    tim_data[9]  = sample_cd
    tim_data[10] = sample_step_con
    tim_data[11] = sample_i_range
    tim_data[12] = V12
    tim_data[13] = V1R
    tim_data[14] = V2R
    tim_data[15] = i12 * 1000
    tim_data[16] = i1R * 1000
    tim_data[17] = i2R * 1000
    tim_data[18] = Qstep_abs / 3.6
    tim_data[19] = Qcd       / 3.6
    tim_data[20] = Qcd_abs   / 3.6
    tim_data[21] = Qc  / 3.6
    tim_data[22] = Qd  / 3.6
    tim_data[23] = Q1  / 3.6
    tim_data[24] = Q2  / 3.6
    tim_data[25] = QR  / 3.6
    tim_data[26] = P   * 1000
    tim_data[27] = W12 / 3.6
    tim_data[28] = Vaux
    tim_data[29] = T_cell
    tim_data[30] = Pressure * 1000
    tim_data[31] = Dilation * 1000000
    tim_data[32] = Force
    tim_data[33] = sample_buf

    tim_data_row = table.concat(tim_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, tim_data_row)
    end
end

-------------------- Send Output-Sensordata.txt Data ----------------------------
--  Plotted as y over x=time, with constant time interval (unlike Output.txt).
--  This is sent once every N seconds, independent from the reduction algorithm.
--  If the parameter "header" is true, then this function will only print the header.
---------------------------------------------------------------------------------
function PrintOutputSensordata(header)
    local file = "Output-Sensordata.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"      , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "t_cycle", "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "t_step" , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "T_set"    , "Unit": "degC", "FieldType" : "decimal" },
        {"Name": "T_chamber", "Unit": "degC", "FieldType" : "decimal" },
        {"Name": "T_cell"   , "Unit": "degC", "FieldType" : "decimal" },
        {"Name": "T_press"  , "Unit": "degC", "FieldType" : "decimal" },
        {"Name": "Pressure" , "Unit": "mbar", "FieldType" : "decimal" },
        {"Name": "Dilation" , "Unit": "um"  , "FieldType" : "decimal" },
        {"Name": "Force"    , "Unit": "N"   , "FieldType" : "decimal" },
        {"Name": "T_board"  , "Unit": "degC", "FieldType" : "decimal" },
        {"Name": "T_ambient", "Unit": "degC", "FieldType" : "decimal" }]])
    end
    sen_data[1]  = sample_t
    sen_data[2]  = sample_cycle_t
    sen_data[3]  = sample_step_t
    sen_data[4]  = T_set
    sen_data[5]  = T_chamber
    sen_data[6]  = T_cell
    sen_data[7]  = T_press  -- temperature of pressure sensor
    sen_data[8]  = Pressure * 1000
    sen_data[9]  = Dilation * 1000000
    sen_data[10] = Force
    sen_data[11] = T_board
    sen_data[12] = T_ambient
    
    sensor_data_row = table.concat(sen_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, sensor_data_row)
    end
end

-------------------- Send Differential Capacity Data ----------------------------
--  Plotted as y = C12 over x = V12
--  If the parameter "header" is true, then this function will only print the header.
---------------------------------------------------------------------------------
function PrintOutputC12(header)
    local file = "Output-C12.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"          , "Unit": "s"    , "FieldType" : "timespan"},
        {"Name": "cycle"      , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "step"       , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "V12"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "dQ12"       , "Unit": "uAh"  , "FieldType" : "decimal" },
        {"Name": "C12"        , "Unit": "mAh/V", "FieldType" : "decimal" }]])
    end
    C12_data[1] = sample_t
    C12_data[2] = sample_cycle_n
    C12_data[3] = sample_step_n
    C12_data[4] = V12_avg
    C12_data[5] = dQ_C12 / 0.0036
    C12_data[6] = C12    / 3.6

    C12_data_row = table.concat(C12_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, C12_data_row)
    end
end
function PrintOutputC1R(header)
    local file = "Output-C1R.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"          , "Unit": "s"    , "FieldType" : "timespan"},
        {"Name": "cycle"      , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "step"       , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "V1R"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "dQ1R"       , "Unit": "uAh"  , "FieldType" : "decimal" },
        {"Name": "C1R"        , "Unit": "mAh/V", "FieldType" : "decimal" }]])
    end
    C1R_data[1] = sample_t
    C1R_data[2] = sample_cycle_n
    C1R_data[3] = sample_step_n
    C1R_data[4] = V1R_avg
    C1R_data[5] = dQ_C1R / 0.0036
    C1R_data[6] = C1R     / 3.6

    C1R_data_row = table.concat(C1R_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, C1R_data_row)
    end
    
end
function PrintOutputC2R(header)
    local file = "Output-C2R.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"          , "Unit": "s"    , "FieldType" : "timespan"},
        {"Name": "cycle"      , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "step"       , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "V2R"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "dQ2R"       , "Unit": "uAh"  , "FieldType" : "decimal" },
        {"Name": "C2R"        , "Unit": "mAh/V", "FieldType" : "decimal" }]])
    end
    C2R_data[1] = sample_t
    C2R_data[2] = sample_cycle_n
    C2R_data[3] = sample_step_n
    C2R_data[4] = V2R_avg
    C2R_data[5] = dQ_C2R / 0.0036
    C2R_data[6] = C2R    / 3.6
            
    C2R_data_row = table.concat(C2R_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, C2R_data_row)
    end
end
function PrintOutputC1(header)
    local file = "Output-C1.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"          , "Unit": "s"    , "FieldType" : "timespan"},
        {"Name": "cycle"      , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "step"       , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "V12"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "V1R"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "dQ1"        , "Unit": "uAh"  , "FieldType" : "decimal" },
        {"Name": "C1"         , "Unit": "mAh/V", "FieldType" : "decimal" }]])
    end
    C1_data[1] = sample_t
    C1_data[2] = sample_cycle_n
    C1_data[3] = sample_step_n
    C1_data[4] = V12_avg
    C1_data[5] = V1R_avg
    C1_data[6] = dQ_C1 / 0.0036
    C1_data[7] = C1    / 3.6

    C1_data_row = table.concat(C1_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, C1_data_row)
    end
    
end
function PrintOutputC2(header)
    local file = "Output-C2.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"          , "Unit": "s"    , "FieldType" : "timespan"},
        {"Name": "cycle"      , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "step"       , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "V12"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "V2R"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "dQ2"        , "Unit": "uAh"  , "FieldType" : "decimal" },
        {"Name": "C2"         , "Unit": "mAh/V", "FieldType" : "decimal" }]])
    end
    C2_data[1] = sample_t
    C2_data[2] = sample_cycle_n
    C2_data[3] = sample_step_n
    C2_data[4] = V12_avg
    C2_data[5] = V2R_avg
    C2_data[6] = dQ_C2 / 0.0036
    C2_data[7] = C2    / 3.6
            
    C2_data_row = table.concat(C2_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, C2_data_row)
    end
end
function PrintOutputCR(header)
    local file = "Output-CR.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"          , "Unit": "s"    , "FieldType" : "timespan"},
        {"Name": "cycle"      , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "step"       , "Unit": ""     , "FieldType" : "integer" },
        {"Name": "V1R"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "V2R"        , "Unit": "V"    , "FieldType" : "decimal" },
        {"Name": "dQR"        , "Unit": "uAh"  , "FieldType" : "decimal" },
        {"Name": "CR"         , "Unit": "mAh/V", "FieldType" : "decimal" }]])
    end
    CR_data[1] = sample_t
    CR_data[2] = sample_cycle_n
    CR_data[3] = sample_step_n
    CR_data[4] = V1R_avg
    CR_data[5] = V2R_avg
    CR_data[6] = dQ_CR / 0.0036
    CR_data[7] = CR    / 3.6
            
    CR_data_row = table.concat(CR_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, CR_data_row)
    end
end

----------------------- Send Output-Cycles.txt Data -----------------------------
--  Plotted as y over x = cycle number
--  If the parameter "header" is true, then this function will only print the header.
---------------------------------------------------------------------------------
function PrintOutputCycles(header)
    local file = "Output-Cycles.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "t"         , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "t_start"   , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "t_duration", "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "cycle"     , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "Qc_cyc"    , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Qd_cyc"    , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Wc_cyc"    , "Unit": "mWh" , "FieldType" : "decimal" },
        {"Name": "Wd_cyc"    , "Unit": "mWh" , "FieldType" : "decimal" },
        {"Name": "Eff_Q"     , "Unit": ""    , "FieldType" : "decimal" },
        {"Name": "Eff_W"     , "Unit": ""    , "FieldType" : "decimal" },
		{"Name": "Qcc_cyc"   , "Unit": "mAh" , "FieldType" : "decimal" },
		{"Name": "Qdd_cyc"   , "Unit": "mAh" , "FieldType" : "decimal" }]])
    end
    cyc_data[1] = sample_t
    cyc_data[2] = sample_cycle_tstart
    cyc_data[3] = sample_cycle_t
    cyc_data[4] = sample_cycle_n
    cyc_data[5] = Qc / 3.6
    cyc_data[6] = Qd / 3.6
    cyc_data[7] = Wc / 3.6
    cyc_data[8] = Wd / 3.6
    cyc_data[9] = EffQ
    cyc_data[10]= EffW
	cyc_data[11] = Qcc_cyc / 3.6
    cyc_data[12] = Qdd_cyc / 3.6						 
    cycle_data_row = table.concat(cyc_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, cycle_data_row)
    end
end

---------------------- Send Output-Impedance.txt Data ---------------------------
--  Plotted as y over x=time or as Bode plot or as Nyquist plot.
--  If the parameter "header" is true, then this function will only print the header.
---------------------------------------------------------------------------------
function PrintOutputImpedance(header)
    local file = "Output-Impedance.txt"
    local rec = true
    if header then
        ec.Write_CSV_Header(file, [[
        {"Name": "freq"       , "Unit": "Hz"  , "FieldType" : "decimal" },
        {"Name": "t"          , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "t_cycle"    , "Unit": "s"   , "FieldType" : "timespan"},
        {"Name": "cycle"      , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "step"       , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "type"       , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "p/g"        , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "c/d"        , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "con"        , "Unit": ""    , "FieldType" : "text"    },
        {"Name": "V12"        , "Unit": "V"   , "FieldType" : "decimal" },
        {"Name": "V1R"        , "Unit": "V"   , "FieldType" : "decimal" },
        {"Name": "V2R"        , "Unit": "V"   , "FieldType" : "decimal" },
        {"Name": "dV12"       , "Unit": "mV"  , "FieldType" : "decimal" },
        {"Name": "dV1R"       , "Unit": "mV"  , "FieldType" : "decimal" },
        {"Name": "dV2R"       , "Unit": "mV"  , "FieldType" : "decimal" },
        {"Name": "I12"        , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "I1R"        , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "I2R"        , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "dI12"       , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "dI1R"       , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "dI2R"       , "Unit": "mA"  , "FieldType" : "decimal" },
        {"Name": "I-Range"    , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "Q1"         , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Q2"         , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "QR"         , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Qcd"        , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "|Qcd|"      , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Qc"         , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Qd"         , "Unit": "mAh" , "FieldType" : "decimal" },
        {"Name": "Re(Z12)"    , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "Im(Z12)"    , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "|Z12|"      , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "phi(Z12)"   , "Unit": "deg" , "FieldType" : "decimal" },
        {"Name": "SFDR(Z12)"  , "Unit": "dB"  , "FieldType" : "decimal" },
        {"Name": "Re(Z1)"     , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "Im(Z1)"     , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "|Z1|"       , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "phi(Z1)"    , "Unit": "deg" , "FieldType" : "decimal" },
        {"Name": "SFDR(Z1)"   , "Unit": "dB"  , "FieldType" : "decimal" },
        {"Name": "Re(Z2)"     , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "Im(Z2)"     , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "|Z2|"       , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "phi(Z2)"    , "Unit": "deg" , "FieldType" : "decimal" },
        {"Name": "SFDR(Z2)"   , "Unit": "dB"  , "FieldType" : "decimal" },
        {"Name": "Re(ZR)"     , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "Im(ZR)"     , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "|ZR|"       , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "phi(ZR)"    , "Unit": "deg" , "FieldType" : "decimal" },
        {"Name": "SFDR(ZR)"   , "Unit": "dB"  , "FieldType" : "decimal" },
        {"Name": "Re(Z1R)"    , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "Im(Z1R)"    , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "|Z1R|"      , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "phi(Z1R)"   , "Unit": "deg" , "FieldType" : "decimal" },
        {"Name": "SFDR(Z1R)"  , "Unit": "dB"  , "FieldType" : "decimal" },
        {"Name": "Re(Z2R)"    , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "Im(Z2R)"    , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "|Z2R|"      , "Unit": "Ohm" , "FieldType" : "decimal" },
        {"Name": "phi(Z2R)"   , "Unit": "deg" , "FieldType" : "decimal" },
        {"Name": "SFDR(Z2R)"  , "Unit": "dB"  , "FieldType" : "decimal" },
        {"Name": "Cs"         , "Unit": "uF"  , "FieldType" : "decimal" },
        {"Name": "Cp"         , "Unit": "uF"  , "FieldType" : "decimal" },
        {"Name": "A"          , "Unit": ""    , "FieldType" : "decimal" },
        {"Name": "n"          , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "m"          , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "f_err"      , "Unit": "%"   , "FieldType" : "decimal" },
        {"Name": "dt"         , "Unit": "s"   , "FieldType" : "decimal" },
        {"Name": "pre"        , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "avg"        , "Unit": ""    , "FieldType" : "integer" },
        {"Name": "DA"         , "Unit": ""    , "FieldType" : "integer" }]])
    end
    imp_data[1]  = EIS_freq
    imp_data[2]  = EIS_t
    imp_data[3]  = EIS_t - cycle_tstart
    imp_data[4]  = sample_cycle_n
    imp_data[5]  = sample_step_n
    imp_data[6]  = sample_step_type
    imp_data[7]  = sample_step_pg
    imp_data[8]  = sample_cd
    imp_data[9]  = sample_step_con
    imp_data[10] = EIS_V12_dc
    imp_data[11] = EIS_V1R_dc
    imp_data[12] = EIS_V2R_dc
    imp_data[13] = EIS_dV12   * 1000
    imp_data[14] = EIS_dV1R   * 1000
    imp_data[15] = EIS_dV2R   * 1000
    imp_data[16] = EIS_i12_dc * 1000
    imp_data[17] = EIS_i1R_dc * 1000
    imp_data[18] = EIS_i2R_dc * 1000
    imp_data[19] = EIS_di12   * 1000
    imp_data[20] = EIS_di1R   * 1000
    imp_data[21] = EIS_di2R   * 1000    
    imp_data[22] = EIS_i_range
    imp_data[23] = Q1      / 3.6
    imp_data[24] = Q2      / 3.6
    imp_data[25] = QR      / 3.6
    imp_data[26] = Qcd     / 3.6
    imp_data[27] = Qcd_abs / 3.6
    imp_data[28] = Qc      / 3.6
    imp_data[29] = Qd      / 3.6
    imp_data[30] = EIS_Z12_re
    imp_data[31] = EIS_Z12_im
    imp_data[32] = EIS_Z12_mag
    imp_data[33] = EIS_Z12_phi
    imp_data[34] = EIS_Z12_SFDR
    imp_data[35] = EIS_Z1_re
    imp_data[36] = EIS_Z1_im
    imp_data[37] = EIS_Z1_mag
    imp_data[38] = EIS_Z1_phi
    imp_data[39] = EIS_Z1_SFDR
    imp_data[40] = EIS_Z2_re
    imp_data[41] = EIS_Z2_im
    imp_data[42] = EIS_Z2_mag
    imp_data[43] = EIS_Z2_phi
    imp_data[44] = EIS_Z2_SFDR
    imp_data[45] = EIS_ZR_re
    imp_data[46] = EIS_ZR_im
    imp_data[47] = EIS_ZR_mag
    imp_data[48] = EIS_ZR_phi
    imp_data[49] = EIS_ZR_SFDR
    imp_data[50] = EIS_Z1R_re
    imp_data[51] = EIS_Z1R_im
    imp_data[52] = EIS_Z1R_mag
    imp_data[53] = EIS_Z1R_phi
    imp_data[54] = EIS_Z1R_SFDR
    imp_data[55] = EIS_Z2R_re
    imp_data[56] = EIS_Z2R_im
    imp_data[57] = EIS_Z2R_mag
    imp_data[58] = EIS_Z2R_phi
    imp_data[59] = EIS_Z2R_SFDR
    imp_data[60] = EIS_Cs * 1000000  -- uF
    imp_data[61] = EIS_Cp * 1000000  -- uF
    imp_data[62] = EIS_A  * 1000
    imp_data[63] = EIS_n
    imp_data[64] = EIS_m
    imp_data[65] = EIS_f_err
    imp_data[66] = EIS_dt
    imp_data[67] = EIS_precycles
    imp_data[68] = EIS_averages
    imp_data[69] = EIS_DAC

    impedance_data_row = table.concat(imp_data, "\t")
    if not header then
        ec.Write_CSV_Data(file, rec, impedance_data_row)
    end
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
    ApplyStepConfig(sample_step_n, true)
end

-- End of Script --
