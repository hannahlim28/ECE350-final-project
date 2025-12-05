# char line[MAX_LINE_LENGTH];
# while (fgets(line, sizeof(line), fin)) {
#         char *token = strtok(line, " \t\r\n");
#         int first_token = 1;

#         while (token) {
#             // Replace exact matches "010101" or "101010" with "000000"
#             if (strcmp(token, "010101") == 0 || strcmp(token, "101010") == 0) {
#                 token = "000000";
#             }
            
#             if (strcmp(token, "000000") == 0) {
#                 token = "0";
#             } else if (strcmp(token, "111111") == 0) {
#                 token = "1";
#             }

#             // Print a space before tokens after the first 
#             if (!first_token) {
#                 fputc(' ', fout);
#             }
#             fprintf(fout, "%s", token);

#             first_token = 0;
#             token = strtok(NULL, " \t\r\n");
#         }

#         // End the line in the output
#         fputc('\n', fout);
#     }

addi sp, sp, 16 

li t0, 200 
li t1, 200 

li t2, 800 


bne 








