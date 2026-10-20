# tests sb and sh at each offset, reads back with lw

.text
main:
        lui   x5, 0x10010          # data base
        li    x6, 0x11223344
        sw    x6, 0(x5)
        sw    x6, 4(x5)

        li    x7, 0xAABBCCDD
        sb    x7, 0(x5)
        lw    x8, 0(x5)            # 0x112233DD
        sb    x7, 1(x5)
        lw    x9, 0(x5)            # 0x1122DDDD
        sb    x7, 2(x5)
        sb    x7, 3(x5)
        lw    x10, 0(x5)           # 0xDDDDDDDD

        sh    x7, 4(x5)
        lw    x11, 4(x5)           # 0x1122CCDD
        sh    x7, 6(x5)
        lw    x12, 4(x5)           # 0xCCDDCCDD

        lb    x13, 7(x5)           # sign extended 0xCC
        lhu   x14, 6(x5)

        wfi
