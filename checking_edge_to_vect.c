#include <stdio.h>
#include <stdlib.h>


/*---------------------------------- INSTANTIATION -----------------------------------------*/
#define WIDTH 100
#define HEIGHT 100

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
static const int DIRS[8][2] = {
    { 1, 0},
    { 1, 1},
    { 0, 1},
    {-1, 1},
    {-1, 0},
    {-1,-1},
    { 0,-1},
    { 1,-1}
};
/*------------------------------------------------------------------------------------------*/
/*---------------------------------- FUNCTION DECLARATIONS ---------------------------------*/

int load_mem(const char *filename, int edge_map[HEIGHT*WIDTH]);
void dump_line_array(LineArray *lines, const char *filename);

/*------------------------------------------------------------------------------------------*/
/*--------------------------------------- BOUND CHECKING -----------------------------------*/
int in_bounds(int x, int y){
    return ((0<=x && x<WIDTH) &&(0<=y && y<HEIGHT));
}
/*--------------------------------------- REVERSE ARRAY -----------------------------------*/
void reverse_point_array(PointArray *pa) {
    int left = 0;
    int right = pa->size - 1;
    while (left < right) {
        Point temp = pa->data[left];
        pa->data[left] = pa->data[right];
        pa->data[right] = temp;
        left++;
        right--;
    }
}
/*--------------------------------------- PERPENDICULAR DISTANCE -----------------------------------*/
int perp_distance(int x0, int x1, int xf, int y0, int y1, int yf){
    int dx = x1 - x0;
    int dy = y1 - y0;
    
    int dfx = xf - x0;
    int dfy = yf - y0;

    if(dx == 0 && dy ==0){
        return (dfx * dfx) + (dfy*dfy);
    }
    int sqrt = dy*(dfx) - dx*(dfy);
    int dist = sqrt * sqrt;
    int length = (dx*dx) + (dy*dy);
    return dist/length;
}
/*--------------------------------------- GRAB PIXELS -----------------------------------*/

LineArray edge_to_vect(int edgemap[HEIGHT * WIDTH]){
    LineArray line_list;
    LineArray_init(&line_list);

    for(int y = 0; y < HEIGHT; y++){
        for (int x=0; x< WIDTH; x++){
            if(edgemap[y*WIDTH + x] == 1){
                Point p = {x, y};
                PointArray pixel_list;
                PointArray_init(&pixel_list);

                int px = x, py = y;
                PointArray_add(&pixel_list, p);
                edgemap[py*WIDTH + px] = 0;
                LineArray_add(&line_list, &pixel_list);
                PointArray *current_line = &line_list.lines[line_list.size - 1];

                Point next = {-1, -1};
                while(1){
                    int found_next = 0;
                    for (int d = 0; d < 8; d++) {
                        next.x = px + DIRS[d][0];
                        next.y = py + DIRS[d][1];
                        if(in_bounds(next.x, next.y)){
                            if(edgemap[next.y*WIDTH + next.x] == 1){
                                PointArray_add(current_line, next);
                                px = next.x;
                                py = next.y;
                                edgemap[next.y*WIDTH +next.x] = 0;
                                found_next = 1;
                                break;
                            }
                        }   
                    }
                    if(found_next == 0){
                        break;
                    }
                }
                
            }
        }
    }
    return line_list;
}
/*---------------------------- MERGING SIMILAR SHORT SEGMENTS-------------------------------*/
LineArray merge_lines(LineArray *linelist){
    LineArray merged_list;
    LineArray_init(&merged_list);
    for(int i = 0; i < linelist -> size-1; i++){
        PointArray *pa1 = &linelist ->lines[i];
        int sx1 = pa1 -> data[0].x;
        int sy1 = pa1 -> data[0].y;
        int ex1 = pa1 -> data[pa1->size - 1].x;
        int ey1 = pa1 -> data[pa1->size - 1].y;

        PointArray *pa2 = &linelist ->lines[i+1];
        int sx2 = pa2 -> data[0].x;
        int sy2 = pa2 -> data[0].y;
        int ex2 = pa2 -> data[pa2->size - 1].x;
        int ey2 = pa2 -> data[pa2->size - 1].y;
        // next is before current
        int dx1 = ex2 - sx1;
        int dy1 = ey2 - sy1;
        int dist1 = (dx1*dx1) + (dy1*dy1);
        // next is after current
        int dx2 = sx2 - ex1;
        int dy2 = sy2 - ey1;
        int dist2 = (dx2*dx2) + (dy2*dy2);

        if((sx1 == ex2 && sy1 == ey2) || dist1 == 1){
            PointArray *revsec = pa2;
            reverse_point_array(revsec);
            PointArray first;
            PointArray_init(&first);
            for(int k = 0; k < revsec->size; k++){
                PointArray_add(&first, revsec->data[k]);
            }
            for(int j = 1; j<pa1 -> size ; j++){
                PointArray_add(&first, pa1->data[j]);
            }
            LineArray_add(&merged_list, &first);
        } else if((ex1 == sx2 && ey1== sy2) || dist2 ==1){
            PointArray second;
            PointArray_init(&second);
            for(int l = 0; l < pa1->size; l++){
                PointArray_add(&second, pa1->data[l]);
            }
            for(int m = 1; m <pa2 -> size ; m++){
                PointArray_add(&second, pa2->data[m]);
            }
            LineArray_add(&merged_list, &second);
        }else{
            LineArray_add(&merged_list, pa1);
        }
    }
    return merged_list;
}
/*---------------------------- DOUGLAS PEUCKER ALGORITHM -----------------------------------*/
PointArray* douglas_peucker(PointArray *points, float epsilon){
        if(points->size < 3){
            return points;
        } else {
            int max_distance = 0;
            int index = -1;
            int x0 = points -> data[0].x;
            int y0 = points -> data[0].y;
            int x1 = points -> data[points->size -1].x;
            int y1 = points -> data[points->size -1].y;
            for(int j = 1 ; j<points->size -1;j++){
                int xp = points ->data[j].x;
                int yp = points ->data[j].y;
                int curr_distance = perp_distance(x0, x1, xp, y0, y1, yp);
                if(curr_distance > max_distance){
                    max_distance = curr_distance;
                    index = j;
                }
            }
            if(max_distance > epsilon){
                PointArray prev;
                PointArray_init(&prev);
                PointArray after;
                PointArray_init(&after);
                for(int j = 0; j < index + 1; j++){
                    PointArray_add(&prev, points->data[j]);
                }
                for(int k = index; k < points->size; k++){
                    PointArray_add(&after, points->data[k]);
                }
                PointArray *left = douglas_peucker(&prev, epsilon);
                PointArray *right = douglas_peucker(&after, epsilon);
                PointArray *new = malloc(sizeof(PointArray));
                PointArray_init(new);
                for(int l = 0; l<left->size -1; l++){
                    PointArray_add(new, left->data[l]);
                }
                for(int m = 0; m<right->size; m++){
                    PointArray_add(new, right->data[m]);
                    
                }
                return new;
            }else{
                PointArray* extra = malloc(sizeof(PointArray));
                PointArray_init(extra);
                PointArray_add(extra, points->data[0]);
                PointArray_add(extra, points->data[points->size-1]);
                return extra;
            }
        }
        
}
LineArray doug_recurse(LineArray *line_points, float epsilon){
    LineArray douglas;
    LineArray_init(&douglas);
    for(int i = 0; i < line_points ->size; i++){
        PointArray *points = &line_points ->lines[i];
        PointArray *douglassed = douglas_peucker(points, epsilon);
        LineArray_add(&douglas, douglassed);
    }
    return douglas;
}
/*---------------------------------- LINE SEGMENTS VECTORS ---------------------------------*/
LineArray find_lines(LineArray *list_pixels){
    int threshold = 0.1f;
    int threshsqr = threshold * threshold;
    LineArray segments;
    LineArray_init(&segments);

    for(int i = 0; i < list_pixels ->size;i++){
        PointArray *pixels = &list_pixels -> lines[i];
        int start_idx = 0;
        int end_idx = 1;
        int next_idx = end_idx +1;
        if (pixels -> size <2){
            continue;
        }
        while(next_idx < pixels->size){
            int x0 = pixels -> data[start_idx].x;
            int y0 = pixels -> data[start_idx].y;
            int x1 = pixels -> data[end_idx].x;
            int y1 = pixels -> data[end_idx].y;
            int xf = pixels -> data[next_idx].x;
            int yf = pixels -> data[next_idx].y;
            if(perp_distance(x0, x1, xf, y0, y1, yf) <= threshsqr){
                end_idx = next_idx;
                next_idx = end_idx +1;
            }else{
                PointArray interm;
                PointArray_init(&interm);
                PointArray_add(&interm, pixels->data[start_idx]);
                PointArray_add(&interm, pixels->data[end_idx]);
                LineArray_add(&segments, &interm);
                start_idx = end_idx;
                end_idx = start_idx +1;
                next_idx = end_idx +1;
            }
        }
        PointArray last;
        PointArray_init(&last);
        PointArray_add(&last, pixels->data[start_idx]);
        PointArray_add(&last, pixels->data[end_idx]);
        LineArray_add(&segments, &last);
    }
    return segments;
}


