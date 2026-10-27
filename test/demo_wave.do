# Demo wave setup for the single-cycle processor
# run from the toolflow output/<program> folder: vsim -do ../../proj/test/demo_wave.do

vsim -voptargs=+acc tb
log -r /tb/MyRiscv/*
mem load -infile imem.hex -format hex /MyRiscv/IMem
mem load -infile dmem.hex -format hex /MyRiscv/DMem


add wave -divider "Clock / Reset"
add wave /tb/CLK /tb/reset

add wave -divider "Fetch"
add wave -radix hex /tb/MyRiscv/s_PC /tb/MyRiscv/s_Inst /tb/MyRiscv/s_PCPlus4
add wave -radix binary /tb/MyRiscv/s_PCSrc
add wave /tb/MyRiscv/s_Branch /tb/MyRiscv/s_Jump /tb/MyRiscv/s_JALR /tb/MyRiscv/s_Zero

add wave -divider "Instruction fields"
add wave -radix binary -label opcode /tb/MyRiscv/s_Inst(6:0)
add wave -radix binary -label funct3 /tb/MyRiscv/s_Inst(14:12)
add wave -label funct7b5 /tb/MyRiscv/s_Inst(30)
add wave -radix unsigned -label rs1 /tb/MyRiscv/s_Inst(19:15)
add wave -radix unsigned -label rs2 /tb/MyRiscv/s_Inst(24:20)
add wave -radix unsigned -label rd /tb/MyRiscv/s_Inst(11:7)

add wave -divider "Control"
add wave /tb/MyRiscv/s_RegWrite /tb/MyRiscv/s_MemWrite /tb/MyRiscv/s_ALUSrcA /tb/MyRiscv/s_ALUSrc
add wave -radix binary /tb/MyRiscv/s_ALUControl /tb/MyRiscv/s_ImmType /tb/MyRiscv/s_ResultSrc
add wave /tb/MyRiscv/s_Halt

add wave -divider "Decode"
add wave -radix hex /tb/MyRiscv/s_RS1Data /tb/MyRiscv/s_RS2Data /tb/MyRiscv/s_Imm

add wave -divider "Execute"
add wave -radix hex /tb/MyRiscv/s_ALUA /tb/MyRiscv/s_ALUB /tb/MyRiscv/s_ALURes

add wave -divider "Barrel shifter"
add wave -radix hex /tb/MyRiscv/ALU0/SHIFTER/i_D /tb/MyRiscv/ALU0/SHIFTER/o_Q
add wave -radix unsigned /tb/MyRiscv/ALU0/SHIFTER/i_Shamt
add wave /tb/MyRiscv/ALU0/SHIFTER/i_Right /tb/MyRiscv/ALU0/SHIFTER/i_Arith

add wave -divider "Memory"
add wave /tb/MyRiscv/s_DMemWr
add wave -radix binary /tb/MyRiscv/s_DMemBE
add wave -radix hex /tb/MyRiscv/s_DMemAddr /tb/MyRiscv/s_DMemData /tb/MyRiscv/s_DMemOut /tb/MyRiscv/s_LoadData

add wave -divider "Writeback"
add wave /tb/MyRiscv/s_RegWr
add wave -radix unsigned /tb/MyRiscv/s_RegWrAddr
add wave -radix hex /tb/MyRiscv/s_RegWrData

run -all
wave zoom full
