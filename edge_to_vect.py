import numpy as np

# DIRS = [(0,-1), (1,-1), (1,0), (1,1), (0,1), (-1,1), (-1,0), (-1,-1)]
DIRS = [
    (1, 0),   # right
    (1, 1),   # down-right
    (0, 1),   # down
    (-1, 1),  # down-left
    (-1, 0),  # left
    (-1, -1), # up-left
    (0, -1),  # up
    (1, -1),  # up-right
]
def in_bounds(x,y,H,W):
    return 0 <= x < W and 0 <= y < H

def edge_to_vect(edge_map):
    R, C = edge_map.shape
    visited = np.zeros_like(edge_map, dtype = bool)
    pixel_follow = []
    for y in range(R):
        for x in range(C):
            if(edge_map[y,x]== 1 and not visited[y, x]):
                forwardpoly = [(x,y)]
                visited[y,x] = 1
                px, py = x, y
                while True:
                    found_next = False
                    for dx, dy in DIRS:
                        nx = px+dx
                        ny = py+dy
                        if(0<= nx < C and 0 <= ny < R):
                            if(edge_map[ny,nx] == 1 and not visited[ny,nx]):
                                poly_points = (nx, ny)
                                forwardpoly.append(poly_points)
                                visited[ny, nx] = 1
                                px, py = nx, ny
                                found_next = True
                                break
                    if not found_next:
                        break
                polyline = forwardpoly
                pixel_follow.append(polyline)
                       
    return pixel_follow

def merge_lines(list_pixels):
    new_list = []
    for i in range(0, len(list_pixels)-1, 1):
        sx1, sy1 = list_pixels[i][0]
        ex1, ey1 = list_pixels[i][len(list_pixels[i])-1]
        sx2, sy2 = list_pixels[i+1][0]
        ex2, ey2 = list_pixels[i+1][len(list_pixels[i+1])-1]

        # NEXT IS BEFORE CURRENT
        dx1 = ex2 - sx1
        dy1 = ey2 - sy1
        dist1 = (dx1 * dx1) + (dy1 * dy1)
        # NEXT IS AFTER CURRENT 
        dx2 = sx2 - ex1
        dy2 = sy2 - ey1
        dist2 = (dx2 * dx2) + (dy2 * dy2)
        if((sx1 == ex2 and sy1 == ey2) or (dist1 ==1)):
            sec_pixels = list_pixels[i+1][::-1] + list_pixels[i][1:] 
            new_list.append(sec_pixels)
        elif((ex1 == sx2 and ey1==sy2) or (dist2 == 1)):
            sec_pixels = list_pixels[i][:] + list_pixels[i+1][1:]
            new_list.append(sec_pixels)
        else:
            new_list.append(list_pixels[i])
    return new_list
def perp_distance(x0, x1, xf, y0, y1, yf):
    dx = x1 - x0
    dy = y1 - y0

    dfx = xf - x0
    dfy = yf - y0

    if dx == 0 and dy == 0:
        return (dfx*dfx) + (dfy*dfy)

    sqrdrt = dy*(xf - x0) - dx*(yf - y0)
    dist = sqrdrt * sqrdrt
    length = (dx * dx) + (dy*dy)
    return dist/length

def douglas_peucker(points, epsilon):
    if(len(points) < 3):
        return points
    max_dist = 0
    index = -1

    x0, y0 = points[0]
    x1, y1 = points[-1]

    for i in range(1, len(points) -1):
        xp, yp = points[i]
        curr_dist = perp_distance(x0, x1, xp, y0, y1, yp) 
        if(curr_dist > max_dist):
            max_dist = curr_dist
            index = i
    if max_dist > epsilon:
        left = douglas_peucker(points[:index+1], epsilon)
        right = douglas_peucker(points[index:], epsilon)
        return left[:-1] + right
    else:
        return [points[0],points[-1]]


