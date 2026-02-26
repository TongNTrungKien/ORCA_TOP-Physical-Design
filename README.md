# ORCA_TOP-Physical-Design

Project Details:
 Technology Node: saed32nm (28/32nm);
 Design Type: Multi-Voltage Digital Block;
 Standard Cell Count: ~53,000;
 Macro Count: 40;
 Metal Layers: 9;
 EDA Tool: Synopsys Fusion Compiler;

Flow Covered:

Floorplanning
 Core definition and utilization setup
 Macro placement with channel spacing consideration
 Multi-voltage area partitioning
 
Power Planning
 Hierarchical power mesh
 Dedicated macro power rings
 Multi-layer PG routing
 
Placement
 Timing-driven standard cell placement
 Congestion-aware optimization
 Density balancing
 
Clock Tree Synthesis (CTS)
 Skew-controlled clock tree build
 Clock routing with non-default rules
 Post-CTS optimization
 
Routing
 Global and detailed routing
 Signal integrity-aware routing
 Post-route optimization

This project helped me understand how floorplanning, placement, CTS, and routing influence each other and impact overall design convergence.
The design still requires additional refinement to reach full signoff quality, but it reflects hands-on experience with a complete backend implementation flow.

Future Work:
 Timing and physical verification refinement toward signoff
 Continued optimization through additional ECO iterations
