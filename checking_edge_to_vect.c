#include <stdio.h>

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
/*------------------------------------------------------------------------------------------*/

/*---------------------------------- FUNCTION DECLARATIONS ---------------------------------*/


int load_mem(const char *filename, int edge_map[HEIGHT][WIDTH]);


/*------------------------------------------------------------------------------------------*/
/*--------------------------------------- BOUND CHECKING -----------------------------------*/
int in_bounds(int x, int y){
    return ((0<=x && x<WIDTH) &&(0<=y && y<HEIGHT));
}












/*---------------------------------- MAIN + MEM FILE LOAD ----------------------------------*/

int main() {
    int edge_map[HEIGHT][WIDTH];
    load_mem("star_edge.mem", edge_map);


}

int load_mem(const char *filename, int edge_map[HEIGHT][WIDTH]){
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
            edge_map[y][x] = (ch == '1') ? 1 : 0;
            index++;
        }
        // ignore any '\n' or spaces
    }

    fclose(fp);
    FILE *fedge = fopen("edge_map.txt", "w");
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            fprintf(fedge, "%d", edge_map[y][x]);
        }
        fprintf(fedge, "\n");
    }

    fclose(fedge);
    return 1;
}
/*------------------------------------------------------------------------------------------*/