def find_lines(list_pixels):
    threshold = 0.1
    threshsquare = threshold * threshold
    segments = []
    for pixels in list_pixels:
        start_idx= 0
        end_idx = 1
        next_idx = end_idx +1
        if len(pixels) < 2:
            continue

        while(next_idx < len(pixels)):
            x0, y0 = pixels[start_idx]
            x1, y1 = pixels[end_idx]
            xf, yf = pixels[next_idx]
            dx = x1 - x0
            dy = y1 - y0

            sqrdrt = dy*(xf - x0) - dx*(yf - y0)
            dist = sqrdrt * sqrdrt
            length = (dx * dx) + (dy*dy)
            if(dist <= threshsquare * length):
                end_idx = next_idx
                next_idx = end_idx +1
            else:
                segments.append([(x0, y0), (x1, y1)])
                start_idx = end_idx
                end_idx = start_idx + 1
                next_idx = end_idx + 1
        segments.append([(x0, y0), (x1, y1)])
    return segments

def load_edge_map(mem_filename, width=100, height=100):
    edge = [[0]*width for _ in range(height)]
    y = 0
    
    with open(mem_filename) as f:
        for line in f:
            tokens = line.strip().split()
            if not tokens:
                continue
            
            if len(tokens) != width:
                raise ValueError(f"Expected {width} values per line, got {len(tokens)}.")

            for x in range(width):
                edge[y][x] = 0 if tokens[x] == "0" else 1
            y += 1
            if y >= height:
                break
        
    if y < height:
        raise ValueError("File ended too early! Not enough rows.")

    return np.array(edge)

def visualize_polylines(polylines, width=100, height=100):
    # Make blank canvas
    canvas = [['.' for _ in range(width)] for _ in range(height)]

    # Draw each point in every polyline
    poly_id = 0
    for poly in polylines:
        symbol = str(poly_id % 10)  # label polylines 0–9 repeating
        for (x, y) in poly:
            if 0 <= x < width and 0 <= y < height:
                canvas[y][x] = symbol
        poly_id += 1

    print(f"Polylines detected: {len(polylines)}")
    # Print
    for row in canvas:
        print("".join(row))
def visualize_segment_points(segments, width=100, height=100):
    canvas = [['.' for _ in range(width)] for _ in range(height)]

    for (x0,y0), (x1,y1) in segments:
        if 0 <= x0 < width and 0 <= y0 < height:
            canvas[y0][x0] = '*'
        if 0 <= x1 < width and 0 <= y1 < height:
            canvas[y1][x1] = '*'

    # print canvas
    for row in canvas:
        print("".join(row))
def visualize_segments(segments, width=100, height=100):
    # Create blank grid
    canvas = [["." for _ in range(width)] for _ in range(height)]

    for seg_idx, seg in enumerate(segments):
        (x0, y0), (x1, y1) = seg
        marker = str(seg_idx % 10)  # label segment index mod 10

        # If the segment is just a point
        if x0 == x1 and y0 == y1:
            if 0 <= x0 < width and 0 <= y0 < height:
                canvas[y0][x0] = marker
            continue

        # Bresenham line drawing
        dx = abs(x1 - x0)
        dy = abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx - dy

        x, y = x0, y0
        while True:
            if 0 <= x < width and 0 <= y < height:
                canvas[y][x] = marker

            if x == x1 and y == y1:
                break

            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x += sx
            if e2 < dx:
                err += dx
                y += sy

    # Print visualization
    for row in canvas:
        print("".join(row))

edge_map = load_edge_map("star_edge.mem")
edge_map = np.array(edge_map)
np.savetxt("edge_map.txt", edge_map, fmt="%d")



first_list = edge_to_vect(edge_map)
merge_list = merge_lines(first_list)
doug = [douglas_peucker(poly, epsilon = 0.7) for poly in merge_list]
print(doug)
get_lines = find_lines(doug)

visualize_segments(get_lines)

# print(edge_to_vect(edge_map))
# print(find_lines(edge_to_vect(edge_map)))
# visualize_segments(find_lines(douglas_peucker(merge_lines(edge_to_vect(edge_map)), 0.)))
# visualize_polylines(merge_list)

                