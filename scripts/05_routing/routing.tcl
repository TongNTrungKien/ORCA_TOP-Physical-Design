###############################################################################
# routing.tcl
# Stage 5 – Routing & Post-Route Optimisation
# Design  : ORCA_TOP
# Tech    : saed32nm (28/32 nm)
# Tool    : Synopsys Fusion Compiler
###############################################################################
# Covers:
#   - Global routing with congestion analysis
#   - Detailed routing with signal-integrity (SI) awareness
#   - Crosstalk-driven net ordering
#   - Post-route optimisation and ECO routing
###############################################################################

puts "INFO: Starting Stage 5 – Routing & Post-Route Optimisation"

###############################################################################
# 1. Open block from CTS stage
###############################################################################
open_lib   ./work/ORCA_TOP.dlib
open_block ORCA_TOP -label cts_done

###############################################################################
# 2. Routing layer constraints
###############################################################################
# Signal routing: M2–M6
# Power routing : M7–M9 (reserved, do not route signals on these layers)
set_preferred_routing_direction -layer M2 -direction horizontal
set_preferred_routing_direction -layer M3 -direction vertical
set_preferred_routing_direction -layer M4 -direction horizontal
set_preferred_routing_direction -layer M5 -direction vertical
set_preferred_routing_direction -layer M6 -direction horizontal

# Restrict power/ground and macro layers from signal routing
set_routing_rule -layer M7 -type no_routing
set_routing_rule -layer M8 -type no_routing
set_routing_rule -layer M9 -type no_routing

# Max layer for standard-cell signal routing
set_app_options -name route.global.max_layer_for_signal   -value M6
set_app_options -name route.detail.max_layer_for_signal   -value M6

puts "INFO: Routing layer constraints set (signal: M2–M6)"

###############################################################################
# 3. Signal-integrity routing settings
###############################################################################
# Enable crosstalk-aware global routing
set_app_options -name route.global.crosstalk_driven        -value true
set_app_options -name route.global.timing_driven           -value true
set_app_options -name route.global.congestion_effort       -value high

# Detailed-route SI options
set_app_options -name route.detail.si_driven               -value true
set_app_options -name route.detail.antenna_checking        -value true
set_app_options -name route.detail.via_optimization        -value true
set_app_options -name route.detail.diode_insertion         -value true

puts "INFO: SI-aware routing options configured"

###############################################################################
# 4. Net ordering for crosstalk reduction
###############################################################################
# Route timing-critical nets first, then shield sensitive nets
set_net_routing_priority \
    -nets [get_nets -filter "net_type==clock"] \
    -priority 100

set_net_routing_priority \
    -nets [filter_collection [all_fanout -flat -clock_tree false] \
               "slack < 0.200"] \
    -priority 80

# Crosstalk-driven net ordering
set_si_options \
    -route_xtalk_prevention       true \
    -delta_delay_threshold        0.050 \
    -min_delta_glitch_threshold   0.050 \
    -max_transition_sensitivity   0.100

puts "INFO: Net routing priorities and SI options set"

###############################################################################
# 5. Global routing
###############################################################################
puts "INFO: Running global routing …"

route_global \
    -effort high \
    -timing_driven true \
    -congestion_effort high \
    -eco_route false

puts "INFO: Global routing done"

# Analyse congestion after global route
analyze_congestion \
    -layer_by_layer \
    -report ./reports/05_congestion_global_route.rpt

###############################################################################
# 6. Track assignment
###############################################################################
puts "INFO: Running track assignment …"
route_track \
    -effort high

puts "INFO: Track assignment done"

###############################################################################
# 7. Detailed routing
###############################################################################
puts "INFO: Running detailed routing …"

route_detail \
    -effort high \
    -incremental false

puts "INFO: Detailed routing done"

###############################################################################
# 8. Post-route antenna fix
###############################################################################
puts "INFO: Fixing antenna violations …"
route_detail \
    -effort high \
    -incremental true \
    -antenna_fixing true

puts "INFO: Antenna fixing done"

###############################################################################
# 9. Post-route SI optimisation
###############################################################################
puts "INFO: Running post-route SI optimisation …"

# Extract parasitics at signoff accuracy
extract_rc \
    -effort high

# Run SI-based timing analysis
set_app_options -name time.si_enable_analysis -value true

# Fix SI violations (delta delay + glitch)
optimize_routes \
    -si_fixing true \
    -effort high

puts "INFO: Post-route SI optimisation done"

###############################################################################
# 10. Post-route setup optimisation (ECO)
###############################################################################
puts "INFO: Running post-route setup ECO …"

route_opt \
    -effort high \
    -optimize {setup}

puts "INFO: Post-route setup ECO done"

###############################################################################
# 11. Post-route hold optimisation (ECO)
###############################################################################
puts "INFO: Running post-route hold ECO …"

fix_hold_violations \
    -slack_margin 0.050 \
    -max_buffer_additions 1000 \
    -eco_mode true

route_eco \
    -effort medium \
    -fix_drc true

puts "INFO: Post-route hold ECO done"

###############################################################################
# 12. DRC clean-up routing
###############################################################################
puts "INFO: Running final DRC clean-up routing …"

route_detail \
    -effort high \
    -incremental true \
    -drc_fix true

puts "INFO: DRC clean-up routing done"

###############################################################################
# 13. Filler cell insertion
###############################################################################
# Insert standard-cell fillers to fill all empty rows
add_filler_cells \
    -lib_cells [get_lib_cells saed32nm_hvt/FILLCELL*] \
    -prefix    FILLER

puts "INFO: Filler cells inserted"

###############################################################################
# 14. Final DRC and connectivity checks
###############################################################################
verify_drc \
    -layer_by_layer \
    -report ./reports/05_drc_final.rpt

verify_connectivity \
    -type all \
    -report ./reports/05_connectivity_final.rpt

###############################################################################
# 15. Save and reports
###############################################################################
save_block -label routing_done

# Final parasitic extraction for signoff-level timing
extract_rc \
    -effort high

report_timing \
    -delay max \
    -max_paths 30 \
    -nworst    5 \
    > ./reports/05_timing_setup_postroute.rpt

report_timing \
    -delay min \
    -max_paths 30 \
    -nworst    5 \
    > ./reports/05_timing_hold_postroute.rpt

report_qor \
    > ./reports/05_qor_postroute.rpt

report_congestion \
    > ./reports/05_congestion_final.rpt

report_si_bottleneck \
    -cost_type delta_delay \
    > ./reports/05_si_bottleneck.rpt

report_utilization \
    > ./reports/05_utilization_final.rpt

puts "INFO: Stage 5 – Routing & Post-Route Optimisation complete"
puts "INFO: Reports written to ./reports/"
