    #---------------------------------------------------------
    # Bitmap → run-length MMIO sender for G-code hardware
    #
    # Register allocation:
    #   $s0 = grid base address (0x1000)
    #   $s1 = y (current row index)
    #   $s2 = x (current column index)
    #   $s3 = byte address within current row
    #   $s4 = run_count (debug)
    #   $s5 = MMIO address scratch
    #   $s6 = x_offset
    #   $s7 = y_offset
    #
    #   $t0 = width  (100)
    #   $t1 = height (100)
    #   $t2 = bytes per row (width * 4)
    #   $t3 = current pixel level (0–3)
    #   $t4 = run_start_x
    #   $t5 = run_level
    #   $t6 = temp (next level, run_end_x, etc.)
    #   $t7 = temp (loop arithmetic)
    #
    #   $t8 = x_start_mm (x_offset + run_start_x)
    #   $t9 = x_end_mm   (x_offset + run_end_x)
    #
    #   $a0 = row pointer (byte address of row start)
    #   $a1, $a2, $a3 = temps for division by 8 (quotient/remainder)
    #
    # Memory layout:
    #   Image pixels:  0x1000 .. (0x1000 + 100*100*4 - 1)
    #   MMIO:
    #     0x9000: RUN_Y
    #     0x9004: RUN_X_START
    #     0x9008: RUN_X_END
    #     0x900C: RUN_LEVEL
    #     0x9010: RUN_CONTROL (bit 0 = go)
    #     0x9014: RUN_STATUS  (non-zero = READY)
    #
    #---------------------------------------------------------

    addi $sp, $zero, 12288     # stack pointer = 0x3000 (if needed)
    addi $s0, $zero, 4096      # grid base address = 0x1000

    addi $s4, $zero, 0         # run_count = 0

    addi $t0, $zero, 100       # t0 = width
    addi $t1, $zero, 100       # t1 = height

    addi $t2, $zero, 400       # bytes per row = 100 pixels * 4 bytes

    addi $s6, $zero, 0         # x_offset = 0
    addi $s7, $zero, 0         # y_offset = 0

    addi $s1, $zero, 0         # y = 0

    addi $a0, $s0, 0           # a0 = row pointer (start of row 0)

y_loop:
    blt  $s1, $t1, y_body      # if y < height, process row
    j    done_with_rows        # else all rows done

y_body:
    addi $s3, $a0, 0           # s3 = byte address in this row
    addi $s2, $zero, 0         # s2 = x = 0

x_loop:
    blt  $s2, $t0, x_body      # if x < width, process pixel
    j    next_row              # else go to next row

x_body:
    # Load current pixel value (assumed 0..255 or 0..3) from memory
    lw   $t3, 0($s3)           # t3 = raw pixel word
    # Only divide if t3 >= 16; else keep as is
    addi $t6, $zero, 16        # t6 = 16
    blt  $t3, $t6, skip_div_t3 # if t3 < 16, skip division

    # Compute t3 / 8 with rounding up: ceil(t3 / 8)
    addi $t7, $zero, 8         # t7 = 8
    addi $t6, $zero, 0         # t6 = quotient
    addi $a1, $zero, 0         # a1 = remainder

div8_t3_loop:
    blt  $t3, $t7, div8_t3_done  # if t3 < 8, done dividing
    addi $t3, $t3, -8            # t3 -= 8
    addi $t6, $t6, 1             # quotient++
    j    div8_t3_loop

div8_t3_done:
    addi $a1, $t3, 0             # a1 = remainder (what's left in t3)
    addi $t3, $t6, 0             # t3 = quotient
    bne  $a1, $zero, add_one_t3  # if remainder != 0, round up
    j    no_remainder_t3

add_one_t3:
    addi $t3, $t3, 1             # t3 = quotient + 1

no_remainder_t3:
    j    continue_x_body

skip_div_t3:
    # t3 stays as is for small values

