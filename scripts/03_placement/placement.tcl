###############################################################################
# placement.tcl
# Stage 3 – Placement & Pre-CTS Optimisation
# Design  : ORCA_TOP
# Tech    : saed32nm (28/32 nm)
# Tool    : Synopsys Fusion Compiler
###############################################################################
# Covers:
#   - Timing-driven standard-cell placement
#   - Congestion-aware optimisation and density balancing
#   - Pre-CTS setup/hold optimisation
#   - Scan-chain reordering
###############################################################################

puts "INFO: Starting Stage 3 – Placement & Pre-CTS Optimisation"

###############################################################################
# 1. Open block from power-plan stage
###############################################################################
open_lib   ./work/ORCA_TOP.dlib
open_block ORCA_TOP -label power_plan_done

###############################################################################
# 2. Placement settings
###############################################################################
# Cell padding – 2 routing tracks on each side to reduce congestion
set_cell_padding -cells [all_standard_cells] -left 2 -right 2

# Use high-Vt cells during placement to save leakage power
# (timing-critical paths will be upsized during optimisation)
set_app_options -name place.coarse.cong_effort             -value high
set_app_options -name place.coarse.timing_driven           -value true
set_app_options -name place.legalize.enable_legalization   -value true
set_app_options -name place.detail.eco_max_displacement    -value {50 50}

# Congestion-aware spreading weights
set_app_options -name place.coarse.congestion_driven_spreading -value true
set_app_options -name place.coarse.max_density                 -value 0.85

puts "INFO: Placement options configured"

###############################################################################
# 3. Pre-placement timing setup
###############################################################################
# Propagate clocks to get accurate pre-CTS timing
set_app_options -name time.use_clock_latency      -value true
set_app_options -name time.remove_clock_reconvergence_pessimism -value true

###############################################################################
# 4. Placement blockages
###############################################################################
# Soft placement blockage around macro channels (reduce crowding)
create_placement_blockage \
    -type partial \
    -blocked_percentage 50 \
    -coordinate {810 60 830 740}    ;# Domain boundary channel

# Hard blockage on top of macros (already covered by halos; belt-and-braces)
create_placement_blockage \
    -type hard \
    -around macros

###############################################################################
# 5. Coarse placement
###############################################################################
puts "INFO: Running coarse placement …"
place_coarse \
    -congestion_driven true \
    -timing_driven     true

puts "INFO: Coarse placement done"

###############################################################################
# 6. Legalization
###############################################################################
legalize_placement

puts "INFO: Legalization done"

###############################################################################
# 7. Incremental placement – timing-driven detail
###############################################################################
puts "INFO: Running detail placement …"
place_detail \
    -max_displacement {50 50} \
    -effort high

puts "INFO: Detail placement done"

###############################################################################
# 8. Congestion analysis and spreading
###############################################################################
analyze_congestion \
    -layer_by_layer \
    -report ./reports/03_congestion_pre_opt.rpt

# If GRC (global-route congestion) overflow > 1 %, re-spread
set overflow [get_app_option -name route.global.overflow]
if {$overflow > 0.01} {
    puts "WARNING: Congestion overflow ${overflow} – applying spreading"
    spread_cells \
        -cell_utilization_target 0.70 \
        -effort high
    legalize_placement
}

###############################################################################
# 9. Pre-CTS optimisation (setup focus)
###############################################################################
puts "INFO: Running pre-CTS optimisation (setup) …"
optimize_netlist -area

place_opt \
    -effort   high \
    -optimize {setup hold} \
    -skip_report

puts "INFO: Pre-CTS optimisation done"

###############################################################################
# 10. Density balancing
###############################################################################
# Ensure no region exceeds 85 % density to leave room for CTS buffers
set_density_constraint \
    -site     unit \
    -max_density 0.85

balance_density

puts "INFO: Density balancing done"

###############################################################################
# 11. Scan-chain reordering
###############################################################################
# Reorder scan chains to minimise total scan wire length
set_scan_reorder_mode \
    -mode wire_length

reorder_scan \
    -report ./reports/03_scan_reorder.rpt

puts "INFO: Scan-chain reordering done"

###############################################################################
# 12. Post-placement checks
###############################################################################
check_placement \
    -verbose \
    > ./reports/03_placement_check.rpt

###############################################################################
# 13. Save and reports
###############################################################################
save_block -label placement_done

report_placement \
    > ./reports/03_placement_summary.rpt

report_timing \
    -delay max \
    -max_paths 20 \
    -nworst    5 \
    > ./reports/03_timing_setup_prects.rpt

report_timing \
    -delay min \
    -max_paths 20 \
    -nworst    5 \
    > ./reports/03_timing_hold_prects.rpt

report_qor \
    > ./reports/03_qor_prects.rpt

puts "INFO: Stage 3 – Placement & Pre-CTS Optimisation complete"
puts "INFO: Reports written to ./reports/"
