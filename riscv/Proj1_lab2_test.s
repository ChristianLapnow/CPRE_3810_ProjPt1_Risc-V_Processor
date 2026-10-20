.text
 

addi x5, x0, 1
lui x6, 0x10010

sw x5, 0(x6)

lw x7, 0(x6)

sub x7, x7, x7

wfi
