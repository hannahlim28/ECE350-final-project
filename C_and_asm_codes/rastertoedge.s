#   0,1,2 -> 0
#   3     -> 1
#
# So: out = 1 if in == 3, else 0.

    addi    s0, zero, 0x1000   # s0 = INPUT base address
    addi    s1, zero, 0x2000   # s1 = OUTPUT base address

    addi    s2, zero, 25000    # s2 = # PIXELS
    addi    s3, zero, 0        # s3 = pixel index i = 0

pixel_loop:
    # if (i < # pixels) -> process; else -> done
    blt     s3, s2, pixel_body  # if s3 < s2, go to body
    j       done                # otherwise finished

pixel_body:
    # Compute addresses for input and output pixels
    add     t0, s3, zero       # t0 = i
    addi    t0, t0, 1           # t0 ++ 

    add     t1, s0, t0         # t1 = input address  
    add     t2, s1, t0         # t2 = output address 

    # Load input pixel value
    lw      t3, 0(t1)          # t3 = in_val (0,1,2,3)

    addi    t4, zero, 3        # t4 = 3

    # t5 = in_val - 3
    sub     t5, t3, t4         # t5 = t3 - 3

    # If t5 != 0, then in_val != 3 -> out = 0
    bne     t5, zero, not_three

    # Case in_val == 3:
    addi    t3, zero, 1        # t3 = out = 1
    j       store_out

not_three:
    # Case in_val != 3 (0,1,2):
    addi    t3, zero, 0        # t3 = out = 0

store_out:
    # Store output pixel
    sw      t3, 0(t2)          # output word = 0 or 1

    # i++
    addi    s3, s3, 1          # s3 = s3 + 1

    # Next pixel
    j       pixel_loop

done:
    j       done               # spin forever