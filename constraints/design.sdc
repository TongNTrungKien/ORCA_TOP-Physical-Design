###############################################################################
# design.sdc
# SDC timing constraints for ORCA_TOP
# Technology : saed32nm (28/32 nm)
# Tool       : Synopsys Fusion Compiler
###############################################################################

###############################################################################
# 1. Design name
###############################################################################
current_design ORCA_TOP

###############################################################################
# 2. Clock definitions
###############################################################################
# Primary clock – 500 MHz (2.0 ns period)
create_clock -name CLK_CORE \
             -period 2.0 \
             -waveform {0 1.0} \
             [get_ports CLK]

# Memory/macro interface clock – 250 MHz
create_clock -name CLK_MEM \
             -period 4.0 \
             -waveform {0 2.0} \
             [get_ports CLK_MEM]

# Generated clock on PLL output
create_generated_clock -name CLK_PLL \
                       -source [get_ports CLK] \
                       -multiply_by 1 \
                       -divide_by 1 \
                       [get_pins PLL_INST/CLK_OUT]

###############################################################################
# 3. Clock uncertainty
###############################################################################
set_clock_uncertainty -setup 0.100 [get_clocks CLK_CORE]
set_clock_uncertainty -hold  0.050 [get_clocks CLK_CORE]
set_clock_uncertainty -setup 0.150 [get_clocks CLK_MEM]
set_clock_uncertainty -hold  0.075 [get_clocks CLK_MEM]

###############################################################################
# 4. Clock transition (slew)
###############################################################################
set_clock_transition 0.080 [get_clocks CLK_CORE]
set_clock_transition 0.100 [get_clocks CLK_MEM]

###############################################################################
# 5. Clock latency (pre-CTS estimates)
###############################################################################
set_clock_latency -source 0.200 [get_clocks CLK_CORE]
set_clock_latency        0.400 [get_clocks CLK_CORE]
set_clock_latency -source 0.250 [get_clocks CLK_MEM]
set_clock_latency        0.500 [get_clocks CLK_MEM]

###############################################################################
# 6. Input/output delays
###############################################################################
# Inputs constrained relative to CLK_CORE (40% of period)
set_input_delay  -max 0.800 -clock CLK_CORE [remove_from_collection [all_inputs] [get_ports CLK]]
set_input_delay  -min 0.100 -clock CLK_CORE [remove_from_collection [all_inputs] [get_ports CLK]]

# Outputs constrained relative to CLK_CORE (40% of period)
set_output_delay -max 0.800 -clock CLK_CORE [all_outputs]
set_output_delay -min 0.100 -clock CLK_CORE [all_outputs]

###############################################################################
# 7. Input/output drive strength and load
###############################################################################
set_driving_cell -lib_cell IBUFFX8_HVT -pin Y [all_inputs]
set_load 0.050 [all_outputs]

###############################################################################
# 8. Operating conditions
###############################################################################
# Worst-case (slow) corner
set_operating_conditions -max saed32nm_ss0p95v125c \
                         -max_library saed32nm_ss0p95v125c

# Best-case (fast) corner for hold analysis
set_operating_conditions -min saed32nm_ff1p16vm40c \
                         -min_library saed32nm_ff1p16vm40c

###############################################################################
# 9. Multi-voltage domains
###############################################################################
# High-voltage domain (1.05 V nominal) – right half of core
# Coordinates match floorplan.tcl voltage-area definition
create_voltage_area -name VDD_HIGH \
                    -coordinate {820 60 1640 740}

# Low-voltage domain (0.85 V nominal) – left half of core
create_voltage_area -name VDD_LOW \
                    -coordinate {60 60 810 740}

###############################################################################
# 10. False paths and multi-cycle paths
###############################################################################
# Asynchronous reset – false path
set_false_path -from [get_ports RST_N]

# Scan path – false path from scan enable
set_false_path -from [get_ports SCAN_EN]

# Clock-domain crossing (CLK_CORE -> CLK_MEM) – constrained separately
set_false_path -from [get_clocks CLK_CORE] -to [get_clocks CLK_MEM]
set_false_path -from [get_clocks CLK_MEM]  -to [get_clocks CLK_CORE]

# Configuration registers – 2-cycle multi-cycle path
set_multicycle_path -setup 2 -from [get_cells -hierarchical CONFIG_REG*]
set_multicycle_path -hold  1 -from [get_cells -hierarchical CONFIG_REG*]

###############################################################################
# 11. Max transition and max capacitance
###############################################################################
set_max_transition 0.300 [current_design]
set_max_capacitance 0.200 [current_design]

###############################################################################
# 12. Disable timing arcs on isolation/level-shifter cells
###############################################################################
set_disable_timing [get_cells -hierarchical -filter "ref_name =~ ISO_*"]

###############################################################################
# End of SDC
###############################################################################
