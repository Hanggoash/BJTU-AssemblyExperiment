.text
.global matmul_asm_basic

matmul_asm_basic:
    ldr w3, [x0] //M
    ldr w4, [x0, #4] //K
    ldr w5, [x1, #4] //N
    ldr x6, [x0, #8] //a
    ldr x7, [x1, #8] //b
    ldr x8, [x2, #8] //c

    mov w9, #0 //i

.Louter_i:
    cmp w9, w3
    b.ge .Ldone

    mov w10, #0 //j

.Louter_j:
    cmp w10, w5
    b.ge .Lnext_i

    mov w11, #0 //k
    mov w12, #0 //accumulator :=0

.Linner_k:
    cmp w11, w4
    b.ge .Lstore

    mul w13, w9, w4
    add w13, w13, w11 //i*K + k
    add x14, x6, w13, uxtw #2
    ldr w15, [x14]

    mul w13, w11, w5
    add w13, w13, w10 //k*N + j
    add x14, x7, w13, uxtw #2 //extend to 64 bits and multiply 4
    ldr w16, [x14]

    mul w17, w15, w16
    add w12, w12, w17 //accumulator += a[i][k] * b[k][j]

    add w11, w11, #1
    b .Linner_k

.Lstore:
    mul w13, w9, w5
    add w13, w13, w10 //i*N + j
    add x14, x8, w13, uxtw #2
    str w12, [x14] //c[i][j] = accumulator

    add w10, w10, #1
    b .Louter_j

.Lnext_i:
    add w9, w9, #1
    b .Louter_i

.Ldone:
    ret

