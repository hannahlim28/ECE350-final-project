#include <stdlib.h>   // for malloc, realloc, free
#include <stddef.h>   // for size_t
#include <stdio.h>
#include <math.h>


typedef struct {
    int x;
    int y;
} Point;

typedef struct {
    Point *data;
    size_t size;
    size_t capacity;
} PointArray;

typedef struct{
    PointArray *lines;
    size_t size;
    size_t capacity;
 } LineArray;

void LineArray_init(LineArray *arr){
    arr->lines = NULL;
    arr->size = 0;
    arr->capacity = 0;
}
void LineArray_add(LineArray *arr, PointArray *parr){
    if(arr->size == arr->capacity){
        size_t new_cap = (arr->capacity == 0) ? 4: arr->capacity * 2;
        arr->lines = realloc(arr->lines, new_cap * sizeof(PointArray));
        arr->capacity = new_cap;
    }
    arr->lines[arr->size++] = *parr;
}
void PointArray_free(PointArray *arr){
    free(arr->data);
    arr->data = NULL;
    arr->size = 0;
    arr->capacity =0;
}
void LineArray_free(LineArray *arr){
    for(int i = 0; i < arr->size; i++){
        PointArray_free(&arr->lines[i]);
    }
    free(arr->lines);
    arr->lines = NULL;
    arr->size = 0;
    arr->capacity=0;
}
void PointArray_init(PointArray *arr){
    arr->data = NULL;
    arr->size = 0;
    arr->capacity=0;
}
void PointArray_add(PointArray *arr, Point p){
    if(arr->size == arr->capacity){
        size_t new_cap = (arr->capacity == 0) ? 4: arr->capacity * 2;
        arr->data = realloc(arr->data, new_cap * sizeof(Point));
        arr->capacity = new_cap;
    }
    arr->data[arr->size++] = p;
}

int in_bounds(int x, int y, int r, int c){
    return ((0<=x && x<c) &&(0<=y && y<r));
}


static const int DIRS[8][2] = {
    {0,-1},
    {1,-1},
    {1,0},
    {1,1},
    {0,1},
    {-1,1},
    {-1,0},
    {-1,-1}
};

LineArray edge_to_vect(int *edgemap, int rows, int cols);
LineArray find_lines(LineArray *pixel_lists);

int main() {
    int rows = 200, cols = 200;
    int *edge_map = calloc(rows * cols, sizeof(int));

    // Cloud circle centers and radii
    struct { int cx, cy, r; } circles[] = {
        {70,  100, 40},
        {100,  70, 45},
        {130, 100, 40},
        {160, 120, 35},
        {110, 140, 55}
    };

    int num_circles = sizeof(circles) / sizeof(circles[0]);

    for (int i = 0; i < num_circles; i++) {
        int cx = circles[i].cx;
        int cy = circles[i].cy;
        int r  = circles[i].r;

        for (int y = cy - r - 1; y <= cy + r + 1; y++) {
            for (int x = cx - r - 1; x <= cx + r + 1; x++) {
                if (x >= 0 && x < cols && y >= 0 && y < rows) {
                    double dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
                    if (fabs(dist - r) < 0.7) {  // thin edge trace
                        edge_map[y * cols + x] = 1;
                    }
                }
            }
        }
    }
    

    FILE *fedge = fopen("edge_map.txt", "w");
    if (!fedge) {
        printf("Error opening edge_map.txt\n");
        return 1;
    }

    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
            fprintf(fedge, "%d", edge_map[y * cols + x]);
        }
        fprintf(fedge, "\n");
    }

    fclose(fedge);
    printf("Saved edge map to edge_map.txt\n");

    
    printf("Running edge_to_vect()...\n");
    LineArray raw_lines = edge_to_vect(edge_map, rows, cols);

    printf("Number of traced lines: %zu\n\n", raw_lines.size);

    for (size_t i = 0; i < raw_lines.size; i++) {
        printf("Raw Line %zu (%zu points):\n", i, raw_lines.lines[i].size);
        for (size_t j = 0; j < raw_lines.lines[i].size; j++) {
            Point p = raw_lines.lines[i].data[j];
            printf("  (%d, %d)\n", p.x, p.y);
        }
        printf("\n");
    }


    printf("Running find_lines()...\n");
    LineArray segments = find_lines(&raw_lines);

    FILE *f = fopen("segments.txt", "w");

    for (size_t i = 0; i < segments.size; i++) {
        fprintf(f, "SEGMENT %zu\n", i);
        for (size_t j = 0; j < segments.lines[i].size; j++) {
            Point p = segments.lines[i].data[j];
            fprintf(f, "%d %d\n", p.x, p.y);
        }
        fprintf(f, "END\n");
    }

    fclose(f);

    printf("Number of line segments: %zu\n\n", segments.size);
    for (size_t i = 0; i < segments.size; i++) {
        printf("Segment %zu (%zu points):\n", i, segments.lines[i].size);
        for (size_t j = 0; j < segments.lines[i].size; j++) {
            Point p = segments.lines[i].data[j];
            printf("  (%d, %d)\n", p.x, p.y);
        }
        printf("\n");
    }


    // Cleanup
    LineArray_free(&segments);
    LineArray_free(&raw_lines);
    free(edge_map);

    return 0;
}

