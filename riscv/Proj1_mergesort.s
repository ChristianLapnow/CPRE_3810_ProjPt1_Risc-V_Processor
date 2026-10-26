# Proj1_mergesort.s
# Recursive merge sort of N words in arr, using tmp as scratch.
# arr should end up sorted ascending.
.data
arr: .word 9, -3, 7, 1, 0, 12, -8, 5, 3, 2
tmp: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
n:   .word 10
.text
main:
    li    sp, 0x10011000
    la    a0, arr            # a0 = arr
    la    a1, tmp            # a1 = tmp
    li    a2, 0              # a2 = lo
    la    t0, n
    lw    a3, 0(t0)
    addi  a3, a3, -1         # a3 = hi = n-1
    jal   ra, mergesort
    j     end                # wfi has to be the last instruction for RARS

# mergesort(arr, tmp, lo, hi)
mergesort:
    bge   a2, a3, ms_ret     # one element, nothing to do
    addi  sp, sp, -16
    sw    ra, 12(sp)
    sw    a2, 8(sp)          # lo
    sw    a3, 4(sp)          # hi
    add   t0, a2, a3
    srai  t0, t0, 1          # mid = (lo+hi)/2
    sw    t0, 0(sp)          # mid

    mv    a3, t0             # sort lo..mid
    jal   ra, mergesort

    lw    t0, 0(sp)
    addi  a2, t0, 1          # sort mid+1..hi
    lw    a3, 4(sp)
    jal   ra, mergesort

    lw    a2, 8(sp)          # merge(lo, mid, hi)
    lw    a4, 0(sp)
    lw    a3, 4(sp)
    jal   ra, merge

    lw    ra, 12(sp)
    addi  sp, sp, 16
ms_ret:
    jalr  x0, ra, 0

# merge(arr=a0, tmp=a1, lo=a2, hi=a3, mid=a4), leaf function
merge:
    mv    t1, a2             # i = lo
    addi  t2, a4, 1          # j = mid+1
    mv    t3, a2             # k = lo
merge_loop:
    blt   a4, t1, copy_right # left half used up
    blt   a3, t2, copy_left  # right half used up
    slli  t4, t1, 2
    add   t4, t4, a0
    lw    t5, 0(t4)          # arr[i]
    slli  t6, t2, 2
    add   t6, t6, a0
    lw    t6, 0(t6)          # arr[j]
    blt   t6, t5, take_right
take_left:
    slli  t4, t3, 2
    add   t4, t4, a1
    sw    t5, 0(t4)          # tmp[k] = arr[i]
    addi  t1, t1, 1
    addi  t3, t3, 1
    j     merge_loop
take_right:
    slli  t4, t3, 2
    add   t4, t4, a1
    sw    t6, 0(t4)          # tmp[k] = arr[j]
    addi  t2, t2, 1
    addi  t3, t3, 1
    j     merge_loop
copy_left:
    blt   a4, t1, copy_back
    slli  t4, t1, 2
    add   t4, t4, a0
    lw    t5, 0(t4)
    slli  t4, t3, 2
    add   t4, t4, a1
    sw    t5, 0(t4)
    addi  t1, t1, 1
    addi  t3, t3, 1
    j     copy_left
copy_right:
    blt   a3, t2, copy_back
    slli  t4, t2, 2
    add   t4, t4, a0
    lw    t5, 0(t4)
    slli  t4, t3, 2
    add   t4, t4, a1
    sw    t5, 0(t4)
    addi  t2, t2, 1
    addi  t3, t3, 1
    j     copy_right
copy_back:                   # tmp[lo..hi] back into arr
    mv    t1, a2
cb_loop:
    blt   a3, t1, merge_ret
    slli  t4, t1, 2
    add   t5, t4, a1
    lw    t5, 0(t5)
    add   t4, t4, a0
    sw    t5, 0(t4)
    addi  t1, t1, 1
    j     cb_loop
merge_ret:
    jalr  x0, ra, 0

end:
    wfi
