def load_segments(filename):
    segments = []
    current = []
    
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            if line.startswith("#"):
                # New segment marker
                if current:
                    segments.append(current)
                    current = []
            else:
                parts = line.split()
                if len(parts) == 2:
                    x, y = map(int, parts)
                    current.append((x, y))
    
    if current:  # append last segment
        segments.append(current)
    
    return segments


def render_ascii(segments):
    # collect min/max ranges
    all_x = [p[0] for seg in segments for p in seg]
    all_y = [p[1] for seg in segments for p in seg]
    
    min_x, max_x = min(all_x), max(all_x)
    min_y, max_y = min(all_y), max(all_y)

    width = max_x - min_x + 1
    height = max_y - min_y + 1

    # Create display grid
    grid = [[" " for _ in range(width)] for _ in range(height)]

    # Plot segments
    for seg in segments:
        for (x, y) in seg:
            gx = x - min_x
            gy = max_y - y  # invert y-axis
            grid[gy][gx] = "#"  # mark pixel
    
    # Print
    for row in grid:
        print("".join(row))


if __name__ == "__main__":
    segs = load_segments("segments.txt")
    print(f"Loaded {len(segs)} segments")
    render_ascii(segs)
