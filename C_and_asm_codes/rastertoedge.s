    # Input base
    addi    s0, zero, 0x1000   # s0 = INPUT base address

    # Output base 
    addi    s1, zero, 0x2000   # s1 = OUTPUT base address

    # Number of pixels (50 x 50 = 2500)
    addi    s2, zero, 2500     # s2 = # PIXELS

    # Pixel index i = 0
    addi    s3, zero, 0        # s3 = i = 0

pixel_loop:
    # if (i < #pixels) -> process; else -> done
    blt     s3, s2, pixel_body
    j       done

pixel_body:
    # Compute addresses for input and output pixels
    add     t0, s3, zero       # t0 = i
    add     t1, s0, t0         # t1 = INPUT_ADDR  = s0 + i
    add     t2, s1, t0         # t2 = OUTPUT_ADDR = s1 + i

    # Load input pixel value (0,1,2,3)
    lw      t3, 0(t1)          # t3 = in_val

    # out = (in_val == 3) ? 1 : 0
    addi    t4, zero, 3        # t4 = 3
    sub     t5, t3, t4         # t5 = t3 - 3
    bne     t5, zero, not_three

    # case in_val == 3
    addi    t3, zero, 1        # t3 = out = 1
    j       store_out

not_three:
    # case in_val != 3
    addi    t3, zero, 0        # t3 = out = 0

store_out:
    # Store output pixel
    sw      t3, 0(t2)          # *OUTPUT_ADDR = out

    # i++
    addi    s3, s3, 1          # s3 = s3 + 1

    # Next pixel
    j       pixel_loop

done:
    j       done               # spin forever
