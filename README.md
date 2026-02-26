# ORCA_TOP-Physical-Design

## Project Overview

A complete back-end physical implementation of the **ORCA_TOP** multi-voltage digital block using the **SAED 32/28nm** standard-cell library and **Synopsys Fusion Compiler**.

| Attribute | Value |
|---|---|
| Technology | SAED 32nm (saed32nm) |
| Design Type | Multi-Voltage Digital Block |
| Standard Cells | ~53,000 |
| Macro Count | 40 |
| Metal Layers | 9 (M1–M9) |
| EDA Tool | Synopsys Fusion Compiler |

---

## Repository Structure

```
ORCA_TOP-Physical-Design/
├── constraints/
│   └── design.sdc             # Timing constraints (SDC)
├── scripts/
│   ├── 01_floorplan/
│   │   └── floorplan.tcl      # Core definition, macro placement, voltage areas
│   ├── 02_power_plan/
│   │   └── power_plan.tcl     # Power mesh, macro rings, PG routing
│   ├── 03_placement/
│   │   └── placement.tcl      # Timing-driven, congestion-aware placement
│   ├── 04_cts/
│   │   └── cts.tcl            # Clock tree synthesis & post-CTS optimization
│   ├── 05_routing/
│   │   └── routing.tcl        # Global/detailed routing & post-route optimization
│   └── run_all.tcl            # Master flow script
└── reports/                   # Output reports directory
```

---

## Implementation Flow

### 1. Floorplanning (`scripts/01_floorplan/floorplan.tcl`)
- Core area definition with target utilization (~70%)
- Macro placement with channel spacing constraints
- Multi-voltage area partitioning (VDD_HIGH / VDD_LOW domains)
- Level-shifter and isolation-cell placement regions

### 2. Power Planning (`scripts/02_power_plan/power_plan.tcl`)
- Hierarchical power mesh across M4–M9
- Dedicated macro power rings on M7/M8
- Per-voltage-domain stripe routing
- Multi-layer PG connection and via stack generation

### 3. Placement (`scripts/03_placement/placement.tcl`)
- Timing-driven standard-cell placement
- Congestion-aware spreading and density balancing
- Pre-CTS optimization (hold/setup)
- Scan-chain reordering for wire-length reduction

### 4. Clock Tree Synthesis (`scripts/04_cts/cts.tcl`)
- Target skew ≤ 50 ps per clock domain
- Non-default routing rules (NDR) for clock nets
- Multi-corner CTS for worst/best-case analysis
- Post-CTS timing optimization

### 5. Routing (`scripts/05_routing/routing.tcl`)
- Global routing with congestion analysis
- Detailed routing with signal-integrity (SI) awareness
- Crosstalk-driven net ordering
- Post-route optimization and ECO routing

---

## How to Run

Launch Synopsys Fusion Compiler and source the master script:

```tcl
fc_shell> source scripts/run_all.tcl
```

Or run individual stages:

```tcl
fc_shell> source scripts/01_floorplan/floorplan.tcl
fc_shell> source scripts/02_power_plan/power_plan.tcl
fc_shell> source scripts/03_placement/placement.tcl
fc_shell> source scripts/04_cts/cts.tcl
fc_shell> source scripts/05_routing/routing.tcl
```

---

## Key Design Parameters

| Parameter | Value |
|---|---|
| Core Utilization | ~70% |
| Target Frequency | 500 MHz |
| Voltage Domains | VDD_HIGH (1.05 V), VDD_LOW (0.85 V) |
| Clock Skew Target | ≤ 50 ps |
| Routing Layers (signal) | M2–M6 |
| Routing Layers (power) | M7–M9 |
| NDR Width/Spacing (clock) | 2×/2× |

---

## Status

The design has completed all major back-end stages through post-route optimization. Additional refinement is required before full signoff quality is achieved.

### Completed
- [x] Floorplanning
- [x] Power planning
- [x] Placement & pre-CTS optimization
- [x] Clock tree synthesis & post-CTS optimization
- [x] Global & detailed routing
- [x] Post-route optimization

### Future Work
- [ ] Timing signoff (STA with all PVT corners)
- [ ] Physical verification (DRC/LVS clean)
- [ ] Additional ECO iterations for hold/setup closure
- [ ] IR drop and electromigration analysis

---

## References

- Synopsys Fusion Compiler Documentation
- SAED 32/28nm PDK User Guide
- IEEE Std 1801 (UPF) for multi-voltage design
