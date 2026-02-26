###############################################################################
# power_plan.tcl
# Stage 2 – Power Planning
# Design  : ORCA_TOP
# Tech    : saed32nm (28/32 nm)
# Tool    : Synopsys Fusion Compiler
###############################################################################
# Covers:
#   - Hierarchical power mesh (M4–M9)
#   - Dedicated macro power rings
#   - Multi-layer PG routing
###############################################################################

puts "INFO: Starting Stage 2 – Power Planning"

###############################################################################
# 1. Open block from floorplan stage
###############################################################################
open_lib   ./work/ORCA_TOP.dlib
open_block ORCA_TOP -label floorplan_done

###############################################################################
# 2. Define PG net names and connections
###############################################################################
set VDD_H  VDD_HIGH    ;# 1.05 V supply
set VDD_L  VDD_LOW     ;# 0.85 V supply
set GND    VSS         ;# Ground

# Connect standard-cell PG pins to the correct supply nets
connect_pg_net -net $VDD_H  -to_pins {VDD}   -domain PD_HIGH
connect_pg_net -net $VDD_L  -to_pins {VDD}   -domain PD_LOW
connect_pg_net -net $GND    -to_pins {VSS}

###############################################################################
# 3. Core ring (outermost ring – M8/M9)
###############################################################################
# M9 horizontal straps (top/bottom of core)
create_pg_ring_pattern core_ring \
    -horizontal_layer M9 \
    -horizontal_width  8.0 \
    -horizontal_spacing 2.0 \
    -vertical_layer   M8 \
    -vertical_width    8.0 \
    -vertical_spacing  2.0

add_pg_ring \
    -pattern  core_ring \
    -nets     [list $VDD_H $GND] \
    -core_ring_type outer \
    -offset   5.0

puts "INFO: Core power ring added on M8/M9"

###############################################################################
# 4. VDD_HIGH domain ring (M7/M8)
###############################################################################
create_pg_ring_pattern vdd_high_ring \
    -horizontal_layer M8 \
    -horizontal_width  6.0 \
    -horizontal_spacing 2.0 \
    -vertical_layer   M7 \
    -vertical_width    6.0 \
    -vertical_spacing  2.0

add_pg_ring \
    -pattern  vdd_high_ring \
    -nets     [list $VDD_H $GND] \
    -voltage_area VDD_HIGH \
    -offset   3.0

puts "INFO: VDD_HIGH domain ring added on M7/M8"

###############################################################################
# 5. VDD_LOW domain ring (M7/M8)
###############################################################################
create_pg_ring_pattern vdd_low_ring \
    -horizontal_layer M8 \
    -horizontal_width  6.0 \
    -horizontal_spacing 2.0 \
    -vertical_layer   M7 \
    -vertical_width    6.0 \
    -vertical_spacing  2.0

add_pg_ring \
    -pattern  vdd_low_ring \
    -nets     [list $VDD_L $GND] \
    -voltage_area VDD_LOW \
    -offset   3.0

puts "INFO: VDD_LOW domain ring added on M7/M8"

###############################################################################
# 6. Macro power rings (per-macro, M7/M8)
###############################################################################
# Dedicated ring around every hard macro to guarantee IR convergence
foreach_in_collection macro [get_cells -hierarchical -filter "is_hard_macro==true"] {
    set mname [get_attribute $macro full_name]
    create_pg_ring_pattern macro_ring_${mname} \
        -horizontal_layer M8 \
        -horizontal_width  4.0 \
        -horizontal_spacing 1.5 \
        -vertical_layer   M7 \
        -vertical_width    4.0 \
        -vertical_spacing  1.5

    add_pg_ring \
        -pattern  macro_ring_${mname} \
        -nets     [list $VDD_H $GND] \
        -around   $mname \
        -offset   2.0
}

puts "INFO: Individual macro power rings created on M7/M8"

