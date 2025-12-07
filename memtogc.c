#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Configuration constants
#define INPUT_MEM_FILE "plant.mem"
#define OUTPUT_GCODE_FILE "plant.gcode"

#define PIXEL_SIZE_MM 0.5   // How many mm each pixel represents
#define CENTER_ON_ORIGIN 0  // 1 = center at (0,0), 0 = start at (0,0)
#define Z_UP_MM 2.0         // Height when pen is up (not drawing)
#define Z_DOWN_MM 0.0       // Height when pen is fully down (darkest)
#define FEED_RATE 1000.0    // Speed of movement in mm/min

#define MAX_GRID_HEIGHT 100
#define MAX_GRID_WIDTH  100
#define MAX_LINE_LENGTH 4096

// Bitmap struct: 2D grid of gray levels
// value 0 = white (skip), 1..3 = increasing darkness
typedef struct {
    int **grid;   // grid[row][col] = 0..3
    int height;   // number of rows actually used
    int width;    // number of columns actually used
} Bitmap;

static int parse_pixel_level(const char *token) {
    int b0 = (token[0] == '1') ? 1 : 0;
    int b1 = (token[1] == '1') ? 1 : 0;

    // 00 -> 0, 01 -> 1, 10 -> 2, 11 -> 3
    int level = (b0 << 1) | b1;   // 2*b0 + b1

    if (level < 0) level = 0;
    if (level > 3) level = 3;
    return level;
}

static double z_for_level(int level) {
  switch (level) {
        case 0: return 2.0;   // white 
        case 1: return 0.6;   // light gray
        case 2: return 0.3;   // medium gray
        case 3: return 0.0;   // black
        default: return 2.0;  // fallback
    }
}

// reads the .mem file and parses it into a 2D grid of gray levels
Bitmap read_mem_bitmap(const char *path) {
    Bitmap bitmap = {0}; // initialize all fields to 0/NULL
    FILE *f = fopen(path, "r");

    // Allocate memory for the 2D grid
    bitmap.grid = (int **)malloc(MAX_GRID_HEIGHT * sizeof(int *));

    for (int i = 0; i < MAX_GRID_HEIGHT; i++) {
        bitmap.grid[i] = (int *)malloc(MAX_GRID_WIDTH * sizeof(int));
        memset(bitmap.grid[i], 0, MAX_GRID_WIDTH * sizeof(int));
    }

    bitmap.height = 0;
    bitmap.width = 0;

    // Read file line by line
    char line[MAX_LINE_LENGTH];
    while (fgets(line, sizeof(line), f)) {
        // Skip leading whitespace
        char *start = line;
        while (isspace((unsigned char)*start)) start++;
        int col = 0;

        char *token = strtok(line, " \t\n\r");
        while (token && col < MAX_GRID_WIDTH) {
            int level = parse_pixel_level(token);  // 0..3

            bitmap.grid[bitmap.height][col] = level;
            col++;

            token = strtok(NULL, " \t\n\r");
        }

        // Only count this line if it had at least one token
        if (col > 0) {
            if (col > bitmap.width) {
                bitmap.width = col;
            }
            bitmap.height++;
        }
    }

    fclose(f);
    return bitmap;
}

// deallocate all memory used by the bitmap grid
void free_bitmap(Bitmap bitmap) {
    // free only the rows we actually allocated / used
    for (int i = 0; i < MAX_GRID_HEIGHT; i++) {
        free(bitmap.grid[i]);
    }
    free(bitmap.grid);
}

// converts the bitmap grid into G-code commands for the plotter/engraver.
void generate_gcode_from_grid(
    Bitmap bitmap,       // pixel grid (levels 0..3)
    double pixel_size_mm,
    int center_on_origin,
    double z_up,
    double z_down,
    double feed_rate,
    const char *output_path) {

    FILE *out = fopen(output_path, "w");
    int height = bitmap.height;
    int width = bitmap.width;

    // total drawing area in mm
    double draw_width_mm  = width  * pixel_size_mm;
    double draw_height_mm = height * pixel_size_mm;

    // offsets for X and Y coordinates
    double x_offset, y_offset;
    if (center_on_origin) {
        x_offset = -draw_width_mm  / 2.0;
        y_offset = -draw_height_mm / 2.0;
    } else {
        x_offset = 0.0;
        y_offset = 0.0;
    }

    // G-code header
    fprintf(out, "; Generated from %s\n", INPUT_MEM_FILE);
    fprintf(out, "; Image size: %d x %d pixels\n", width, height);
    fprintf(out, "; Center on origin: %s\n", center_on_origin ? "true" : "false");
    fprintf(out, "G21        ; mm units\n");
    fprintf(out, "G90        ; absolute coords\n");
    fprintf(out, "G0 Z%.3f   ; pen up\n", z_up);

    // Scan through the grid row by row (raster)
    for (int y = 0; y < height; y++) {
        int *row = bitmap.grid[y];
        int x = 0;

        while (x < width) {
            int level = row[x];

            // skip white pixels (level 0)
            if (level == 0) {
                x++;
                continue;
            }

            // We have a non-zero level -> start of a "run" with this gray level
            int run_start = x;
            int run_level = level;
            // Extend run while same non-zero level
            while (x < width && row[x] == run_level) {
                x++;
            }
            int run_end = x - 1;

            // Convert pixel coordinates to mm
            double x_start_mm = x_offset + run_start * pixel_size_mm;
            double x_end_mm   = x_offset + run_end   * pixel_size_mm;
            double y_mm       = y_offset + y * pixel_size_mm;

            double z_draw = z_for_level(run_level);

            // 1. Rapid move to start with pen up
            fprintf(out, "G0 X%.2f Y%.2f Z%.2f\n", x_start_mm, y_mm, z_up);
            // 2. Lower pen to appropriate gray-level height
            fprintf(out, "G1 Z%.2f F%.1f\n", z_draw, feed_rate);
            // 3. Draw line to end of run
            fprintf(out, "G1 X%.2f Y%.2f\n", x_end_mm, y_mm);
            // 4. Pen up again
            fprintf(out, "G0 Z%.2f\n", z_up);
        }
    }

    // Return to origin, pen up
    fprintf(out, "G0 Z%.3f\n", z_up);
    fprintf(out, "G0 X0.00 Y0.00\n");
    fprintf(out, "M2\n");

    fclose(out);
}

int main(void) {
    Bitmap grid = read_mem_bitmap(INPUT_MEM_FILE);

    generate_gcode_from_grid(
        grid,
        PIXEL_SIZE_MM,
        CENTER_ON_ORIGIN,
        Z_UP_MM,
        Z_DOWN_MM,
        FEED_RATE,
        OUTPUT_GCODE_FILE
    );

    printf("Done. Wrote %s\n", OUTPUT_GCODE_FILE);

    free_bitmap(grid);
    return 0;
}