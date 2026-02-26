###############################################################################
# run_all.tcl
# Master flow script – ORCA_TOP full back-end implementation
# Design  : ORCA_TOP
# Tech    : saed32nm (28/32 nm)
# Tool    : Synopsys Fusion Compiler
###############################################################################
# Usage:
#   fc_shell> source scripts/run_all.tcl
#
# Individual stages can be re-run by sourcing their scripts directly:
#   fc_shell> source scripts/01_floorplan/floorplan.tcl
###############################################################################

puts "============================================================"
puts "  ORCA_TOP Physical Design – Full Back-End Flow"
puts "  Technology : saed32nm (28/32 nm)"
puts "  Tool       : Synopsys Fusion Compiler"
puts "============================================================"

###############################################################################
# 0. Flow control flags
#    Set any flag to 0 to skip that stage (useful for re-runs)
###############################################################################
set RUN_FLOORPLAN    1
set RUN_POWER_PLAN   1
set RUN_PLACEMENT    1
set RUN_CTS          1
set RUN_ROUTING      1

###############################################################################
# 1. Environment checks
###############################################################################
if {![file isdirectory ./work]} {
    file mkdir ./work
    puts "INFO: Created ./work directory"
}

if {![file isdirectory ./reports]} {
    file mkdir ./reports
    puts "INFO: Created ./reports directory"
}

###############################################################################
# 2. Stage execution
###############################################################################
set flow_start_time [clock seconds]

# ---- Stage 1: Floorplanning ----
if {$RUN_FLOORPLAN} {
    puts "\n[string repeat = 60]"
    puts "  STAGE 1: Floorplanning"
    puts "[string repeat = 60]"
    set t0 [clock seconds]
    source scripts/01_floorplan/floorplan.tcl
    set elapsed [expr {[clock seconds] - $t0}]
    puts "INFO: Stage 1 completed in ${elapsed}s"
} else {
    puts "INFO: Skipping Stage 1 – Floorplanning (RUN_FLOORPLAN=0)"
}

# ---- Stage 2: Power Planning ----
if {$RUN_POWER_PLAN} {
    puts "\n[string repeat = 60]"
    puts "  STAGE 2: Power Planning"
    puts "[string repeat = 60]"
    set t0 [clock seconds]
    source scripts/02_power_plan/power_plan.tcl
    set elapsed [expr {[clock seconds] - $t0}]
    puts "INFO: Stage 2 completed in ${elapsed}s"
} else {
    puts "INFO: Skipping Stage 2 – Power Planning (RUN_POWER_PLAN=0)"
}

# ---- Stage 3: Placement ----
if {$RUN_PLACEMENT} {
    puts "\n[string repeat = 60]"
    puts "  STAGE 3: Placement & Pre-CTS Optimisation"
    puts "[string repeat = 60]"
    set t0 [clock seconds]
    source scripts/03_placement/placement.tcl
    set elapsed [expr {[clock seconds] - $t0}]
    puts "INFO: Stage 3 completed in ${elapsed}s"
} else {
    puts "INFO: Skipping Stage 3 – Placement (RUN_PLACEMENT=0)"
}

# ---- Stage 4: CTS ----
if {$RUN_CTS} {
    puts "\n[string repeat = 60]"
    puts "  STAGE 4: Clock Tree Synthesis & Post-CTS Optimisation"
    puts "[string repeat = 60]"
    set t0 [clock seconds]
    source scripts/04_cts/cts.tcl
    set elapsed [expr {[clock seconds] - $t0}]
    puts "INFO: Stage 4 completed in ${elapsed}s"
} else {
    puts "INFO: Skipping Stage 4 – CTS (RUN_CTS=0)"
}

# ---- Stage 5: Routing ----
if {$RUN_ROUTING} {
    puts "\n[string repeat = 60]"
    puts "  STAGE 5: Routing & Post-Route Optimisation"
    puts "[string repeat = 60]"
    set t0 [clock seconds]
    source scripts/05_routing/routing.tcl
    set elapsed [expr {[clock seconds] - $t0}]
    puts "INFO: Stage 5 completed in ${elapsed}s"
} else {
    puts "INFO: Skipping Stage 5 – Routing (RUN_ROUTING=0)"
}

###############################################################################
# 3. Flow summary
###############################################################################
set total_elapsed [expr {[clock seconds] - $flow_start_time}]
set total_min     [expr {$total_elapsed / 60}]
set total_sec     [expr {$total_elapsed % 60}]

puts "\n[string repeat = 60]"
puts "  ORCA_TOP Flow Complete"
puts "  Total wall-clock time: ${total_min}m ${total_sec}s"
puts "[string repeat = 60]"

# Print key QoR summary
if {$RUN_ROUTING} {
    puts "\nINFO: Key post-route QoR:"
    report_qor -summary
} elseif {$RUN_CTS} {
    puts "\nINFO: Key post-CTS QoR:"
    report_qor -summary
} elseif {$RUN_PLACEMENT} {
    puts "\nINFO: Key pre-CTS QoR:"
    report_qor -summary
}

puts "\nINFO: All reports are located in ./reports/"
puts "INFO: Saved block labels: floorplan_done, power_plan_done, placement_done, cts_done, routing_done"
