    # Register allocation:
    # $s0 = grid base address (0x1000)
    # $s1 = y (current row)
    # $s2 = x (current column)
    # $s3 = byte address in current row
    # $s4 = run_count
    # $s5 = temp register for addresses/values
    # $s6 = x_offset
    # $s7 = y_offset
    # $t0 = width
    # $t1 = height
    # $t2 = bytes per row
    # $t3 = current pixel level
    # $t4 = run_start_x
    # $t5 = run_level
    # $t6 = temp (next level, run_end_x, etc.)
    # $t7 = temp (arithmetic, comparisons)
    # $t8 = x_start_mm
    # $t9 = x_end_mm
    # $a0 = row pointer

    addi $sp, $zero, 12288     # stack pointer = 0x3000
    addi $s0, $zero, 4096      # grid base address = 0x1000

    addi $s4, $zero, 0         # run_count = 0

    addi $t0, $zero, 100       # t0 = width
    addi $t1, $zero, 100       # t1 = height

    addi $t2, $zero, 400       # bytes per row = 100 pixels * 4 bytes

    addi $s6, $zero, 0         # s6 = x_offset
    addi $s7, $zero, 0         # s7 = y_offset

    addi $s1, $zero, 0         # s1 = y

    addi $a0, $s0, 0           # a0 = row pointer (start of row 0)

# Y LOOP (iterate through rows)
y_loop:
    blt  $s1, $t1, y_body       # if y < height, process row
    j    done_with_rows

y_body:
    addi $s3, $a0, 0            # s3 = byte address in this row
    addi $s2, $zero, 0          # s2 = x = 0

# X LOOP (iterate through columns)
x_loop:
    blt  $s2, $t0, x_body       # if x < width, process pixel
    j    next_row               # else go to next row

x_body:
    # Load current pixel level (0-3 stored as integer)
    lw   $t3, 0($s3)            # t3 = raw pixel word

    # Only divide by 8 if t3 > 15, otherwise keep as is
    addi $t6, $zero, 16         # t6 = 16
    blt  $t3, $t6, skip_div_t3  # if t3 < 16, skip division

    # Compute t3 / 8, with +1 if remainder
    addi $t7, $zero, 8          # t7 = 8
    addi $t6, $zero, 0          # t6 = quotient
    addi $a1, $zero, 0          # a1 = remainder
div8_t3_loop:
    blt  $t3, $t7, div8_t3_done # if t3 < 8, done dividing
    addi $t3, $t3, -8           # t3 -= 8
    addi $t6, $t6, 1            # quotient++
    j    div8_t3_loop
div8_t3_done:
    addi $a1, $t3, 0            # a1 = remainder (what's left in t3)
    addi $t3, $t6, 0            # t3 = quotient
    # If remainder != 0, add 1 to quotient
    bne  $a1, $zero, add_one_t3
    j    no_remainder_t3
add_one_t3:
    addi $t3, $t3, 1            # t3 = quotient + 1
no_remainder_t3:
    j    continue_x_body

skip_div_t3:
    # t3 stays as is
continue_x_body:

    addi $s3, $s3, 4            # advance to next word in memory
    addi $s2, $s2, 1            # x++

    # Start of a run at this pixel (any level 0-3)
    addi $t4, $s2, -1           # t4 = run_start_x = x - 1
    addi $t5, $t3, 0            # t5 = run_level = current level (0-3)

    j    find_end               # go extend the run

# Find the end of the run (same non-zero level, same row)
find_end:
    blt  $s2, $t0, fe_body      # while x < width
    j    end_run

fe_body:
    lw   $t6, 0($s3)            # t6 = next raw pixel word

    # Only divide by 8 if t6 > 15, otherwise keep as is
    addi $a2, $zero, 16         # a2 = 16
    blt  $t6, $a2, skip_div_t6  # if t6 < 16, skip division

    # Compute t6 / 8, with +1 if remainder
    addi $t7, $zero, 8          # t7 = 8
    addi $a2, $zero, 0          # a2 = quotient
    addi $a3, $zero, 0          # a3 = remainder
div8_t6_loop:
    blt  $t6, $t7, div8_t6_done # if t6 < 8, done dividing
    addi $t6, $t6, -8           # t6 -= 8
    addi $a2, $a2, 1            # quotient++
    j    div8_t6_loop
div8_t6_done:
    addi $a3, $t6, 0            # a3 = remainder (what's left in t6)
    addi $t6, $a2, 0            # t6 = quotient
    # If remainder != 0, add 1 to quotient
    bne  $a3, $zero, add_one_t6
    j    no_remainder_t6
add_one_t6:
    addi $t6, $t6, 1            # t6 = quotient + 1
no_remainder_t6:
    j    continue_find_end

skip_div_t6:
    # t6 stays as is
continue_find_end:

    bne  $t6, $t5, end_run      # if level changed, end of run

    addi $s3, $s3, 4            # move to next pixel word
    addi $s2, $s2, 1            # x++
    j    find_end

end_run:
    addi $t6, $s2, -1           # t6 = run_end_x

    # Compute coordinates (integer units, scaling applied later)
    add  $t7, $s7, $s1          # t7 = y_mm = y_offset + y
    add  $t8, $s6, $t4          # t8 = x_start_mm = x_offset + run_start_x
    add  $t9, $s6, $t6          # t9 = x_end_mm = x_offset + run_end_x

    # MMIO Interface: send run to G-code hardware module
    # Wait for hardware to be ready before sending

    # 1) Poll RUN_STATUS (0x9014) until ready (non-zero)
    addi $s5, $zero, 36884      # s5 = RUN_STATUS address (0x9014)

wait_ready_loop:
    lw   $t6, 0($s5)            # t6 = status
    bne  $t6, $zero, send_run   # if status != 0, ready to send
    j    wait_ready_loop        # else keep waiting

send_run:
   # 2) Write run data into MMIO registers

    addi $s5, $zero, 36864      # RUN_Y_MM (0x9000)
    sw   $t7, 0($s5)            # write y coordinate

    addi $s5, $zero, 36868      # RUN_X_START (0x9004)
    sw   $t8, 0($s5)            # write start x

    addi $s5, $zero, 36872      # RUN_X_END (0x9008)
    sw   $t9, 0($s5)            # write end x

    addi $s5, $zero, 36876      # RUN_LEVEL (0x900C)
    sw   $t5, 0($s5)            # write level (1-3 for grays, 0=skip)

    # 3) Trigger send via RUN_CONTROL (0x9010)
    addi $s5, $zero, 36880      # RUN_CONTROL address
    addi $t6, $zero, 1
    sw   $t6, 0($s5)            # write 1 to trigger send

    # 4) Increment run counter
    addi $s4, $s4, 1            # run_count++

    # Continue to next pixel (already advanced x in x_body and find_end)
    j    x_loop

# Move to next row
next_row:
    addi $s1, $s1, 1            # y++
    add  $a0, $a0, $t2          # row pointer += bytes per row
    j    y_loop

# Done processing all rows
done_with_rows:
    # Optional: store final run count to memory for debugging
    addi $t0, $zero, 32764      # 0x7FFC (high memory)
    sw   $s4, 0($t0)            # store run_count

done:
    j    done                   # infinite loop at end