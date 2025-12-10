#!/usr/bin/env python3
from typing import List

INPUT_MEM_FILE = "plant.mem"
OUTPUT_GCODE_FILE = "plant.gcode"

PIXEL_SIZE_MM = 1.0      
CENTER_ON_ORIGIN = True 

Z_UP_MM = 5.0
Z_DOWN_MM = 0.0
FEED_RATE = 1000.0


def read_mem_bitmap(path: str) -> List[List[int]]:
    grid: List[List[int]] = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            tokens = line.split()
            row: List[int] = []

            for tok in tokens:
                val = 1 if "1" in tok else 0
                row.append(val)

            if row:
                grid.append(row)

    if not grid:
        raise ValueError("No bitmap data found in .mem")

    width = max(len(r) for r in grid)
    for r in grid:
        if len(r) < width:
            r.extend([0] * (width - len(r)))

    return grid


def generate_gcode_from_grid(
    grid: List[List[int]],
    pixel_size_mm: float,
    center_on_origin: bool,
    z_up: float,
    z_down: float,
    feed_rate: float,
) -> str:
    
    height = len(grid)
    width = len(grid[0])

    draw_width_mm = width * pixel_size_mm
    draw_height_mm = height * pixel_size_mm

    if center_on_origin:
        x_offset = -draw_width_mm / 2.0
        y_offset = -draw_height_mm / 2.0
    else:
        x_offset = 0.0
        y_offset = 0.0

    lines = []
    lines.append(f"; Center on origin: {center_on_origin}")
    lines.append("G21 ; mm units")
    lines.append("G90 ; absolute coords")
    lines.append(f"G0 Z{z_up:.3f}  ; pen up")

    for y in range(height):
        row = grid[y]
        x = 0
        while x < width:
            if row[x] == 0:
                x += 1
                continue

            # continuous run of "on" pixels
            run_start = x
            while x < width and row[x] == 1:
                x += 1
            run_end = x - 1

            x_start_mm = x_offset + run_start * pixel_size_mm
            x_end_mm   = x_offset + run_end   * pixel_size_mm
            y_mm       = y_offset + y        * pixel_size_mm

            lines.append(f"G0 X{x_start_mm:.3f} Y{y_mm:.3f} Z{z_up:.3f}")
            lines.append(f"G1 Z{z_down:.3f} F{feed_rate:.1f}")
            lines.append(f"G1 X{x_end_mm:.3f} Y{y_mm:.3f}")
            lines.append(f"G0 Z{z_up:.3f}")

    lines.append(f"G0 Z{z_up:.3f}")
    lines.append("G0 X0.000 Y0.000")
    lines.append("M2")
    return "\n".join(lines) + "\n"


def main():
    grid = read_mem_bitmap(INPUT_MEM_FILE)
    gcode = generate_gcode_from_grid(
        grid,
        pixel_size_mm=PIXEL_SIZE_MM,
        center_on_origin=CENTER_ON_ORIGIN,
        z_up=Z_UP_MM,
        z_down=Z_DOWN_MM,
        feed_rate=FEED_RATE,
    )
    with open(OUTPUT_GCODE_FILE, "w") as f:
        f.write(gcode)
    print("Done.")

if __name__ == "__main__":
    main()
