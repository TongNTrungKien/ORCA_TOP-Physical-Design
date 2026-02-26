###############################################################################
# floorplan.tcl
# Stage 1 – Floorplanning
# Design  : ORCA_TOP
# Tech    : saed32nm (28/32 nm)
# Tool    : Synopsys Fusion Compiler
###############################################################################
# Covers:
#   - Core area definition and utilization setup
#   - Macro placement with channel spacing consideration
#   - Multi-voltage area partitioning
###############################################################################

puts "INFO: Starting Stage 1 – Floorplanning"

###############################################################################
# 1. Design initialisation
###############################################################################
# Open the synthesised netlist (assuming it was saved as a design library)
open_lib  ./work/ORCA_TOP.dlib
open_block ORCA_TOP

# Read timing constraints
read_sdc  ./constraints/design.sdc

###############################################################################
# 2. Core area definition
###############################################################################
# Die area  : 1700 x 800 µm
# Core area : 1600 x 700 µm  (50 µm boundary on all sides)
# Target cell utilisation ≈ 70 %
initialize_floorplan \
    -die_coordinate  {0 0 1700 800} \
    -core_coordinate {50 50 1650 750} \
    -core_utilization 0.70 \
    -core_offset      {50 50 50 50}

puts "INFO: Core floorplan initialised (die 1700x800, core 1600x700, util 70%)"

###############################################################################
# 3. Row and site definition
###############################################################################
# Use the unit cell site from the saed32nm technology
create_site_row \
    -site        unit \
    -direction   horizontal \
    -flip        alternate

###############################################################################
# 4. Multi-voltage domain creation
###############################################################################
# VDD_HIGH domain – right half of the core (high-performance logic)
create_voltage_area \
    -name    VDD_HIGH \
    -power_domain  PD_HIGH \
    -coordinate {820 60 1640 740} \
    -guard_band_size 8

# VDD_LOW domain – left half of the core (low-power logic)
create_voltage_area \
    -name    VDD_LOW \
    -power_domain  PD_LOW \
    -coordinate {60 60 810 740} \
    -guard_band_size 8

# Level-shifter and isolation placement constraints
# Keep level-shifters within 20 µm of the domain boundary
set_voltage_area_boundary_snap \
    -voltage_area VDD_HIGH \
    -snap_to_row

puts "INFO: Voltage areas VDD_HIGH and VDD_LOW created"

###############################################################################
# 5. Macro placement
###############################################################################
# 40 macros: 8 SRAM banks, 8 register files, 24 hard-IP blocks
# Channel spacing of at least 15 µm between adjacent macros

# --- SRAM banks (8 x SRAM_256x32) ---
set sram_width  120
set sram_height  80
set ch_space     15

# Row 1 – SRAM banks 0-3 (left half, y=650..730)
set_cell_location -name SRAM_BANK_0 -coordinate [list  65 660]  -orientation R0
set_cell_location -name SRAM_BANK_1 -coordinate [list [expr  65 + $sram_width + $ch_space] 660] -orientation R0
set_cell_location -name SRAM_BANK_2 -coordinate [list [expr  65 + 2*($sram_width + $ch_space)] 660] -orientation R0
set_cell_location -name SRAM_BANK_3 -coordinate [list [expr  65 + 3*($sram_width + $ch_space)] 660] -orientation R0

# Row 2 – SRAM banks 4-7 (right half, y=650..730)
set_cell_location -name SRAM_BANK_4 -coordinate [list  830 660] -orientation R0
set_cell_location -name SRAM_BANK_5 -coordinate [list [expr  830 + $sram_width + $ch_space] 660] -orientation R0
set_cell_location -name SRAM_BANK_6 -coordinate [list [expr  830 + 2*($sram_width + $ch_space)] 660] -orientation R0
set_cell_location -name SRAM_BANK_7 -coordinate [list [expr  830 + 3*($sram_width + $ch_space)] 660] -orientation R0

# --- Register files (8 x RF_64x16) ---
set rf_width  60
set rf_height 40

for {set i 0} {$i < 8} {incr i} {
    set xpos [expr {65 + $i * ($rf_width + $ch_space)}]
    set_cell_location -name RF_$i -coordinate [list $xpos 600] -orientation R0
}

# --- Hard-IP blocks (24 instances in two rows) ---
set ip_width  50
set ip_height 50

# First row of IPs (y ≈ 80)
for {set i 0} {$i < 12} {incr i} {
    set xpos [expr {65 + $i * ($ip_width + $ch_space)}]
    set_cell_location -name HARD_IP_[expr {$i}]      -coordinate [list $xpos 65] -orientation R0
}

# Second row of IPs (y ≈ 145)
for {set i 0} {$i < 12} {incr i} {
    set xpos [expr {65 + $i * ($ip_width + $ch_space)}]
    set_cell_location -name HARD_IP_[expr {$i + 12}] -coordinate [list $xpos [expr {65 + $ip_height + $ch_space}]] -orientation R0
}

puts "INFO: All 40 macros placed with ≥${ch_space} µm channel spacing"

###############################################################################
# 6. Macro halos (blockage halo around every macro)
###############################################################################
# 5 µm placement blockage halo around all macros to avoid congestion
create_placement_blockage \
    -type   hard \
    -around macros \
    -halo   {5 5 5 5}

###############################################################################
# 7. Port placement
###############################################################################
# Distribute I/O ports on the die boundary
set_port_side -ports [get_ports -filter "direction==in"]  -side left
set_port_side -ports [get_ports -filter "direction==out"] -side right
set_port_side -ports [get_ports CLK*]                     -side bottom
set_port_side -ports [get_ports RST*]                     -side bottom

###############################################################################
# 8. Tap cells and well connections
###############################################################################
add_tap_cell_array \
    -lib_cell   saed32nm_hvt/TAPCELL \
    -distance   25 \
    -pattern    stagger

puts "INFO: Tap cells inserted every 25 µm"

###############################################################################
# 9. End-cap cells
###############################################################################
add_end_cap_cell \
    -lib_cell_left  saed32nm_lvt/DECAP \
    -lib_cell_right saed32nm_lvt/DECAP

###############################################################################
# 10. Save and reports
###############################################################################
save_block -label floorplan_done

report_floorplan     > ./reports/01_floorplan_summary.rpt
report_voltage_areas > ./reports/01_voltage_areas.rpt
report_macro_placement \
    -check_channel_spacing \
    > ./reports/01_macro_placement.rpt

puts "INFO: Stage 1 – Floorplanning complete"
puts "INFO: Reports written to ./reports/"
