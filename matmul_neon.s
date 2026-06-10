.text
.align 2
.global matmul_asm_neon
.type matmul_asm_neon, %function

matmul_asm_neon:
    ldr w3, [x0]
    ldr w4, [x0, #4]
    ldr w5, [x1]
    ldr x6, [x0, #8]
    ldr x7, [x1, #8]
    ldr x8, [x2, #8]

    mov w9, wzr

.Lneon_i:
    cmp w9, w3
    b.ge .Lneon_done

    mul w13, w9, w4
    add x14, x6, w13, uxtw #2

    mul w13, w9, w5
    add x15, x8, w13, uxtw #2

    mov w10, wzr

.Lneon_j:
    cmp w10, w5
    b.ge .Lneon_next_i

    mul w13, w10, w4
    add x16, x7, w13, uxtw #2

    mov x17, x14
    mov w11, wzr
    movi v31.4s, #0

.Lneon_vec:
    add w13, w11, #3
    cmp w13, w4
    b.ge .Lneon_tail

    ld1 {v0.4s}, [x17]
    ld1 {v1.4s}, [x16]
    mul v2.4s, v0.4s, v1.4s
    add v31.4s, v31.4s, v2.4s

    add x17, x17, #16
    add x16, x16, #16
    add w11, w11, #4
    b .Lneon_vec

.Lneon_tail:
    addv s30, v31.4s
    fmov w12, s30

    cmp w11, w4
    b.ge .Lneon_store

.Lneon_scalar:
    ldr w13, [x17]
    ldr w0, [x16]
    mul w13, w13, w0
    add w12, w12, w13

    add x17, x17, #4
    add x16, x16, #4
    add w11, w11, #1
    cmp w11, w4
    b.lt .Lneon_scalar

.Lneon_store:
    add x13, x15, w10, uxtw #2
    str w12, [x13]

    add w10, w10, #1
    b .Lneon_j

.Lneon_next_i:
    add w9, w9, #1
    b .Lneon_i

.Lneon_done:
    ret

.size matmul_asm_neon, .-matmul_asm_neon
