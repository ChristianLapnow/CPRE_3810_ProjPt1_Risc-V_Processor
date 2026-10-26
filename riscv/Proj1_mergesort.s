# Proj1_mergesort.s
# Recursive merge sort of array_size words in array, sorted in place.
# Built on Proj_sort_template.s: main calls sort(a0 = array, a1 = size).
# merge copies the left half into tmp (at most 256 words when the array
# is 512 long) and merges it with the right half back into array.
#
# main is placed last so that wfi is the final instruction in .text. The
# toolflow's RARS does not stop at a wfi in the middle of a program.

# Note: You MUST put the sorted array back in the SAME memory location as the original array.
#       During grading we will insert our own array and corresponding array_size for testing.
#       The max size will be 512 elements.
.data
    array_size: .word 12
    array: .word 65, 12, 10, 89, 11, 70, 67, 5, 9, 45, 90, 7
    tmp: .space 1024          # scratch for the left half, 256 words
.text
.globl main

    li    sp, 0x10011000     # registers reset to 0 on our processor, so set sp
    j     main

# void sort(int* array, int size);
.globl sort
sort:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    mv    a2, x0             # lo = 0
    addi  a3, a1, -1         # hi = size - 1
    jal   ra, msort
    lw    ra, 0(sp)
    addi  sp, sp, 4
    jalr  x0, ra, 0

# msort(array=a0, lo=a2, hi=a3): sorts array[lo..hi]
msort:
    bge   a2, a3, ms_ret     # 0 or 1 elements, nothing to do
    addi  sp, sp, -16
    sw    ra, 12(sp)
    sw    a2, 8(sp)          # lo
    sw    a3, 4(sp)          # hi
    add   t0, a2, a3
    srai  t0, t0, 1          # mid = (lo+hi)/2
    sw    t0, 0(sp)          # mid

    mv    a3, t0             # sort lo..mid
    jal   ra, msort

    lw    t0, 0(sp)
    addi  a2, t0, 1          # sort mid+1..hi
    lw    a3, 4(sp)
    jal   ra, msort

    lw    a2, 8(sp)          # merge(lo, mid, hi)
    lw    a4, 0(sp)
    lw    a3, 4(sp)
    jal   ra, merge

    lw    ra, 12(sp)
    addi  sp, sp, 16
ms_ret:
    jalr  x0, ra, 0

# merge(array=a0, lo=a2, hi=a3, mid=a4), leaf function
# array[lo..mid] goes to tmp, then tmp and array[mid+1..hi] merge back
# into array[lo..hi]. Anything left in the right half is already in place.
merge:
    la    a1, tmp
    mv    t1, a2             # i = lo
    mv    t3, x0             # k = 0
copy_loop:
    blt   a4, t1, copy_done  # i > mid
    slli  t4, t1, 2
    add   t4, t4, a0
    lw    t5, 0(t4)          # array[i]
    slli  t4, t3, 2
    add   t4, t4, a1
    sw    t5, 0(t4)          # tmp[k] = array[i]
    addi  t1, t1, 1
    addi  t3, t3, 1
    j     copy_loop
copy_done:
    mv    t6, t3             # t6 = number of words in tmp
    mv    t1, x0             # i = 0 (tmp)
    addi  t2, a4, 1          # j = mid+1 (right half)
    mv    t3, a2             # k = lo (output)
merge_loop:
    bge   t1, t6, merge_ret  # tmp used up
    blt   a3, t2, take_left  # right half used up
    slli  t4, t1, 2
    add   t4, t4, a1
    lw    t5, 0(t4)          # tmp[i]
    slli  t4, t2, 2
    add   t4, t4, a0
    lw    t4, 0(t4)          # array[j]
    blt   t4, t5, take_right # equal keeps the left one (stable)
take_left:
    slli  t4, t1, 2
    add   t4, t4, a1
    lw    t5, 0(t4)
    slli  t4, t3, 2
    add   t4, t4, a0
    sw    t5, 0(t4)          # array[k] = tmp[i]
    addi  t1, t1, 1
    addi  t3, t3, 1
    j     merge_loop
take_right:
    slli  t4, t2, 2
    add   t4, t4, a0
    lw    t5, 0(t4)
    slli  t4, t3, 2
    add   t4, t4, a0
    sw    t5, 0(t4)          # array[k] = array[j]
    addi  t2, t2, 1
    addi  t3, t3, 1
    j     merge_loop
merge_ret:
    jalr  x0, ra, 0

main:
    # Save return address
    addi sp, sp, -4
    sw ra, 0(sp)

    # Call sorting function
    la a0, array
    lw a1, array_size
    jal ra, sort

    # restore stack
    lw ra, 0(sp)
    addi sp, sp, 4

    # Exit program
    wfi