LineArray edge_to_vect(int *edgemap, int rows, int cols){
    LineArray line_list;
    LineArray_init(&line_list);

    Point start = {-1, -1};

    int endOfLine = 0;
    int backOfLine = 0;
    int *visited = calloc(rows * cols, sizeof(int));

    for(int y = 0; y < rows; y++){
        for (int x=0; x<cols; x++){
            if(in_bounds(x, y, rows, cols) && edgemap[y*cols + x] == 1 && visited[y*cols +x] == 0){
                Point p = {x, y};
                PointArray pixel_list;
                PointArray_init(&pixel_list);

                PointArray_add(&pixel_list, p);
                visited[y*cols + x] = 1;
                LineArray_add(&line_list, &pixel_list);
                PointArray *current_line = &line_list.lines[line_list.size - 1];


                start.x = x;
                start.y = y;

                Point next = {-1, -1};

                while(endOfLine == 0){
                    int added = 0;
                    for (int d = 0; d < 8; d++) {
                        next.x = x + DIRS[d][0];
                        next.y = y + DIRS[d][1];
                        if(in_bounds(next.x, next.y, rows, cols)){
                            if((edgemap[next.y*cols + next.x] == 1 && visited[next.y*cols+next.x] == 0) || (next.y == start.y && next.x == start.x)){
                                PointArray_add(current_line, next);
                                x = next.x;
                                y = next.y;
                                added = 1;
                                visited[next.y*cols +next.x] = 1;
                                break;
                            }
                        }   
                    }
                    if(added == 0){
                         endOfLine = 1;
                    }
                }
                while(backOfLine == 0){
                    int badded = 0;
                    for (int d = 8; d < 0; d--) {
                        next.x = x + DIRS[d][0];
                        next.y = y + DIRS[d][1];
                        if(in_bounds(next.x, next.y, rows, cols)){
                            if((edgemap[next.y*cols + next.x] == 1 && visited[next.y*cols+next.x] == 0) || (next.y == start.y && next.x == start.x)){
                                PointArray_add(current_line, next);
                                x = next.x;
                                y = next.y;
                                badded = 1;
                                visited[next.y*cols +next.x] = 1;
                                break;
                            }
                        }   
                    }
                    if(badded == 0){
                         backOfLine = 1;
                    }
                }
                start.x = -1;
                start.y = -1;
                endOfLine = 0;
                backOfLine = 0;
            }
        }
    }
    return line_list;
}


LineArray find_lines(LineArray *pixel_lists){
    LineArray segments;
    LineArray_init(&segments);
    for(int i = 0; i < pixel_lists->size; i++){
        PointArray pixels;
        PointArray_init(&pixels);
        PointArray_add(&pixels, pixel_lists->lines[i].data[0]);
        LineArray_add(&segments, &pixels);
        PointArray *current_line = &segments.lines[segments.size - 1];
        for(int j = 0; (j+1) <pixel_lists->lines[i].size;j++){

            Point p0 = pixel_lists->lines[i].data[j];
            Point p1 = pixel_lists->lines[i].data[j+1];
            if((j+2) >= pixel_lists->lines[i].size){
                PointArray_add(current_line, p1);
                break;
            }
            Point p2 = pixel_lists->lines[i].data[j+2];

            int dx1 = p1.x - p0.x;
            int dx2 = p2.x - p1.x;
            int dy1 = p1.y - p0.y;
            int dy2 = p2.y - p1.y;
            if(dx1 != dx2 || dy1 != dy2){
                PointArray_add(current_line, p1);

                PointArray new_segment;
                PointArray_init(&new_segment);
                PointArray_add(&new_segment, p1);
                LineArray_add(&segments, &new_segment);
                current_line = &segments.lines[segments.size - 1];
            }
        }
    }
    return segments;
}
