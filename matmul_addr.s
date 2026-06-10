.text
.align 2
.global matmul_asm_addr
.type matmul_asm_addr, %function

matmul_asm_addr:
    ldr w3, [x0]
    ldr w4, [x0, #4]
    ldr w5, [x1, #4]
    ldr x6, [x0, #8]
    ldr x7, [x1, #8]
    ldr x8, [x2, #8]

    mov w9, wzr

.Laddr_i:
    cmp w9, w3
    b.ge .Laddr_done

    mul w13, w9, w4
    add x14, x6, w13, uxtw #2

    mul w13, w9, w5
    add x15, x8, w13, uxtw #2

    mov w10, wzr

.Laddr_j:
    cmp w10, w5
    b.ge .Laddr_next_i

    mov w12, wzr
    mov x13, x14
    add x16, x15, w10, uxtw #2
    add x17, x7, w10, uxtw #2
    mov w11, wzr

.Laddr_k:
    cmp w11, w4
    b.ge .Laddr_store

    ldr w0, [x13]
    ldr w1, [x17]
    mul w2, w0, w1
    add w12, w12, w2

    add x13, x13, #4
    add x17, x17, w5, uxtw #2
    add w11, w11, #1
    b .Laddr_k

.Laddr_store:
    str w12, [x16]

    add w10, w10, #1
    b .Laddr_j

.Laddr_next_i:
    add w9, w9, #1
    b .Laddr_i

.Laddr_done:
    ret

.size matmul_asm_addr, .-matmul_asm_addr
