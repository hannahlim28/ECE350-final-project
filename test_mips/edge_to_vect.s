nop
nop
nop
init:
addi $sp, $0, 10001
addi $a0, $0, 0
addi $a1, $0, 10400
# linelist size = 350 * 30
addi $a2, $0, 25400
addi $t0, $0, 1
addi $t1, $0, -1
# 1,0
lw $t0, 0($a2)
lw $0, 4($a2)
# 1,1
lw $t0, 8($a2)
lw $t0, 12($a2)
# 0,1
lw $0, 16($a2)
lw $t0, 20($a2)
# -1,1
lw $t1, 24($a2)
lw $t0, 28($a2)
#-1, 0 
lw $t1, 32($a2)
lw $0, 36($a2)
#-1,-1
lw $t1, 40($a2)
lw $t1, 44($a2)
#0, -1
lw $0, 48($a2)
lw $t1, 52($a2)
#1, -1
lw $t0, 56($a2)
lw $t1, 60($a2)
addi $a3, $0, 25464
jal edge_to_vect

#------------------------------------------- GRAB PIXELS ------------------------------------------#
# PARAMETERS: $a0 -> edge map pointer $a1 -> pointer to list $a2 -> pointer to directions array, $a3-> pointer to points allocation
edge_to_vect:
    addi $sp, $sp, -36
    # STACK SAVES --> a0, a1 X, Y, $ra, 
    sw $ra, 32($sp)
    sw $0,  12($sp)#x
    sw $0,  8($sp) #y
    sw $a0, 4($sp) #a0
    sw $a1, 0($sp) #a1
    sw $a2, 16($sp)#a2
    sw $a3, 28($sp)

    add $a0, $a1, $0
    jal linearr_init
    lw $a0, 4($sp)

y_loop:
    # GRAB Y and SET MAX
    addi $t0, $0, 99
    lw $s0, 8($sp)
    # IF Y>=99, then END LOOP
    blt $t0, $s0, edge_done
    # SET X = 0;
    sw $0, 12($sp)
x_loop:
    lw $s1, 12($sp)
    # SET MAX
    addi $t0, $0, 99
    # IF X >= 99, BRANCH
    blt $t0, $s1, y_incre
    # SET WIDTH/HEIGHT
    addi $t0, $0, 100
    # Y*WIDTH + X
    mul $t1, $t0, $s0
    add $t1, $t1, $s1
    # index = y*width + x *4
    sll $t1 , $t1, 2
    add $t1, $a0, $t1
    # grab edge_map[index]
    lw $t2, 0($t1)
    # X++
    addi $s1, $s1, 1
    # STORE X
    sw $s1, 12($sp)
    # IF EDGE_MAP[INDEX] != 1, LOOP X
    addi $t0, $0, 1
    bne $t2, $t0, x_loop
    # ELSE
    # SET EDGE_MAP[INDEX] = 0
    sw $0, 0($t1)
    # GRAB SIZE OF LIST ARRAY
    lw $t1, 0($a1)
    # ADD PROJECTED PIXEL ARRAY SIZE
    addi $t2, $0, 404 #8*50 + 4
    # INDEX = SIZE OF LIST ARRAY * PROJECTED ARRAY SIZE
    mul $t1, $t1, $t2
    # SET PARAMETER = POINT_ARRAY[INDEX]
    add $a0, $a3, $t1
    # INITIALIZE
    jal pointarr_init
    add $s4, $0, $a0
    # SET X, Y PARAMETERS
    add $a1, $0, $s1
    add $a2, $0, $s0
    # ADD POINT
    jal pointarr_add
    sw $a0, 28($sp)
    lw $a0, 4($sp)
    lw $a1, 0($sp)
    lw $a2, 16($sp)
    # ADD POINTER TO LINE ARRAY
    # GRAB SIZE OF LIST ARRAY
    lw $t1, 0($a1)
    # ADD PROJECTED PIXEL ARRAY SIZE
    addi $t2, $0, 404 #8*50 + 4
    # INDEX = SIZE OF LIST ARRAY * PROJECTED ARRAY SIZE
    mul $t1, $t1, $t2
    # SET PARAMETER = POINT_ARRAY[INDEX]
    add $a0, $0, $a1
    add $a1, $a3, $t1
    jal linearr_add
    lw $a0, 4($sp)
    lw $a1, 0($sp)
    # set px, py
    add $t1, $s1, $0
    add $t2, $s0, $0
    sw $t1, 20($sp) #s2 = px
    sw $t2, 24($sp) #s3 = py
