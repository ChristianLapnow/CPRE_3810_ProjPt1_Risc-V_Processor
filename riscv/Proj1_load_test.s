# tests lb, lh, lbu, lhu, lw at each offset

.text
main:
        lui   x5, 0x10010          # data base
        li    x6, 0x8001FF7F
        sw    x6, 0(x5)
        li    x6, 0x12345678
        sw    x6, 4(x5)

        lb    x7,  0(x5)
        lb    x8,  1(x5)           # 0xFFFFFFFF
        lb    x9,  2(x5)
        lb    x10, 3(x5)           # 0xFFFFFF80
        lbu   x11, 1(x5)           # 0x000000FF
        lbu   x12, 3(x5)           # 0x00000080
        lh    x13, 0(x5)
        lh    x14, 2(x5)
        lhu   x15, 0(x5)
        lhu   x16, 2(x5)
        lw    x17, 0(x5)

        # second word
        lb    x18, 4(x5)
        lb    x19, 7(x5)
        lh    x20, 6(x5)
        lhu   x21, 4(x5)
        lw    x22, 4(x5)

        add   x23, x8, x12         # use a loaded value

        wfi