###############################################################################
# 7. Power mesh – M4 vertical stripes (fine pitch, signal layer boundary)
###############################################################################
create_pg_mesh_pattern mesh_m4 \
    -layers [list \
        [create_pg_mesh_layer \
             -layer      M4 \
             -direction  vertical \
             -width      0.8 \
             -spacing    1.6 \
             -pitch      10.0 \
             -offset     5.0]]

add_pg_mesh \
    -pattern  mesh_m4 \
    -nets     [list $VDD_H $VDD_L $GND] \
    -voltage_area {VDD_HIGH VDD_LOW} \
    -boundary_type core

puts "INFO: M4 vertical power stripes added (pitch 10 µm)"

###############################################################################
# 8. Power mesh – M5 horizontal stripes
###############################################################################
create_pg_mesh_pattern mesh_m5 \
    -layers [list \
        [create_pg_mesh_layer \
             -layer      M5 \
             -direction  horizontal \
             -width      1.0 \
             -spacing    2.0 \
             -pitch      15.0 \
             -offset     7.5]]

add_pg_mesh \
    -pattern  mesh_m5 \
    -nets     [list $VDD_H $VDD_L $GND] \
    -voltage_area {VDD_HIGH VDD_LOW} \
    -boundary_type core

puts "INFO: M5 horizontal power stripes added (pitch 15 µm)"

###############################################################################
# 9. Power mesh – M6 vertical stripes (coarser)
###############################################################################
create_pg_mesh_pattern mesh_m6 \
    -layers [list \
        [create_pg_mesh_layer \
             -layer      M6 \
             -direction  vertical \
             -width      2.0 \
             -spacing    3.0 \
             -pitch      30.0 \
             -offset     15.0]]

add_pg_mesh \
    -pattern  mesh_m6 \
    -nets     [list $VDD_H $VDD_L $GND] \
    -boundary_type core

puts "INFO: M6 vertical power stripes added (pitch 30 µm)"

###############################################################################
# 10. Power mesh – M7 horizontal stripes (global distribution)
###############################################################################
create_pg_mesh_pattern mesh_m7 \
    -layers [list \
        [create_pg_mesh_layer \
             -layer      M7 \
             -direction  horizontal \
             -width      4.0 \
             -spacing    4.0 \
             -pitch      50.0 \
             -offset     25.0]]

add_pg_mesh \
    -pattern  mesh_m7 \
    -nets     [list $VDD_H $VDD_L $GND] \
    -boundary_type core

puts "INFO: M7 horizontal power stripes added (pitch 50 µm)"

###############################################################################
# 11. Via pillars – connect mesh layers with stacked vias
###############################################################################
add_pg_via_master_rule via_pillar_rule \
    -cut_layer_widths {VIA1 0.1 VIA2 0.1 VIA3 0.1 VIA4 0.2 VIA5 0.2 VIA6 0.4 VIA7 0.4 VIA8 0.6}

synthesize_pg_via \
    -via_master_rule via_pillar_rule \
    -nets [list $VDD_H $VDD_L $GND]

puts "INFO: PG via pillars synthesised (VIA1–VIA8)"

###############################################################################
# 12. Standard-cell rail insertion
###############################################################################
# M1 VDD/VSS rails follow cell rows
add_pg_std_cell_conn_pattern std_cell_rail \
    -rail_width   0.12 \
    -bottom_layer M1 \
    -top_layer    M1

apply_pg_std_cell_conn \
    -nets [list $VDD_H $VDD_L $GND]

puts "INFO: M1 standard-cell power rails inserted"

###############################################################################
# 13. Verify power network connectivity
###############################################################################
verify_pg_nets \
    -nets [list $VDD_H $VDD_L $GND] \
    -report ./reports/02_pg_connectivity.rpt

###############################################################################
# 14. Save and reports
###############################################################################
save_block -label power_plan_done

report_power_plan  > ./reports/02_power_plan_summary.rpt
report_ir_drop     > ./reports/02_ir_drop_estimate.rpt

puts "INFO: Stage 2 – Power Planning complete"
puts "INFO: Reports written to ./reports/"
