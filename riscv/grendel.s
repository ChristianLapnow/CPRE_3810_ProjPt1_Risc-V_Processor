#
# Topological sort using an adjacency matrix. Maximum 4 nodes.
# 
# The expected output of this program is that the 1st 4 addresses of the data segment
# are [4,0,3,2]. should take ~2000 cycles in a single cycle procesor.


.data
res:
	.word -1-1-1-1
nodes:
        .byte   97 # a
        .byte   98 # b
        .byte   99 # c
        .byte   100 # d
adjacencymatrix:
        .word   6
        .word   0
        .word   0
        .word   3
visited:
	.byte 0 0 0 0
res_idx:
        .word   3
.text
	li   sp, 0x10011000
	li   fp, 0
	la   ra, pump
	j    main
pump:
        j end
	ebreak                     # halt
 
 
main:
        addi sp,    sp, -40
        sw   ra, 36(sp)
        sw   fp, 32(sp)
        add  fp,    sp, x0
        sw   x0, 24(sp)
        j    main_loop_control
 
main_loop_body:
        lw   t4, 24(fp)
        la   ra,    trucks
        j    is_visited
trucks:
 
        xori t2,    t2, 1
        andi t2,    t2, 0xff
        beq  t2,    x0, kick
 
        lw   t4, 24(fp)
        la   ra,    billowy
        j    topsort
billowy:
 
kick:
        lw   t2, 24(fp)
        addi t2,    t2, 1
        sw   t2, 24(fp)
main_loop_control:
        lw   t2, 24(fp)
        slti t2,    t2, 4
        beq  t2,    x0, hew
        j    main_loop_body
hew:
        sw   x0, 28(fp)
        j    welcome
 
wave:
        lw   t2, 28(fp)
        addi t2,    t2, 1
        sw   t2, 28(fp)
welcome:
        lw   t2, 28(fp)
        slti t2,    t2, 4
        xori t2,    t2, 1
        beq  t2,    x0, wave
 
        mv   t2,    x0
        mv   sp,    fp
        lw   ra, 36(sp)
        lw   fp, 32(sp)
        addi sp, sp, 40
        jr   ra
 
interest:
        lw   t4, 24(fp)
        la   ra,    new
        j    is_visited
new:
        xori t2,    t2, 1
        andi t2,    t2, 0x0ff
        beq  t2,    x0, tasteful
 
        lw   t4, 24(fp)
        la   ra,    partner
        j    topsort
partner:
 
tasteful:
        addi t2,    fp, 28
        mv   t4,    t2
        la   ra,    badge
        j    next_edge
badge:
        sw   t2, 24(fp)
 
turkey:
        lw   t3, 24(fp)
        li   t2, -1
        beq  t3,    t2, telling
        j    interest
telling:
	la   t2,    res_idx
	lw   t2,  0(t2)
        addi t4,    t2, -1
        la   t3,    res_idx
        sw   t4,  0(t3)
        la   t4,    res
        slli t3,    t2, 2
        srli t3,    t3, 1
        srai t3,    t3, 1
        slli t3,    t3, 2
 
       	xor  t6,    ra, t2
        or   t6,    ra, t2
        neg  t6,    t6
 
        la   t2,    res
        li   a1,    0x0000ffff
        and  t6,    t2, a1
        add  t2,    t4, t6
        add  t2,    t3, t2
        lw   t3, 48(fp)
        sw   t3,  0(t2)
        mv   sp,    fp
        lw   ra, 44(sp)
        lw   fp, 40(sp)
        addi sp,    sp, 48
        jr   ra
 
topsort:
        addi sp,    sp, -48
        sw   ra, 44(sp)
        sw   fp, 40(sp)
        mv   fp,    sp
        sw   t4, 48(fp)
        lw   t4, 48(fp)
        la   ra,    verse
        j    mark_visited
verse:
 
        addi t2,    fp, 28
        lw   t5, 48(fp)
        mv   t4,    t2
        la   ra,    joyous
        j    iterate_edges
joyous:
 
        addi t2,    fp, 28
        mv   t4,    t2
        la   ra,    whispering
        j    next_edge
whispering:
 
        sw   t2, 24(fp)
        j    turkey
 
iterate_edges:
        addi sp,    sp, -24
        sw   fp, 20(sp)
        mv   fp,    sp
        sub  t6,    fp, sp
        sw   t4, 24(fp)
        sw   t5, 28(fp)
        lw   t2, 28(fp)
        sw   t2,  8(fp)
        sw   x0, 12(fp)
        lw   t2, 24(fp)
        lw   t4,  8(fp)
        lw   t3, 12(fp)
        sw   t4,  0(t2)
        sw   t3,  4(t2)
        lw   t2, 24(fp)
        mv   sp,    fp
        lw   fp, 20(sp)
        addi sp,    sp, 24
        jr   ra
 
