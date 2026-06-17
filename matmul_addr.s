.text
.global matmul_asm_addr

matmul_asm_addr:
    ldr w3, [x0] //M
    ldr w4, [x0, #4] //K
    ldr w5, [x1, #4] //N
    ldr x6, [x0, #8] //a
    ldr x7, [x1, #8] //b
    ldr x8, [x2, #8] //c

    mov w9, #0 //i

.Laddr_i:
    cmp w9, w3
    b.ge .Laddr_done

    mul w13, w9, w4
    add x14, x6, w13, uxtw #2 //row_a := &a[i][0]

    mul w13, w9, w5
    add x15, x8, w13, uxtw #2 //row_c := &c[i][0]

    mov w10, #0 //j

.Laddr_j:
    cmp w10, w5
    b.ge .Laddr_next_i

    mov w12, #0 //accumulator :=0
    mov x13, x14 //cur_a := row_a
    add x16, x15, w10, uxtw #2 //dst := &c[i][j]
    add x17, x7, w10, uxtw #2 //cur_b := &b[0][j]
    mov w11, #0 //k

.Laddr_k:
    cmp w11, w4
    b.ge .Laddr_store

    ldr w0, [x13] //a[i][k]
    ldr w1, [x17] //b[k][j]
    mul w2, w0, w1
    add w12, w12, w2 //accumulator += a[i][k] * b[k][j]

    add x13, x13, #4 //advance to a[i][k + 1]
    add x17, x17, w5, uxtw #2 //advance to b[k + 1][j]
    add w11, w11, #1
    b .Laddr_k

.Laddr_store:
    str w12, [x16] //c[i][j] = accumulator

    add w10, w10, #1
    b .Laddr_j

.Laddr_next_i:
    add w9, w9, #1
    b .Laddr_i

.Laddr_done:
    ret