continue_x_body:
    #  next pixel in memory and x index
    addi $s3, $s3, 4           # s3 += 4 bytes (next word)
    addi $s2, $s2, 1           # x++

    # Start a run at this pixel:
    addi $t4, $s2, -1          # t4 = run_start_x = x - 1 (start of run)
    addi $t5, $t3, 0           # t5 = run_level   = current level 0..3

    j    find_end

# extend run while next pixels on row match level
find_end:
    blt  $s2, $t0, fe_body     # while x < width, check next pixel
    j    end_run               # else row boundary → end run

fe_body:
    lw   $t6, 0($s3)           # t6 = next raw pixel word

    # Quantize t6 similarly to t3 above
    addi $a2, $zero, 16        # a2 = 16
    blt  $t6, $a2, skip_div_t6 # if t6 < 16, skip division

    addi $t7, $zero, 8         # t7 = 8
    addi $a2, $zero, 0         # a2 = quotient
    addi $a3, $zero, 0         # a3 = remainder

div8_t6_loop:
    blt  $t6, $t7, div8_t6_done  # if t6 < 8, done dividing
    addi $t6, $t6, -8            # t6 -= 8
    addi $a2, $a2, 1             # quotient++
    j    div8_t6_loop

div8_t6_done:
    addi $a3, $t6, 0             # a3 = remainder
    addi $t6, $a2, 0             # t6 = quotient
    bne  $a3, $zero, add_one_t6  # round up if remainder != 0
    j    no_remainder_t6

add_one_t6:
    addi $t6, $t6, 1

no_remainder_t6:
    j    continue_find_end

skip_div_t6:
    # t6 stays as is

continue_find_end:
    bne  $t6, $t5, end_run    # if level changed, run ends here

    # else level is same: extend run
    addi $s3, $s3, 4          # next pixel word
    addi $s2, $s2, 1          # x++
    j    find_end

#we now have a run from x = t4 to x = (s2 - 1)
end_run:
    addi $t6, $s2, -1         # t6 = run_end_x

    add  $t7, $s7, $s1        # t7 = y_mm
    add  $t8, $s6, $t4        # t8 = x_start_mm
    add  $t9, $s6, $t6        # t9 = x_end_mm
    #runs for level 0 (pure white)
    bne  $t5, $zero, mmio_send
    j x_loop

mmio_send:
    # MMIO INTERFACE: send this run to the G-code hardware
    addi $s5, $zero, 36884    # s5 = 0x9014 (RUN_STATUS)

wait_ready_loop:
    lw   $t6, 0($s5)          # t6 = status
    bne  $t6, $zero, do_send
    j wait_ready_loop  # if 0, still busy → wait

    # 2) Write run parameters to MMIO registers
do_send: 
    addi $s5, $zero, 36864    # 0x9000: RUN_Y
    sw   $t7, 0($s5)          # y

    addi $s5, $zero, 36868    # 0x9004: RUN_X_START
    sw   $t8, 0($s5)          # x_start

    addi $s5, $zero, 36872    # 0x9008: RUN_X_END
    sw   $t9, 0($s5)          # x_end

    addi $s5, $zero, 36876    # 0x900C: RUN_LEVEL
    sw   $t5, 0($s5)          # level (1–3, or 0 if you didn't skip above)

    # 3) Trigger send via RUN_CONTROL (0x9010), bit 0 = 1
    addi $s5, $zero, 36880    # 0x9010: RUN_CONTROL
    addi $t6, $zero, 1
    sw   $t6, 0($s5)          # write 1 to "go"

    # 4) Increment run counter (debug)
    addi $s4, $s4, 1          # run_count++

    # Continue scanning this row (x, s3 already point after this run)
    j    x_loop

next_row:
    addi $s1, $s1, 1          # y++
    add  $a0, $a0, $t2        # row pointer += bytes per row
    j    y_loop

done_with_rows:
    # store run_count to memory for debugging
    addi $t0, $zero, 32764    # 0x7FFC 
    sw   $s4, 0($t0)          # store run_count

done:
    j    done                 # infinite loop at end