# WHILE LOOP
while_can:
    lw $s2, 20($sp)
    lw $s3, 24($sp)
# CREATE INDEX
    addi $t3, $0, 0
# FOR LOOP
for_dirs:
    # MAX = 7
    addi $t0, $0, 7
    # IF d > 7 end for loop
    blt $t0, $t3, x_loop
    # index * 8
    sll $t4, $t3, 3
    # DIRS_INDEX + index*8
    add $t4, $t4, $a2
    # INDEX ++
    addi $t3, $t3, 1
    # GRAB DIR[DIRS_INDEX] x and y
    lw $t5, 0($t4)
    lw $t6, 4($t4)
    # GRAB px = x, py = y
    lw $s2, 20($sp)
    lw $s3, 24($sp)
    # next.x = px+ dirx next.y = py + diry
    add $t7, $t5, $s2
    add $t8, $t6, $s3
    # load parameters, nextx, nexty
    add $a0, $0, $t7
    add $a1, $0, $t8
    jal in_bounds
    lw $a0, 4($sp)
    lw $a1, 0($sp)
    # check if in_bounds returned 1
    addi $t0, $0, 1
    bne $v0, $t0, for_dirs
    # nexty * index + nextx
    addi $t0, $0, 100
    mul $t5, $t8, $t0
    add $t5, $t5, $t7
    sll $t5, $t5, 2
    add $t5, $a0, $t5
    # edge_map[nexty * index + nextx]
    lw $t6, 0($t5) 
    # check if 1
    addi $t0, $0, 1
    bne $t0, $t6, for_dirs
    # SET X, Y PARAMETERS
    lw $s4, 28($sp)
    add $a0, $0, $s4
    add $a1, $0, $t7
    add $a2, $0, $t8
    jal pointarr_add
    lw $a0, 4($sp)
    lw $a1, 0($sp)
    lw $a2, 16($sp)
    # change px and py to nextx and nexty
    add $s2, $0, $t7
    add $s3, $0, $t8
    sw $s2, 20($sp)
    sw $s3, 24($sp)
    # change edge_map[nexty * index + nextx] to 0
    sw $0, 0($t5)
    j while_can
y_incre:
    addi $s0, $s0, 1
    sw $s0, 8($sp)
    j y_loop
    lw $a0, 4($sp)
    lw $a1, 0($sp)
edge_done:
    add $v0, $0, $a1
    lw $a1, 0($sp)
    lw $a0, 4($sp)
    lw $s0, 8($sp)
    lw $s1, 12($sp)
    lw $a2, 16($sp)
    lw $a3, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra
    
#------------------------------------------ REVERSE ARRAY -----------------------------------------#
reverse_array:
    addi $sp, $sp, -4
    sw $ra 0($sp)
    # GRAB DATA and SIZE
    lw $t0, 0($a0)
    lw $t1, 4($a0)
    # int left = 0 (t2 = left)
    # int right = size - 1 (t1 = right/size)
    addi $t2, $0, 0
    addi $t1, $t1, -1
    # START LOOP
