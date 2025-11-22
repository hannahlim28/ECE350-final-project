G90 ; Use absolute positioning
G21 ; Set units to millimeters
G0 Z0.5 F300 ; Move to a safe height (0.5mm above bed/workpiece)
G0 X0 Y0 F1000 ; Move to the starting corner (0,0)

G1 F600 ; Set movement speed (feed rate) to 600 mm/min
G1 X10 Y0 ; Move to (10, 0)
G1 X10 Y10 ; Move to (10, 10)
G1 X0 Y10 ; Move to (0, 10)
G1 X0 Y0 ; Move back to (0, 0), completing the square

G0 Z10 ; Lift the tool to a high, safe position
M5 ; Turn off spindle (for CNC) or fan (for some 3D printers)
M30 ; Program end