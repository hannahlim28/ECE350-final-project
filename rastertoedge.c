#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Configuration constants
#define INPUT_MEM_FILE "plant.mem"
#define OUTPUT_MEM_FILE "plant_edge.mem"
#define MAX_LINE_LENGTH 4096

int main(void){
    FILE *fin  = fopen(INPUT_MEM_FILE, "r");
    FILE *fout = fopen(OUTPUT_MEM_FILE, "w");

char line[MAX_LINE_LENGTH];
while (fgets(line, sizeof(line), fin)) {
        char *token = strtok(line, " \t\r\n");
        int first_token = 1;

        while (token) {
            // Replace exact matches "010101" or "101010" with "000000"
            if (strcmp(token, "01") == 0 || strcmp(token, "10") == 0) {
                token = "00";
            }
            
            if (strcmp(token, "00") == 0) {
                token = "0";
            } else if (strcmp(token, "11") == 0) {
                token = "1";
            }

            // Print a space before tokens after the first 
            if (!first_token) {
                fputc(' ', fout);
            }
            fprintf(fout, "%s", token);

            first_token = 0;
            token = strtok(NULL, " \t\r\n");
        }

        // End the line in the output
        fputc('\n', fout);
    }

    fclose(fin);
    fclose(fout);

    printf("Done. Wrote cleaned mem file to %s\n", OUTPUT_MEM_FILE);
    return 0;
}