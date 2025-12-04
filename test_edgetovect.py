import numpy as np

# (y,x)
# GO UP   (-1, 0)
# GO DOWN ( 1, 0)
# GO LEFT ( 0,-1)
# GO RIGHT( 1, 0)

DIRS = [
    (-1,-1), (-1, 0), (-1, 1),
    ( 0,-1),          ( 0, 1),
    (-1, 1), ( 1, 0), ( 1, 1)  
]

# CHECK IF STILL IN IMAGE
def is_inside(x, y, H, W):
    return 0 <= x < edge_map.shape[0] and 0 <= y < edge_map.shape[1] and edge_map[x, y] == 1

def edge_to_segments(edge_map):
    H, W = edge_map.shape
    visited = np.zeros_like(edge_map, dtype = bool)
    segments = []
    for r in range(H):
        for c in range(W):
            if not is_edge(r, c, edge_map):
                continue
            for dr, dc in DIRS:
                pr, pc = r-dr, c-dc
                nr, nc = r+dr, c+dc
                if not is_edge(nr, nc, edge_map):
                    continue
                if is_edge(pr, pc, edge_map):
                    continue
                start = (r, c)
                cur_r, cur_c = r, c
                while True:
                    nr, nc = cur_r + dr, cur_c + dc
                    if not is_edge(nr, nc, edge_map):
                        break
                    cur_r, cur_c = nr, nc
                end = (cur_r, cur_c)
                segments.append((start, end))
    return segments


# Create a 200x200 array of zeros
edge_map = np.zeros((200, 200), dtype=int)

# Define square boundaries
top = 50
bottom = 150
left = 50
right = 150

# Top horizontal edge
edge_map[top, left:right+1] = 1

# Bottom horizontal edge
edge_map[bottom, left:right+1] = 1

# Left vertical edge
edge_map[top:bottom+1, left] = 1

# Right vertical edge
edge_map[top:bottom+1, right] = 1

np.savetxt("edge_map.txt", edge_map, fmt="%d")
print(edge_to_segments(edge_map))

