onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock / Reset}
add wave -noupdate /tb/CLK
add wave -noupdate /tb/reset
add wave -noupdate -divider Fetch
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_PC
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_Inst
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_PCPlus4
add wave -noupdate -radix binary /tb/MyRiscv/s_PCSrc
add wave -noupdate /tb/MyRiscv/s_Branch
add wave -noupdate /tb/MyRiscv/s_Jump
add wave -noupdate /tb/MyRiscv/s_JALR
add wave -noupdate /tb/MyRiscv/s_Zero
add wave -noupdate -divider Control
add wave -noupdate /tb/MyRiscv/s_RegWrite
add wave -noupdate /tb/MyRiscv/s_MemWrite
add wave -noupdate /tb/MyRiscv/s_ALUSrcA
add wave -noupdate /tb/MyRiscv/s_ALUSrc
add wave -noupdate -radix binary /tb/MyRiscv/s_ALUControl
add wave -noupdate -radix binary /tb/MyRiscv/s_ImmType
add wave -noupdate -radix binary /tb/MyRiscv/s_ResultSrc
add wave -noupdate /tb/MyRiscv/s_Halt
add wave -noupdate -divider Decode
add wave -noupdate -radix unsigned {/tb/MyRiscv/s_Inst(19 downto 15)}
add wave -noupdate -radix unsigned {/tb/MyRiscv/s_Inst(24 downto 20)}
add wave -noupdate -radix unsigned /tb/MyRiscv/s_RegWrAddr
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_RS1Data
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_RS2Data
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_Imm
add wave -noupdate -divider Execute
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_ALUA
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_ALUB
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_ALURes
add wave -noupdate -divider Memory
add wave -noupdate /tb/MyRiscv/s_DMemWr
add wave -noupdate -radix binary /tb/MyRiscv/s_DMemBE
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_DMemAddr
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_DMemData
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_DMemOut
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_LoadData
add wave -noupdate -divider Writeback
add wave -noupdate /tb/MyRiscv/s_RegWr
add wave -noupdate -radix unsigned /tb/MyRiscv/s_RegWrAddr
add wave -noupdate -radix hexadecimal /tb/MyRiscv/s_RegWrData
add wave -noupdate -divider {Barrel shifter}
add wave -noupdate -radix hexadecimal /tb/MyRiscv/ALU0/SHIFTER/i_D
add wave -noupdate -radix hexadecimal /tb/MyRiscv/ALU0/SHIFTER/o_Q
add wave -noupdate -radix unsigned /tb/MyRiscv/ALU0/SHIFTER/i_Shamt
add wave -noupdate /tb/MyRiscv/ALU0/SHIFTER/i_Right
add wave -noupdate /tb/MyRiscv/ALU0/SHIFTER/i_Arith
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {969 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 238
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1408 ns}
