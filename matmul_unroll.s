.text
.align 2
.global matmul_asm_unroll
.type matmul_asm_unroll, %function

matmul_asm_unroll:
    ldr w3, [x0]
    ldr w4, [x0, #4]
    ldr w5, [x1, #4]
    ldr x6, [x0, #8]
    ldr x7, [x1, #8]
    ldr x8, [x2, #8]

    mov w9, wzr

.Lunroll_i:
    cmp w9, w3
    b.ge .Lunroll_done

    mov w10, wzr

.Lunroll_j:
    cmp w10, w5
    b.ge .Lunroll_next_i

    mov w11, wzr
    mov w12, wzr

.Lunroll_k4:
    add w13, w11, #3
    cmp w13, w4
    b.ge .Lunroll_tail

    mul w14, w9, w4
    add w14, w14, w11
    add x15, x6, w14, uxtw #2
    ldr w16, [x15]
    mul w14, w11, w5
    add w14, w14, w10
    add x15, x7, w14, uxtw #2
    ldr w17, [x15]
    mul w14, w16, w17
    add w12, w12, w14

    add w13, w11, #1
    mul w14, w9, w4
    add w14, w14, w13
    add x15, x6, w14, uxtw #2
    ldr w16, [x15]
    mul w14, w13, w5
    add w14, w14, w10
    add x15, x7, w14, uxtw #2
    ldr w17, [x15]
    mul w14, w16, w17
    add w12, w12, w14

    add w13, w11, #2
    mul w14, w9, w4
    add w14, w14, w13
    add x15, x6, w14, uxtw #2
    ldr w16, [x15]
    mul w14, w13, w5
    add w14, w14, w10
    add x15, x7, w14, uxtw #2
    ldr w17, [x15]
    mul w14, w16, w17
    add w12, w12, w14

    add w13, w11, #3
    mul w14, w9, w4
    add w14, w14, w13
    add x15, x6, w14, uxtw #2
    ldr w16, [x15]
    mul w14, w13, w5
    add w14, w14, w10
    add x15, x7, w14, uxtw #2
    ldr w17, [x15]
    mul w14, w16, w17
    add w12, w12, w14

    add w11, w11, #4
    b .Lunroll_k4

.Lunroll_tail:
    cmp w11, w4
    b.ge .Lunroll_store

    mul w14, w9, w4
    add w14, w14, w11
    add x15, x6, w14, uxtw #2
    ldr w16, [x15]

    mul w14, w11, w5
    add w14, w14, w10
    add x15, x7, w14, uxtw #2
    ldr w17, [x15]

    mul w14, w16, w17
    add w12, w12, w14

    add w11, w11, #1
    b .Lunroll_tail

.Lunroll_store:
    mul w14, w9, w5
    add w14, w14, w10
    add x15, x8, w14, uxtw #2
    str w12, [x15]

    add w10, w10, #1
    b .Lunroll_j

.Lunroll_next_i:
    add w9, w9, #1
    b .Lunroll_i

.Lunroll_done:
    ret

.size matmul_asm_unroll, .-matmul_asm_unroll
