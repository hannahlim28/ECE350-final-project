    addi $s0, $zero, 4096       # s0 = grid base address = 0x1000
    addi $s4, $zero, 0          # s4 = pixel counter

    addi $t0, $zero, 50         # t0 = WIDTH = 50 pixels
    addi $t1, $zero, 50         # t1 = HEIGHT = 50 rows
    addi $t2, $zero, 200        # t2 = BYTES_PER_ROW = 50 * 4 = 200

    addi $s6, $zero, 0          # s6 = x_offset (mm)
    addi $s7, $zero, 0          # s7 = y_offset (mm)
    addi $s1, $zero, 0          # s1 = y = 0 (row)
    addi $a0, $s0, 0            # a0 = row base pointer

y_loop:
    blt  $t1, $s1, done_rows
    j    done_rows

y_body:
    addi $s2, $zero, 0          # s2 = x = 0
    addi $s3, $a0, 0            # s3 = pixel pointer

x_loop:
    blt  $s2, $t0, x_body
    j    next_row

x_body:
    lw   $t3, 0($s3)            # t3 = pixel level (0..3)

    # compute coordinates 
    add  $t7, $s7, $s1          # y_mm = y_offset + y
    add  $t8, $s6, $s2          # x_start_mm = x_offset + x
    addi $t9, $t8, 1            # x_end_mm = x_start_mm + 1

    # advance to next pixel
    addi $s3, $s3, 4           # move to next pixel word
    addi $s2, $s2, 1            # x++

    # wait until hardware is ready
wait_ready:
    addi $s5, $zero, 36884      # 0x9014: STATUS
    lw   $t6, 0($s5)
    bne  $t6, $zero, wait_ready

    # write pixel (Y, Xstart, Xend, Level)
    addi $s5, $zero, 36864      # 0x9000
    sw   $t7, 0($s5)
    addi $s5, $zero, 36868      # 0x9004
    sw   $t8, 0($s5)
    addi $s5, $zero, 36872      # 0x9008
    sw   $t9, 0($s5)
    addi $s5, $zero, 36876      # 0x900C
    sw   $t3, 0($s5)

    # trigger send
    addi $s5, $zero, 36880      # 0x9010
    addi $t6, $zero, 1
    sw   $t6, 0($s5)

    addi $s4, $s4, 1
    j    x_loop

next_row:
    addi $s1, $s1, 1
    add  $a0, $a0, $t2
    j    y_loop

done_rows:
    addi $t0, $zero, 32764
    sw   $s4, 0($t0)

done:
    j    done
