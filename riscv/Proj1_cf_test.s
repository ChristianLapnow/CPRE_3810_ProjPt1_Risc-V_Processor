# Proj1_cf_test.s
# Every branch both taken and not taken, a backward branch loop,
# jal/jalr, and a recursive call 7 deep.
.data
res: .word 0, 0, 0, 0
.text
main:
    li    sp, 0x10011000
    la    s0, res
    li    t0, 5
    li    t1, 5
    li    t2, -5
    li    s1, 0              # s1 collects a bit for each correct not-taken branch

    beq   t0, t1, L1         # taken
    addi  s1, s1, 100
L1: beq   t0, t2, L2         # not taken
    addi  s1, s1, 1
L2: bne   t0, t2, L3         # taken
    addi  s1, s1, 100
L3: bne   t0, t1, L4         # not taken
    addi  s1, s1, 2
L4: blt   t2, t0, L5         # taken, signed -5 < 5
    addi  s1, s1, 100
L5: blt   t0, t2, L6         # not taken
    addi  s1, s1, 4
L6: bge   t0, t2, L7         # taken
    addi  s1, s1, 100
L7: bge   t2, t0, L8         # not taken
    addi  s1, s1, 8
L8: bltu  t0, t2, L9         # taken, -5 is 0xFFFFFFFB unsigned
    addi  s1, s1, 100
L9: bltu  t2, t0, L10        # not taken
    addi  s1, s1, 16
L10: bgeu t2, t0, L11        # taken
    addi  s1, s1, 100
L11: bgeu t0, t2, L12        # not taken
    addi  s1, s1, 32
L12: sw   s1, 0(s0)          # res[0] = 63

    # backward branch loop, counts down 10 to 0
    li    t3, 10
    li    t4, 0
loop:
    addi  t4, t4, 1
    addi  t3, t3, -1
    bne   t3, x0, loop
    sw    t4, 4(s0)          # res[1] = 10

    # recursive sum 6+5+...+0, call depth 7
    li    a0, 6
    jal   ra, rsum
    sw    a0, 8(s0)          # res[2] = 21

    # jalr with a nonzero offset to a computed address
    la    t5, hop
    addi  t5, t5, -4
    jalr  ra, t5, 4
    sw    a0, 12(s0)         # res[3] = 77
    j     end                # wfi has to be the last instruction for RARS

hop:
    li    a0, 77
    jalr  x0, ra, 0

rsum:
    addi  sp, sp, -8
    sw    ra, 4(sp)
    sw    a0, 0(sp)
    beq   a0, x0, rsum_ret   # base case returns 0
    addi  a0, a0, -1
    jal   ra, rsum
    lw    t0, 0(sp)
    add   a0, a0, t0         # n + sum(n-1)
rsum_ret:
    lw    ra, 4(sp)
    addi  sp, sp, 8
    jalr  x0, ra, 0

end:
    wfi
