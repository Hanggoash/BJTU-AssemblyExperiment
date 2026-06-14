.text
.global matmul_asm_neon

matmul_asm_neon:
    ldr w3, [x0] //M
    ldr w4, [x0, #4] //K
    ldr w5, [x1] //N (= BT.rows = B.cols)
    ldr x6, [x0, #8] //a
    ldr x7, [x1, #8] //bt
    ldr x8, [x2, #8] //c

    mov w9, #0 //i

.Lneon_i:
    cmp w9, w3
    b.ge .Lneon_done

    mul w13, w9, w4
    add x14, x6, w13, uxtw #2 //row_a := &a[i][0]

    mul w13, w9, w5
    add x15, x8, w13, uxtw #2 //row_c := &c[i][0]

    mov w10, #0 //j

.Lneon_j:
    cmp w10, w5
    b.ge .Lneon_next_i

    mul w13, w10, w4
    add x16, x7, w13, uxtw #2 //row_bt := &bt[j][0] (= B column j)

    mov x17, x14 //cur_a := row_a
    mov w11, #0 //k
    movi v31.4s, #0 //vec_acc := {0, 0, 0, 0}

.Lneon_vec:
    add w13, w11, #3 //check whether k + 3 < K
    cmp w13, w4
    b.ge .Lneon_tail

    ld1 {v0.4s}, [x17] //load a[i][k : k + 3]
    ld1 {v1.4s}, [x16] //load bt[j][k : k + 3]
    mul v2.4s, v0.4s, v1.4s
    add v31.4s, v31.4s, v2.4s //vec_acc += a_row * bt_row

    add x17, x17, #16 //advance 4 ints in a row
    add x16, x16, #16 //advance 4 ints in bt row
    add w11, w11, #4 //k += 4
    b .Lneon_vec

.Lneon_tail:
    addv s30, v31.4s //horizontal sum of vec_acc
    fmov w12, s30 //accumulator := horizontal sum

    cmp w11, w4
    b.ge .Lneon_store

.Lneon_scalar:
    ldr w13, [x17] //a[i][k]
    ldr w0, [x16] //bt[j][k] (= b[k][j])
    mul w13, w13, w0
    add w12, w12, w13 //accumulator += a[i][k] * bt[j][k]

    add x17, x17, #4 //advance to a[i][k + 1]
    add x16, x16, #4 //advance to bt[j][k + 1]
    add w11, w11, #1
    cmp w11, w4
    b.lt .Lneon_scalar

.Lneon_store:
    add x13, x15, w10, uxtw #2 //dst := &c[i][j]
    str w12, [x13] //c[i][j] = accumulator

    add w10, w10, #1
    b .Lneon_j

.Lneon_next_i:
    add w9, w9, #1
    b .Lneon_i

.Lneon_done:
    ret

.size matmul_asm_neon, .-matmul_asm_neon
