#include <stdio.h>
#include <stdint.h>

#define INPUT_MEM_FILE    "plant.mem"
#define OUTPUT_GCODE_FILE "plant.gcode"

#define PIXEL_SIZE_MM     1
#define CENTER_ON_ORIGIN  0
#define Z_UP_MM           2.0
#define FEED_RATE         1000.0

#define GRID_WIDTH        50
#define GRID_HEIGHT       50

// Each pixel is a 32-bit word, just like in hardware memory
uint32_t grid[GRID_HEIGHT * GRID_WIDTH];

int grid_height = 0;
int grid_width  = GRID_WIDTH;

double z_for_level(uint32_t level) {
    if (level == 0) {
        return 2.0;
    } else if (level == 1) {
        return 0.6;
    } else if (level == 2) {
        return 0.3;
    } else if (level == 3) {
        return 0.0;
    }
    return 2.0;
}

void read_mem_bitmap(const char *path) {
    FILE *f;
    uint32_t value;
    int index = 0;

    f = fopen(path, "r");
    if (f == NULL) {
        printf("Error: Could not open %s\n", path);
        return;
    }

    // Read each 2-bit binary token and convert to integer
    // fscanf with %u would read decimal, so we read as string
    char token[16];
    while (fscanf(f, "%s", token) == 1) {
        if (index >= GRID_HEIGHT * GRID_WIDTH) {
            break;
        }

        // Convert binary string "00","01","10","11" to integer 0,1,2,3
        value = 0;
        int i = 0;
        while (token[i] == '0' || token[i] == '1') {
            value = (value << 1) | (token[i] - '0');
            i++;
        }

        // Store as 32-bit word (like hardware memory)
        grid[index] = value;
        index++;
    }

    fclose(f);
    grid_height = index / grid_width;

    printf("Read %d pixels into 32-bit words, grid: %d x %d\n", index, grid_width, grid_height);
}

uint32_t get_pixel(int row, int col) {
    return grid[row * grid_width + col];
}

void generate_gcode(void) {
    FILE *out;
    double x_offset;
    double y_offset;

    out = fopen(OUTPUT_GCODE_FILE, "w");
    if (out == NULL) {
        return;
    }

    if (CENTER_ON_ORIGIN == 1) {
        x_offset = -(grid_width * PIXEL_SIZE_MM) / 2.0;
        y_offset = -(grid_height * PIXEL_SIZE_MM) / 2.0;
    } else {
        x_offset = 0.0;
        y_offset = 0.0;
    }

    fprintf(out, "; Generated from %s\n", INPUT_MEM_FILE);
    fprintf(out, "; Image size: %d x %d pixels\n", grid_width, grid_height);
    fprintf(out, "G21\n");
    fprintf(out, "G90\n");
    fprintf(out, "G0 Z%.3f\n", Z_UP_MM);

    int y;
    int x;
    for (y = 0; y < grid_height; y++) {
        x = 0;

        while (x < grid_width) {
            uint32_t level = get_pixel(y, x);

            if (level == 0) {
                x++;
                continue;
            }

            int run_start = x;
            uint32_t run_level = level;

            while (x < grid_width && get_pixel(y, x) == run_level) {
                x++;
            }


            double x_start_mm = x_offset + run_start * PIXEL_SIZE_MM;
            double x_end_mm   = x_offset + x * PIXEL_SIZE_MM;
            double y_mm       = y_offset + y * PIXEL_SIZE_MM;
            double z_draw     = z_for_level(run_level);

            fprintf(out, "G0 X%.2f Y%.2f Z%.2f\n", x_start_mm, y_mm, Z_UP_MM);
            fprintf(out, "G1 Z%.2f F%.1f\n", z_draw, FEED_RATE);
            fprintf(out, "G1 X%.2f Y%.2f\n", x_end_mm, y_mm);
            fprintf(out, "G0 Z%.2f\n", Z_UP_MM);
        }
    }

    fprintf(out, "G0 Z%.3f\n", Z_UP_MM);
    fprintf(out, "G0 X0.00 Y0.00\n");
    fprintf(out, "M2\n");

    fclose(out);
}

int main(void) {
    read_mem_bitmap(INPUT_MEM_FILE);
    generate_gcode();
    printf("Done. Wrote %s\n", OUTPUT_GCODE_FILE);
    return 0;
}