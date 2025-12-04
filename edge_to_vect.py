import numpy as np

DIRS = [(0,-1), (1,-1), (1,0), (1,1), (0,1), (-1,1), (-1,0), (-1,-1)]

def in_bounds(x,y,H,W):
    return 0 <= x < W and 0 <= y < H

def edge_to_vect(edge_map):
    R, C = edge_map.shape
    visited = np.zeros_like(edge_map, dtype = bool)
    pixel_follow = []
    index = 0
    start = (None, None)
    endOfLine = False
    nx, ny = None, None
    for y in range(R):
        for x in range(C):
            if(edge_map[y,x] == 1 and visited[y, x] != True and start == (None, None)):
                pixel_follow.append([])
                pixel_follow[index].append((x,y))
                start = (x,y)
                while((nx, ny) != start and not endOfLine):
                    added = False
                    for dx, dy in DIRS:
                        nx, ny = (x+dx), (y+dy)
                        if edge_map[ny, nx] == 1 and visited[ny, nx] != True and in_bounds(nx, ny, R, C):
                            pixel_follow[index].append((nx, ny))
                            x, y = nx, ny
                            added = True
                            visited[ny, nx] = True
                            break
                        visited[ny, nx] = True
                    if added != True:
                        endOfLine = True
                index = index + 1
                start = (None, None)
                endOfLine = False
                visited[y, x] = True
    return pixel_follow

def find_lines(list_pixels):
    segments = []
    index = 0
    for y in list_pixels:
        segments.append([])
        segments[index].append(y[0])
        for i in range(len(y)):
            (x0, y0) = y[i]
            (x1, y1) = y[i+1]
            if(i+2 >= len(y)):
                segments[index].append((x1,y1))
                break
            (x2, y2) = y[i+2]
            dx1 = x1-x0
            dx2 = x2-x1
            dy1 = y1-y0
            dy2 = y2-y1
            if dx1 != dx2 or dy1 != dy2:
                segments[index].append((x1,y1))
                index +=1
                segments.append([])
                segments[index].append((x1,y1))
    return segments

# Create a 200x200 array of zeros
edge_map = np.zeros((20, 20), dtype=int)

# Define square boundaries
top = 5
bottom = 15
left = 5
right = 15

# Top horizontal edge
edge_map[top, left:right+1] = 1

# Bottom horizontal edge
edge_map[bottom, left:right+1] = 1

# Left vertical edge
edge_map[top:bottom+1, left] = 1

# Right vertical edge
edge_map[top:bottom+1, right] = 1

np.savetxt("edge_map.txt", edge_map, fmt="%d")
print(find_lines(edge_to_vect(edge_map)))
                