rev_loop:
    # t2 = left, t1 = right
    # if t1 < t2, end loop
    blt $t1, $t2, rev_done
    # left index * 8
    # data[left_index *8]
    sll $t3, $t2, 3
    add $t3, $t3, $t0
    # right index *8
    # data[right_index *8]
    sll $t4, $t1, 3
    add $t4, $t4, $t0
    # data[left]
    lw $t5, 0($t3)
    lw $t6, 4($t3)
    # data[right]
    lw $t7, 0($t4)
    lw $t8, 4($t4)
    # data[left] = data[right]
    sw $t7, 0($t3)
    sw $t8, 4($t3)
    # data[right] = prev data[left]
    sw $t5, 0($t4)
    sw $t6, 4($t4)
    # left ++, right --
    addi $t2, $t2, 1
    addi $t1, $t1, -1
    # loop back
    j rev_loop
rev_done:
    lw $ra 0($sp)
    addi $sp, $sp, 4
    jr $ra


#--------------------------------------- PERPENDICULAR DISTANCE -----------------------------------#
perp_distance:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # a0 = x0, a1 = x1, a2 = y0, a3 = y1, a4 = xf, a5 = yf
    # dx = x1 - x0
    sub $t0, $a1, $a0
    # dy = y1 - y0
    sub $t1, $a3, $a2

    # dfx = xf - x0
    sub $t2, $s0, $a0
    #dfy = yf - y0
    sub $t3, $s1, $a2

    # dx || dy (should be 0 if both are 0)
    or $s0, $t0, $t1
    bne $s0, $0, perp_cont

    # dfx * dfx
    mul $s1, $t2, $t2
    # dfy * dfy
    mul $s2, $t3, $t3
    #return (dfx*dfx) + (dfy*dfy)
    add $v0, $s1, $s2
    lw $ra 0($sp)
    addi $sp, $sp, 4
    jr $ra

perp_cont:
    # sqrt = dy*dfx - dx*dfy
    mul $t7, $t1, $t2
    mul $t8, $t0, $t3
    sub $t7, $t7, $t8
    # dist = sqrt *sqrt
    mul $t9, $t7, $t7
    # length = dx*dx + dy*dy
    mul $t4, $t0, $t0
    mul $t5, $t1, $t1
    add $t4, $t4, $t5
    # return dist/length
    div $v0, $t9, $t4
    lw $ra 0($sp)
    addi $sp, $sp, 4
    jr $ra

# --------------------------------------- BOUND CHECKING ----------------------------------- #
in_bounds:
    addi $sp, $sp, -4
    sw $ra 0($sp)
    # SET TO COMPARISON VALUE (100)
    addi $t0, $0, 100
    # CHECK IF X >= 0, IF SO OUT OF BOUNDS
    blt $a0, $0, out_of_bounds
    # CHECK IF X < 100, IF SO OUT OF BOUNDS
    blt $t0, $a0, out_of_bounds

    # CHECK IF Y >= 0, IF SO OUT OF BOUNDS
    blt $a1, $0, out_of_bounds
    # CHECK IF Y < 100, IF SO OUT OF BOUNDS
    blt $t0, $a1, out_of_bounds

    # IF PASSING EVERYTHING SET TO 1
    addi $v0,$0, 1
    # RETURN
    lw $ra 0($sp)
    addi $sp, $sp, 4
    jr $ra
out_of_bounds:
    # IF OUT OF BOUNDS SET TO 0
    addi $v0, $0, 0
    # RETURN
    lw $ra 0($sp)
    addi $sp, $sp, 4
    jr $ra
pointarr_init:
    sw $0, 0($a0)
    jr $ra
pointarr_add:
    # a0 = pointer to point array, a1 = x, a2 = y
    lw $t0, 0($a0)
    sll $t1, $t0, 3
    addi $t1, $t1, 4
    add $t1, $t1, $a0
    sw $a1, 0($t1)
    sw $a2, 4($t1)
    addi $t0, $t0, 1
    sw $t0, 0($a0)
    jr $ra
linearr_init:
    sw $0, 0($a0)
    jr $ra
linearr_add:
    # a0 = pointer to line array, a1 = pointer to point array
    lw $t0, 0($a0)
    sll $t1,$t0, 2
    addi $t1, $t1, 4
    add $t1, $t1, $a0
    sw $a1, 0($t1)
    addi $t0, $t0, 1
    sw $t0, 0($a0)
    jr $ra
