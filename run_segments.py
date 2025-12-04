WIDTH = 200
HEIGHT = 200

# Load segments
segments = []
current = []

with open("segments.txt") as f:
    for line in f:
        if line.startswith("SEGMENT"):
            current = []
        elif line.startswith("END"):
            segments.append(current)
        else:
            x, y = map(int, line.split())
            current.append((x, y))

# Create blank grid
grid = [[" " for _ in range(WIDTH)] for _ in range(HEIGHT)]

# Mark the segments
for seg in segments:
    for (x, y) in seg:
        if 0 <= x < WIDTH and 0 <= y < HEIGHT:
            grid[y][x] = "#"

# Flip vertically so it looks correct
grid.reverse()

# Print it!
for row in grid:
    print("".join(row))
