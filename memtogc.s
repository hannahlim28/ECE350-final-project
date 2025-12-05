addi sp, zero, 0x3000 # intializing where in memory with stack will start 
addi s0, zero, 0x1000   # where pixels live in bytes 
addi s5, zero, 0x8000   # where we store runs of 1 
nop
addi s4, zero, 0 # run count = 0 
nop
addi t0, zero, 500  # t0 = width 
addi t1, zero, 500  # t1 = length 
nop
addi t2, zero, 2000  # t2 = how many bytes are in every row 
nop
addi s6, zero, -250  # s6 = x_offset 
addi s7, zero, -250  # s7 = y_offset 
nop
addi s1, zero, 0  # s1 = y 
nop
addi s8, s0, 0 # s8 = here is where row 0 starts 
nop
y_loop: 
blt s1, t1, y_body #if y< height 
j done_with_rows
nop
y_body: 
addi s3, s8, 0  #s3 = byte address right now 
addi s2, zero, 0  # x=0 
nop
x_loop: 
blt s2, t0, x_body
j next_row #if x< width, got to next row
nop
x_body: 
lw t3, 0(s3) #t3 = level 
addi s3, s3,4  #add 4 bytes (or one pixel) to the row position 
addi s2, s2, 1  #x++ 
nop
bne t3, zero, not_white
j x_loop 
nop
not_white: 
addi t4, s2, -1 #t4 = start run cause we saw a non zero at x-1 postition 
addi t5, t3, 0 #t5 = run_level = this level 
nop
find_end: 
blt s2, t0, fe_body
j end_run
nop
fe_body:
lw t6, 0(s3)  # t6 = next level 
bne t6, t5, end_run # if level ! = next_level -> end_run 
nop
addi s3, s3,4  #add 4 bytes (or one pixel) to the row position 
addi s2, s2, 1  #x++ 
j find_end
nop
end_run: 
addi t6, s2, -1  #t6 = end x run 
nop
nop
add t7, s7, s1   #t7 = y_mm = y_offset + y 
add t8, s6, t4   #t8 = x_start_mm = x_offset + run_start_x
add t9, s6, t6   #t9 = x_end_mm 
nop
sw  t7,  0(s5)#store [ y_mm, x_start_mm, x_end_mm, run_level] at s5
sw  t8,  4(s5) 
sw  t9,  8(s5)
sw  t5, 12(s5)
nop
addi  s5, s5, 16 # move pointer to next address
nop
addi s4, s4, # run_count++ 
j x_loop 
nop
next_row: # after finishing a row, y++ 
addi s1,s1,1
add s8,s8,t2 
j y_loop 
nop
done_with_rows: # all rows done 
addi t0,zero, 0x7FFC
sw s4, 0(t0)
nop
done: 
j done 