/*---------------------------------- MAIN + MEM FILE LOAD ----------------------------------*/

int main() {
    int edge_map[HEIGHT * WIDTH];
    load_mem("star_edge.mem", edge_map);
    LineArray linelist = edge_to_vect(edge_map);
    dump_line_array(&linelist, "vector.txt");
    LineArray mergedlist = merge_lines(&linelist);
    dump_line_array(&mergedlist, "merge.txt");
    LineArray douglas_list = doug_recurse(&mergedlist, 0.7);
    dump_line_array(&douglas_list, "douglas.txt");
    LineArray final_list = find_lines(&douglas_list);
    dump_line_array(&final_list, "segments.txt");



    LineArray_free(&mergedlist);
    LineArray_free(&linelist);
}

int load_mem(const char *filename, int edge_map[HEIGHT*WIDTH]){
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        printf("Error: Could not open file\n");
        return 1;
    }
    int index = 0;
    int ch;
    while ((ch = fgetc(fp)) != EOF && index < WIDTH * HEIGHT) {
        if (ch == '0' || ch == '1') {
            int y = index / WIDTH;
            int x = index % WIDTH;
            edge_map[y*WIDTH + x] = (ch == '1') ? 1 : 0;
            index++;
        }
        // ignore any '\n' or spaces
    }

    fclose(fp);
    FILE *fedge = fopen("edge_map.txt", "w");
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            fprintf(fedge, "%d", edge_map[y*WIDTH + x]);
        }
        fprintf(fedge, "\n");
    }

    fclose(fedge);
    return 1;
}
/*------------------------------------------------------------------------------------------*/

/*---------------------------------- VISUALIZATION CODE ----------------------------------*/
void dump_line_array(LineArray *lines, const char *filename) {
    FILE *fp = fopen(filename, "w");
    if (!fp) return;

    for (int i = 0; i < lines->size; i++) {
        PointArray *pa = &lines->lines[i];
        fprintf(fp, "#\n"); // marker for new polyline
        for (int j = 0; j < pa->size; j++) {
            fprintf(fp, "%d %d\n", pa->data[j].x, pa->data[j].y);
        }
    }

    fclose(fp);
}