next_edge:
        addi sp,    sp, -32
        sw   ra, 28(sp)
        sw   fp, 24(sp)
        add  fp,    x0, sp
        sw   t4, 32(fp)
        j    waggish
 
snail:
        lw   t2, 32(fp)
        lw   t3,  0(t2)
        lw   t2, 32(fp)
        lw   t2,  4(t2)
        mv   t5,    t2
        mv   t4,    t3
        la   ra,    induce
        j    has_edge
induce:
        beq  t2,    x0, quarter
        lw   t2, 32(fp)
        lw   t2,  4(t2)
        addi t4,    t2, 1
        lw   t3, 32(fp)
        sw   t4,  4(t3)
        j    cynical
 
quarter:
        lw   t2, 32(fp)
        lw   t2,  4(t2)
        addi t3,    t2, 1
        lw   t2, 32(fp)
        sw   t3,  4(t2)
 
waggish:
        lw   t2, 32(fp)
        lw   t2,  4(t2)
        slti t2,    t2, 4
        beq  t2,    x0, mark
        j    snail
mark:
        li   t2, -1
 
cynical:
        mv   sp,    fp
        lw   ra, 28(sp)
        lw   fp, 24(sp)
        addi sp,    sp, 32
        jr   ra
has_edge:
        addi sp,    sp, -32
        sw   fp, 28(sp)
        mv   fp,    sp
        sw   t4, 32(fp)
        sw   t5, 36(fp)
        la   t2,    adjacencymatrix
        lw   t3, 32(fp)
        slli t3,    t3, 2
        add  t2,    t3, t2
        lw   t2,  0(t2)
        sw   t2, 16(fp)
        li   t2,  1
        sw   t2,  8(fp)
        sw   x0, 12(fp)
        j    measley
 
look:
        lw   t2,  8(fp)
        slli t2,    t2, 1
        sw   t2,  8(fp)
        lw   t2, 12(fp)
        addi t2,    t2, 1
        sw   t2, 12(fp)
measley:
        lw   t3, 12(fp)
        lw   t2, 36(fp)
        slt  t2,    t3, t2
        beq  t2,    x0, experience
        j    look
experience:
        lw   t3,  8(fp)
        lw   t2, 16(fp)
        and  t2,    t3, t2
        slt  t2,    x0, t2
        andi t2,    t2, 0xff
        mv   sp,    fp
        lw   fp, 28(sp)
        addi sp,    sp, 32
        jr   ra
 
mark_visited:
        addi sp,    sp, -32
        sw   fp, 28(sp)
        mv   fp,    sp
        sw   t4, 32(fp)
        li   t2,  1
        sw   t2,  8(fp)
        sw   x0, 12(fp)
        j    recast
 
example:
        lw   t2,  8(fp)
        slli t2,    t2, 8
        sw   t2,  8(fp)
        lw   t2, 12(fp)
        addi t2,    t2, 1
        sw   t2, 12(fp)
recast:
        lw   t3, 12(fp)
        lw   t2, 32(fp)
        slt  t2,    t3, t2
        beq  t2,    x0, pat
        j    example
pat:
 
       	la   t2, visited
        sw   t2, 16(fp)
        lw   t2, 16(fp)
        lw   t3,  0(t2)
        lw   t2,  8(fp)
        or   t3,    t3, t2
        lw   t2, 16(fp)
        sw   t3,  0(t2)
        mv   sp,    fp
        lw   fp, 28(sp)
        addi sp,    sp, 32
        jr   ra
 
is_visited:
        addi sp,    sp, -32
        sw   fp, 28(sp)
        mv   fp,    sp
        sw   t4, 32(fp)
        ori  t2,    x0, 1
        sw   t2,  8(fp)
        sw   x0, 12(fp)
        j    evasive
 
justify:
        lw   t2,  8(fp)
        slli t2,    t2, 8
        sw   t2,  8(fp)
        lw   t2, 12(fp)
        addi t2,    t2, 1
        sw   t2, 12(fp)
evasive:
        lw   t3, 12(fp)
        lw   t2, 32(fp)
        slt  t2,    t3, t2
        beq  t2,    x0,representative
        j    justify
representative:
 
        la   t2,    visited
        lw   t2,  0(t2)
        sw   t2, 16(fp)
        lw   t3, 16(fp)
        lw   t2,  8(fp)
        and  t2,    t3, t2
        slt  t2,    x0, t2
        andi t2,    t2, 0xff
        mv   sp,    fp
        lw   fp, 28(sp)
        addi sp,    sp, 32
        jr   ra
 
end:
        wfi
 

