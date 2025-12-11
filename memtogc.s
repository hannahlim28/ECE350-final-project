    # s0 = grid base 
    addi $s0, $zero, 4096       

    # s4 = run_count
    addi $s4, $zero, 0          

    # t0 = WIDTH = 50 pixels
    addi $t0, $zero, 50         

    # t1 = HEIGHT = 50 rows
    addi $t1, $zero, 50         

    # x_offset, y_offset in mm (currently 0)
    addi $s6, $zero, 0          
    addi $s7, $zero, 0          

    # s1 = y = 0 (current row)
    addi $s1, $zero, 0          

    # s3 = pixel
    add  $s3, $s0, $zero        

y_loop:
    # if y >= HEIGHT, go to done_rows
    blt  $s1, $t1, y_body       # if y < HEIGHT, continue to y_body
    j    done_rows              # else y >= HEIGHT, done

y_body:
    # s2 = x = 0 (pixel coordinate in this row)
    addi $s2, $zero, 0          

x_loop:
    # if x >= WIDTH, go to next_row
    blt  $s2, $t0, continue_x_loop
    j    next_row

continue_x_loop:
    # Load and quantize current pixel
    lw   $t3, 0($s3)            # t3 = raw pixel value

    # Quantize: if t3 >= 2, map 16->2, 17->3 (rest stay 0/1)
    addi $t6, $zero, 2          # threshold = 2
    blt  $t3, $t6, quant_done
    addi $t3, $t3, -14          # convert 16->2,17->3

quant_done:
    # If pixel is zero (white), just advance
    bne  $t3, $zero, start_run  # if t3 != 0, start a run
    
    # White pixel: advance to next
    addi $s3, $s3, 1            # pixel += 1 (next pixel)
    addi $s2, $s2, 1            # x++
    j    x_loop

start_run:
    # Found non-zero pixel: start a run
    add  $t4, $s2, $zero        # t4 = run_start_x
    add  $t5, $t3, $zero        # t5 = run_level
    
    # Move to next pixel
    addi $s3, $s3, 1            # pixel += 1
    addi $s2, $s2, 1            # x++
    
    # Find end of run
find_run_end:
    # Check if x >= WIDTH (end of row)
    blt  $s2, $t0, continue_find
    j    emit_run               # reached row end: emit run
    
continue_find:
    # Load next pixel
    lw   $t6, 0($s3)            # t6 = next raw pixel
    
    # Quantize next pixel
    addi $t7, $zero, 2
    blt  $t6, $t7, quant2_done
    addi $t6, $t6, -14

quant2_done:
    # If level changes, run ends
    bne  $t6, $t5, emit_run
    
    # Same level: extend run
    addi $s3, $s3, 1            # pixel += 1
    addi $s2, $s2, 1            # x++
    j    find_run_end

emit_run:
    # Calculate coordinates (PIXEL_SIZE_MM = 1)
    add  $t7, $s7, $s1          # y_mm       = y_offset + y
    add  $t8, $s6, $t4          # x_start_mm = x_offset + run_start_x
    add  $t9, $s6, $s2          # x_end_mm   = x_offset + current_x
    
    # Skip if zero length (x_start == x_end)
    bne  $t8, $t9, do_send      # if x_start != x_end, send
    j    x_loop                 # else skip zero-length run

do_send:
    # Wait for hardware ready
    addi $t3, $zero, 36884      # STATUS addr
wait_ready:
    lw   $t6, 0($t3)
    bne  $t6, $zero, wait_ready # wait while busy != 0
    
    # Send Y
    addi $t3, $zero, 36864      # RUN_Y
    sw   $t7, 0($t3)
    
    # Send X_START
    addi $t3, $zero, 36868      # RUN_X_START
    sw   $t8, 0($t3)
    
    # Send X_END
    addi $t3, $zero, 36872      # RUN_X_END
    sw   $t9, 0($t3)
    
    # Send LEVEL
    addi $t3, $zero, 36876      # RUN_LEVEL
    sw   $t5, 0($t3)
    
    # Trigger hardware
    addi $t3, $zero, 36880      # CONTROL
    addi $t6, $zero, 1
    sw   $t6, 0($t3)
    
    # Update run count
    addi $s4, $s4, 1
    
    # Continue scanning row
    j    x_loop

next_row:
    addi $s1, $s1, 1            # y++
    j    y_loop                 # pixel already at next row 

done_rows:
    # Store run_count at 0x7FFC (32764)
    addi $t0, $zero, 32764      
    sw   $s4, 0($t0)            # store run_count

done:
    j    done                   # spin forever
