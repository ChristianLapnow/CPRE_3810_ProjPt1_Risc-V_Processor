# QuestaSim: do wave_fetch.do  (after compiling Lab 2 parts + fetch files)
vsim -voptargs=+acc work.tb_fetchUnit
add wave -divider "Test step"
add wave -radix decimal /tb_fetchUnit/s_Case
add wave /tb_fetchUnit/s_CLK /tb_fetchUnit/s_RST /tb_fetchUnit/s_PCWE
add wave -divider "Control inputs"
add wave /tb_fetchUnit/s_Branch /tb_fetchUnit/s_Jump /tb_fetchUnit/s_JALR /tb_fetchUnit/s_Zero
add wave -radix binary /tb_fetchUnit/s_Funct3
add wave -divider "Internal"
add wave /tb_fetchUnit/DUT/s_BrCond
add wave -radix binary /tb_fetchUnit/s_PCSrc
add wave -radix hex /tb_fetchUnit/DUT/s_PCPlus4 /tb_fetchUnit/DUT/s_PCPlusImm /tb_fetchUnit/DUT/s_JalrTarget
add wave -divider "Data in / PC out"
add wave -radix hex /tb_fetchUnit/s_Imm /tb_fetchUnit/s_ALURes
add wave -radix hex /tb_fetchUnit/s_PC /tb_fetchUnit/DUT/s_NextPC
run 500 ns
wave zoom full
