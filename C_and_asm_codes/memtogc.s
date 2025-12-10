addi $s0, $zero, 4096       # s0 = grid base address = 0x1000
addi $s4, $zero, 0          # s4 = run_count 

addi $t0, $zero, 50         # t0 = WIDTH = 50 pixels
addi $t1, $zero, 50         # t1 = HEIGHT = 50 rows
addi $t2, $zero, 200        # t2 = BYTES_PER_ROW = 50 * 4 = 200

addi $s6, $zero, 0          # s6 = x_offset (mm)
addi $s7, $zero, 0          # s7 = y_offset (mm)

addi $t6, $zero, 32736      # 0x7FE0: PREV_VALID address
sw   $zero, 0($t6)          # prev_valid = 0

addi $s1, $zero, 0          # s1 = y = 0 (current row)
addi $a0, $s0, 0            # a0 = row_base_addr = grid base (0x1000)

y_loop:
    # if y >= HEIGHT, go to done_rows
    blt  $s1, $t1, y_body   # if y < HEIGHT, continue to y_body
    j    done_rows          # else y >= HEIGHT, done

y_body:
    addi $s2, $zero, 0      # s2 = x = 0 (pixel coordinate)
    add  $s3, $a0, $zero    # s3 = pixel_ptr = row_base_addr

x_loop:
    # if x >= WIDTH, go to next_row
    blt  $s2, $t0, continue_x_loop  # if x < WIDTH, continue
    j    next_row           # else x >= WIDTH
    
continue_x_loop:
    # Load and quantize current pixel
    lw   $t3, 0($s3)        # t3 = raw pixel value
    addi $t6, $zero, 2      # threshold = 2
    blt  $t3, $t6, quant_done
    addi $t3, $t3, -14      # convert 16->2, 17->3

quant_done:
    # If pixel is zero (white), just advance
    bne  $t3, $zero, start_run  # if t3 != 0, start a run
    
    # White pixel: advance to next
    addi $s3, $s3, 4        # Advance pixel pointer by 4 bytes
    addi $s2, $s2, 1        # x++
    j    x_loop

start_run:
    # Found non-zero pixel: start a run
    add  $t4, $s2, $zero    # t4 = run_start_x
    add  $t5, $t3, $zero    # t5 = run_level
    
    addi $s3, $s3, 4        # Advance to next pixel (4 bytes)
    addi $s2, $s2, 1        # x++
    
    # Find end of run
find_run_end:
    # Check if x >= WIDTH (end of row)
    blt  $s2, $t0, continue_find  # if x < WIDTH, continue
    j    emit_run           # else x >= WIDTH, emit run
    
continue_find:
    # Load next pixel
    lw   $t6, 0($s3)        # t6 = next raw pixel
    
    # Quantize it
    addi $t7, $zero, 2
    blt  $t6, $t7, quant2_done
    addi $t6, $t6, -14

quant2_done:
    bne  $t6, $t5, emit_run # Different level -> end run
    
    # Same level: continue run
    addi $s3, $s3, 4        # Advance pointer
    addi $s2, $s2, 1        # x++
    j    find_run_end

emit_run:
    # Calculate coordinates (PIXEL_SIZE_MM = 1)
    add  $t7, $s7, $s1      # y_mm = y_offset + y
    add  $t8, $s6, $t4      # x_start_mm = x_offset + run_start_x
    add  $t9, $s6, $s2      # x_end_mm = x_offset + current_x
    
    # Skip if zero length (x_start == x_end)
    bne  $t8, $t9, check_dup  # if x_start != x_end, check duplicate
    j    x_loop             # else skip zero-length run

check_dup:
    # Duplicate check
    addi $t3, $zero, 32736  # PREV_VALID
    lw   $t6, 0($t3)
    bne  $t6, $zero, check_y_match  # if prev_valid != 0, check further
    j    do_send                     # else send (prev_valid == 0)
    j    check_y_match      # else check further

check_y_match:
    addi $t3, $zero, 32740  # PREV_Y
    lw   $t6, 0($t3)
    bne  $t7, $t6, do_send  # Different y, send
    
    addi $t3, $zero, 32744  # PREV_XS  
    lw   $t6, 0($t3)
    bne  $t8, $t6, do_send  # Different x_start, send
    
    addi $t3, $zero, 32748  # PREV_XE
    lw   $t6, 0($t3)
    bne  $t9, $t6, do_send  # Different x_end, send
    
    addi $t3, $zero, 32752  # PREV_LVL
    lw   $t6, 0($t3)
    bne  $t5, $t6, do_send  # Different level, send
    
    # All match -> duplicate, skip
    j    x_loop

do_send:
    # Wait for hardware
    addi $t3, $zero, 36884  # STATUS
wait_ready:
    lw   $t6, 0($t3)
    bne  $t6, $zero, wait_ready  # Wait while busy
    
    # Send data
    addi $t3, $zero, 36864  # RUN_Y
    sw   $t7, 0($t3)
    
    addi $t3, $zero, 36868  # RUN_X_START
    sw   $t8, 0($t3)
    
    addi $t3, $zero, 36872  # RUN_X_END
    sw   $t9, 0($t3)
    
    addi $t3, $zero, 36876  # RUN_LEVEL
    sw   $t5, 0($t3)
    
    # Trigger
    addi $t3, $zero, 36880  # CONTROL
    addi $t6, $zero, 1
    sw   $t6, 0($t3)
    
    # Update run count
    addi $s4, $s4, 1
    
    # Save as previous run
    addi $t3, $zero, 32740  # PREV_Y
    sw   $t7, 0($t3)
    
    addi $t3, $zero, 32744  # PREV_XS
    sw   $t8, 0($t3)
    
    addi $t3, $zero, 32748  # PREV_XE
    sw   $t9, 0($t3)
    
    addi $t3, $zero, 32752  # PREV_LVL
    sw   $t5, 0($t3)
    
    addi $t3, $zero, 32736  # PREV_VALID
    addi $t6, $zero, 1
    sw   $t6, 0($t3)
    
    j    x_loop

next_row:
    addi $s1, $s1, 1        # y++
    add  $a0, $a0, $t2      # row_base_addr += 200
    j    y_loop

done_rows:
    addi $t0, $zero, 32764  # 0x7FFC
    sw   $s4, 0($t0)        # store run_count

done:
    j    done