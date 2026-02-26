###############################################################################
# cts.tcl
# Stage 4 – Clock Tree Synthesis (CTS) & Post-CTS Optimisation
# Design  : ORCA_TOP
# Tech    : saed32nm (28/32 nm)
# Tool    : Synopsys Fusion Compiler
###############################################################################
# Covers:
#   - Skew-controlled clock tree build (target ≤ 50 ps per domain)
#   - Non-default routing rules (NDR) for clock nets
#   - Multi-corner CTS for worst/best-case analysis
#   - Post-CTS timing optimisation (setup + hold)
###############################################################################

puts "INFO: Starting Stage 4 – Clock Tree Synthesis & Post-CTS Optimisation"

###############################################################################
# 1. Open block from placement stage
###############################################################################
open_lib   ./work/ORCA_TOP.dlib
open_block ORCA_TOP -label placement_done

###############################################################################
# 2. Non-default routing rules for clock nets
###############################################################################
# NDR: 2× width, 2× spacing on M3–M5 for clock shielding
create_routing_rule NDR_CLOCK \
    -default_reference_rule \
    -multiplied_width   2.0 \
    -multiplied_spacing 2.0 \
    -cut_metal_layers {M3 M4 M5}

# Shield ground wires on either side of clock nets
set_clock_routing_rules \
    -rule          NDR_CLOCK \
    -net_type      clock \
    -shield_metal_layer M3 \
    -shield_net    VSS \
    -max_routing_layer M5 \
    -min_routing_layer M3

puts "INFO: NDR for clock nets defined (2×width / 2×spacing, M3–M5, VSS shield)"

###############################################################################
# 3. CTS cell selection
###############################################################################
# Allow only high-Vt and regular-Vt clock buffers/inverters
# (Low-Vt avoided to limit leakage on clock tree)
set_lib_cell_purpose \
    -lib_cells [get_lib_cells {saed32nm_hvt/CLKBUFX* saed32nm_hvt/CLKINVX*}] \
    -include {cts}

set_lib_cell_purpose \
    -lib_cells [get_lib_cells {saed32nm_rvt/CLKBUFX* saed32nm_rvt/CLKINVX*}] \
    -include {cts}

set_dont_use \
    -lib_cells [get_lib_cells {saed32nm_lvt/CLKBUFX* saed32nm_lvt/CLKINVX*}] \
    -all

###############################################################################
# 4. Clock tree settings
###############################################################################
set_app_options -name cts.compile.enable_local_skew    -value true
set_app_options -name cts.compile.target_skew          -value 0.050  ;# 50 ps
set_app_options -name cts.compile.max_transition        -value 0.150  ;# 150 ps
set_app_options -name cts.compile.max_capacitance       -value 0.100  ;# 100 fF
set_app_options -name cts.compile.buffer_sizing_effort  -value high

# Honour clock uncertainty set in SDC
set_app_options -name cts.compile.use_clock_latency_adjustment -value true

###############################################################################
# 5. Multi-corner CTS
###############################################################################
# Define corners for clock tree analysis
set_scenario_status -active true \
    [get_scenarios {func_ss_max func_ff_min}]

# Worst-case corner (slow): CLK_CORE
set_clock_tree_options \
    -clock_trees [get_clocks CLK_CORE] \
    -target_skew 0.050 \
    -max_fanout  20 \
    -scenario    func_ss_max

# Best-case corner (fast): CLK_CORE (hold check)
set_clock_tree_options \
    -clock_trees [get_clocks CLK_CORE] \
    -target_skew 0.050 \
    -max_fanout  20 \
    -scenario    func_ff_min

# Memory interface clock
set_clock_tree_options \
    -clock_trees [get_clocks CLK_MEM] \
    -target_skew 0.070 \
    -max_fanout  16

puts "INFO: CTS options configured for multi-corner analysis"

###############################################################################
# 6. Clock tree compilation
###############################################################################
puts "INFO: Compiling clock tree …"
compile_clock_trees \
    -effort high

puts "INFO: Clock tree compilation done"

###############################################################################
# 7. Clock tree reporting (pre-optimisation)
###############################################################################
report_clock_tree \
    -summary \
    > ./reports/04_cts_summary_pre_opt.rpt

report_clock_timing \
    -type skew \
    -nosplit \
    > ./reports/04_cts_skew_pre_opt.rpt

###############################################################################
# 8. Clock routing (with NDR)
###############################################################################
puts "INFO: Routing clock nets …"
route_clock_nets \
    -nets [get_nets -hierarchical -filter "net_type==clock"] \
    -shield_nets VSS

puts "INFO: Clock net routing done"

###############################################################################
# 9. Post-CTS setup optimisation
###############################################################################
puts "INFO: Running post-CTS setup optimisation …"
set_app_options -name opt.common.max_num_cells_to_add -value 5000

optimize_clock_tree \
    -metric     skew

clock_opt \
    -optimize_dft \
    -hold_fix_allow_setup_tns_deterioration false

puts "INFO: Post-CTS setup optimisation done"

###############################################################################
# 10. Post-CTS hold optimisation
###############################################################################
puts "INFO: Running post-CTS hold fix …"
set_app_options -name opt.hold.slack_threshold -value 0.0

fix_hold_violations \
    -slack_margin 0.050 \
    -max_buffer_additions 2000

puts "INFO: Hold fix done"

###############################################################################
# 11. Post-CTS timing checks
###############################################################################
check_clock_tree \
    > ./reports/04_cts_check.rpt

report_clock_tree \
    -summary \
    > ./reports/04_cts_summary_post_opt.rpt

report_clock_timing \
    -type skew \
    -nosplit \
    > ./reports/04_cts_skew_post_opt.rpt

###############################################################################
# 12. Save and reports
###############################################################################
save_block -label cts_done

report_timing \
    -delay max \
    -max_paths 20 \
    -nworst    5 \
    > ./reports/04_timing_setup_postcts.rpt

report_timing \
    -delay min \
    -max_paths 20 \
    -nworst    5 \
    > ./reports/04_timing_hold_postcts.rpt

report_qor \
    > ./reports/04_qor_postcts.rpt

puts "INFO: Stage 4 – CTS & Post-CTS Optimisation complete"
puts "INFO: Reports written to ./reports/"
