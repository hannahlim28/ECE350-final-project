    addi $sp, $zero, 12288      # stack pointer start = 0x3000
    addi $s0, $zero, 4096       # pixels base address = 0x1000

    addi $s4, $zero, 0          # run_count = 0

    addi $t0, $zero, 100        # t0 = width
    addi $t1, $zero, 100        # t1 = height

    addi $t2, $zero, 400        # bytes per row = 100 pixels * 4 bytes each

    addi $s6, $zero, 0          # s6 = x_offset
    addi $s7, $zero, 0          # s7 = y_offset

    addi $s1, $zero, 0          # s1 = y

    addi $a0, $s0, 0            # a0 = row pointer (start of row 0)

# Y LOOP (rows)
y_loop:
    blt  $s1, $t1, y_body       # if y < height, process row
    j    done_with_rows

y_body:
    addi $s3, $a0, 0            # s3 = byte address in this row
    addi $s2, $zero, 0          # s2 = x = 0

# X LOOP (columns)
x_loop:
    blt  $s2, $t0, x_body       # if x < width, process pixel
    j    next_row               # else, go to next row

x_body:
    # Load current pixel word for column x
    lw   $t3, 0($s3)            # t3 = raw pixel word (2-bit level in LSBs)

    # --------- DECODE LEVEL = LAST 2 BITS: t3 = t3 % 4 ---------
    addi $t7, $zero, 4          # t7 = 4
mod4_t3_loop:
    blt  $t3, $t7, mod4_t3_done # if t3 < 4, done
    addi $t3, $t3, -4           # t3 -= 4
    j    mod4_t3_loop
mod4_t3_done:
    # t3 is now 0,1,2,3 (decoded level from 2 lowest bits)
    # ------------------------------------------------------

    addi $s3, $s3, 4            # advance to next word in memory
    addi $s2, $s2, 1            # x++

    # Start a run at this pixel, for this level (including level 0 = white)
    addi $t4, $s2, -1           # t4 = run_start_x = x - 1
    addi $t5, $t3, 0            # t5 = run_level = this level (0..3)

    j    find_end               # go extend the run

# find the end of the run (same level, same row)
find_end:
    blt  $s2, $t0, fe_body      # while x < width
    j    end_run

fe_body:
    lw   $t6, 0($s3)            # t6 = next raw pixel word

    # --------- DECODE NEXT LEVEL = LAST 2 BITS: t6 = t6 % 4 ----
    addi $t7, $zero, 4          # t7 = 4
mod4_t6_loop:
    blt  $t6, $t7, mod4_t6_done # if t6 < 4, done
    addi $t6, $t6, -4           # t6 -= 4
    j    mod4_t6_loop
mod4_t6_done:
    # t6 is now 0,1,2,3
    # -----------------------------------------------------------

    bne  $t6, $t5, end_run      # if level changed → end of run

    addi $s3, $s3, 4            # move to next pixel word
    addi $s2, $s2, 1            # x++
    j    find_end

end_run:
    addi $t6, $s2, -1           # t6 = run_end_x

    # Compute coordinates in "mm units" (still integer, scaling later)
    add  $t7, $s7, $s1          # t7 = y_mm = y_offset + y
    add  $t8, $s6, $t4          # t8 = x_start_mm = x_offset + run_start_x
    add  $t9, $s6, $t6          # t9 = x_end_mm = x_offset + run_end_x

    #  MMIO: send run to G-code module 

    # 1) Wait until RUN_STATUS (36884 = 0x9014) says ready (non-zero)
    addi $s5, $zero, 36884      # s5 = RUN_STATUS address

wait_ready_loop:
    lw   $t6, 0($s5)            # t6 = status
    bne  $t6, $zero, ready      # if status != 0 => ready
    j    wait_ready_loop

ready:
    # 2) Write run data into MMIO registers
    addi $s5, $zero, 36864      # RUN_Y_MM  (0x9000)
    sw   $t7, 0($s5)

    addi $s5, $zero, 36868      # RUN_X_START (0x9004)
    sw   $t8, 0($s5)

    addi $s5, $zero, 36872      # RUN_X_END (0x9008)
    sw   $t9, 0($s5)

    addi $s5, $zero, 36876      # RUN_LEVEL (0x900C)
    sw   $t5, 0($s5)            # t5 is 0..3 (0 = white, 1..3 = grays)

    # 3) Trigger send via RUN_CONTROL (36880 = 0x9010)
    addi $s5, $zero, 36880      # RUN_CONTROL
    addi $t6, $zero, 1
    sw   $t6, 0($s5)            # write 1 to control

    # 4) Count this run
    addi $s4, $s4, 1            # run_count++

    j    x_loop                 # continue scanning pixels

# Move to next row 
next_row:
    addi $s1, $s1, 1            # y++
    add  $a0, $a0, $t2          # row pointer += bytes per row
    j    y_loop

# Done with all rows 
done_with_rows:
    addi $t0, $zero, 32764      # 0x7FFC
    sw   $s4, 0($t0)            # store run_count (optional/debug)

done:
    j    done                   # infinite loop at end
