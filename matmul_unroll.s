.text
.global matmul_asm_unroll

matmul_asm_unroll:
    ldr w3, [x0] //M
    ldr w4, [x0, #4] //K
    ldr w5, [x1, #4] //N
    ldr x6, [x0, #8] //a
    ldr x7, [x1, #8] //b
    ldr x8, [x2, #8] //c

    mov w9, #0 //i

.Lunroll_i:
    cmp w9, w3
    b.ge .Lunroll_done

    mov w10, #0 //j

.Lunroll_j:
    cmp w10, w5
    b.ge .Lunroll_next_i

    mov w11, #0 //k
    mov w12, #0 //accumulator :=0

.Lunroll_k4:
    add w13, w11, #3 //check whether k + 3 < K
    cmp w13, w4
    b.ge .Lunroll_tail

    mul w14, w9, w4
    add w14, w14, w11 //i*K + k
    add x15, x6, w14, uxtw #2
    ldr w16, [x15] //a[i][k]
    mul w14, w11, w5
    add w14, w14, w10 //k*N + j
    add x15, x7, w14, uxtw #2
    ldr w17, [x15] //b[k][j]
    mul w14, w16, w17
    add w12, w12, w14 //accumulator += a[i][k] * b[k][j]

    add w13, w11, #1
    mul w14, w9, w4
    add w14, w14, w13 //i*K + (k + 1)
    add x15, x6, w14, uxtw #2
    ldr w16, [x15] //a[i][k + 1]
    mul w14, w13, w5
    add w14, w14, w10 //(k + 1)*N + j
    add x15, x7, w14, uxtw #2
    ldr w17, [x15] //b[k + 1][j]
    mul w14, w16, w17
    add w12, w12, w14 //accumulator += a[i][k + 1] * b[k + 1][j]

    add w13, w11, #2
    mul w14, w9, w4
    add w14, w14, w13 //i*K + (k + 2)
    add x15, x6, w14, uxtw #2
    ldr w16, [x15] //a[i][k + 2]
    mul w14, w13, w5
    add w14, w14, w10 //(k + 2)*N + j
    add x15, x7, w14, uxtw #2
    ldr w17, [x15] //b[k + 2][j]
    mul w14, w16, w17
    add w12, w12, w14 //accumulator += a[i][k + 2] * b[k + 2][j]

    add w13, w11, #3
    mul w14, w9, w4
    add w14, w14, w13 //i*K + (k + 3)
    add x15, x6, w14, uxtw #2
    ldr w16, [x15] //a[i][k + 3]
    mul w14, w13, w5
    add w14, w14, w10 //(k + 3)*N + j
    add x15, x7, w14, uxtw #2
    ldr w17, [x15] //b[k + 3][j]
    mul w14, w16, w17
    add w12, w12, w14 //accumulator += a[i][k + 3] * b[k + 3][j]

    add w11, w11, #4 //k += 4
    b .Lunroll_k4

.Lunroll_tail:
    cmp w11, w4
    b.ge .Lunroll_store

    mul w14, w9, w4
    add w14, w14, w11 //i*K + k
    add x15, x6, w14, uxtw #2
    ldr w16, [x15] //a[i][k]

    mul w14, w11, w5
    add w14, w14, w10 //k*N + j
    add x15, x7, w14, uxtw #2
    ldr w17, [x15] //b[k][j]

    mul w14, w16, w17
    add w12, w12, w14 //accumulator += a[i][k] * b[k][j]

    add w11, w11, #1
    b .Lunroll_tail

.Lunroll_store:
    mul w14, w9, w5
    add w14, w14, w10 //i*N + j
    add x15, x8, w14, uxtw #2
    str w12, [x15] //c[i][j] = accumulator

    add w10, w10, #1
    b .Lunroll_j

.Lunroll_next_i:
    add w9, w9, #1
    b .Lunroll_i

.Lunroll_done:
    ret

