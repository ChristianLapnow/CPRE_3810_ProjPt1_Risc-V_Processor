# Proj1_base_test.s
# Uses every required arithmetic/logical/memory instruction at least once.
# Expected register values are in the comments.
.data
words: .word 0, 0, 0, 0
bytes: .byte 0x80, 0x7F, 0xFF, 0x01
halfs: .half 0x8000, 0x7FFF
.text
main:
    lui   s0, 0x10010        # s0 = 0x10010000, base of .data

    # I-type arithmetic/logic
    addi  t0, x0, 100        # t0 = 100
    addi  t1, x0, -50        # t1 = -50
    xori  t2, t0, 0xFF       # t2 = 155
    ori   t3, t1, 0x0F       # t3 = -49
    andi  t4, t1, 0xFF       # t4 = 206 (low byte of -50)
    slti  t5, t1, 0          # t5 = 1  (-50 < 0)
    sltiu t6, t1, 1          # t6 = 0  (0xFFFFFFCE is huge unsigned)
    sltiu s1, x0, 1          # s1 = 1  (seqz idiom)

    # R-type arithmetic/logic
    add   s2, t0, t1         # s2 = 50
    sub   s3, t1, t0         # s3 = -150
    and   s4, t0, t3         # s4 = 68
    or    s5, t0, t1         # s5 = -18
    xor   s6, t0, t1         # s6 = -86
    slt   s7, t1, t0         # s7 = 1
    slt   s8, t0, t1         # s8 = 0

    # upper immediates
    lui   s9, 0xABCDE        # s9 = 0xABCDE000
    auipc s10, 0             # s10 = address of this instruction

    # immediate shifts
    slli  s11, t0, 4         # s11 = 1600
    srli  a0, t1, 28         # a0 = 15 (logical, zeros shifted in)
    srai  a1, t1, 4          # a1 = -4 (arithmetic, sign kept)

    # register shifts, only low 5 bits of the amount matter
    addi  a2, x0, 3
    sll   a3, t0, a2         # a3 = 800
    srl   a4, t1, a2         # a4 = 0x1FFFFFF9
    sra   a5, t1, a2         # a5 = -7
    addi  a2, x0, 35         # 35 & 0x1F = 3
    sll   a6, t0, a2         # a6 = 800 again

    # word store/load round trip
    sw    s2, 0(s0)          # words[0] = 50
    sw    s3, 4(s0)          # words[1] = -150
    lw    a7, 0(s0)          # a7 = 50
    lw    t0, 4(s0)          # t0 = -150

    # byte and half loads, signed vs unsigned
    addi  t1, s0, 16         # t1 = &bytes
    lb    t2, 0(t1)          # t2 = -128
    lbu   t3, 0(t1)          # t3 = 128
    lb    t4, 1(t1)          # t4 = 127
    lh    t5, 4(t1)          # t5 = -32768
    lhu   t6, 4(t1)          # t6 = 32768
    lh    s1, 6(t1)          # s1 = 32767

    # sb/sh live in Proj1_store_test.s, course RARS doesn't trace their memory writes
    addi  t0, x0, -1         # t0 = 0xFFFFFFFF
    sw    x0, 8(s0)          # words[2] = 0

    wfi
