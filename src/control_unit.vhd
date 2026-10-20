-------------------------------------------------------------------------
-- Christian Lapnow
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- control_unit.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Combinational (dataflow) control unit for the single-cycle
-- RISC-V processor. Two levels:
--   1) Main decoder: opcode -> datapath control signals + 2-bit ALUOp
--   2) ALU decoder:  ALUOp + funct3 + funct7[5] -> 4-bit ALUControl
--
-- ALUControl encoding:
--   0000 ADD   0001 SUB   0010 AND   0011 OR    0100 XOR
--   0101 SLT   0110 SLTU  0111 SLL   1000 SRL   1001 SRA
-- ImmType encoding:
--   000 I   001 S   010 B   011 U   100 J
-- ResultSrc encoding (what gets written back to rd):
--   00 ALU result   01 load data   10 PC+4 (jal/jalr)   11 U-imm (lui)
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity control_unit is
  port(i_Opcode     : in  std_logic_vector(6 downto 0);  -- inst[6:0]
       i_Funct3     : in  std_logic_vector(2 downto 0);  -- inst[14:12]
       i_Funct7b5   : in  std_logic;                     -- inst[30]
       i_Imm12      : in  std_logic_vector(11 downto 0); -- inst[31:20] (used to detect wfi)
       o_ALUSrcA    : out std_logic;                     -- 0 = rs1, 1 = PC (auipc)
       o_ALUSrc     : out std_logic;                     -- 0 = rs2, 1 = immediate
       o_ALUControl : out std_logic_vector(3 downto 0);
       o_ImmType    : out std_logic_vector(2 downto 0);
       o_ResultSrc  : out std_logic_vector(1 downto 0);
       o_MemWrite   : out std_logic;
       o_RegWrite   : out std_logic;
       o_Branch     : out std_logic;                     -- conditional branch
       o_Jump       : out std_logic;                     -- jal (PC <- PC + imm)
       o_JALR       : out std_logic;                     -- jalr (PC <- (rs1 + imm) & ~1)
       o_Halt       : out std_logic);                    -- wfi
end control_unit;

architecture dataflow of control_unit is

  -- Main decoder output bundle (14 bits):
  -- [13] ALUSrcA [12] ALUSrc [11:9] ImmType [8:7] ResultSrc [6] MemWrite
  -- [5] RegWrite [4] Branch [3] Jump [2] JALR [1:0] ALUOp
  signal s_Main   : std_logic_vector(13 downto 0);
  signal s_ALUOp  : std_logic_vector(1 downto 0);
  signal s_Arith  : std_logic_vector(3 downto 0);  -- R/I-type ALU decode
  signal s_BrOp   : std_logic_vector(3 downto 0);  -- branch compare decode
  signal s_SubOK  : std_logic;                     -- funct7[5] selects SUB only for R-type

begin

  ---------------------------------------------------------------------
  -- Main decoder
  --                         ASA AS  Imm   Res  MW RW Br J  JR ALUOp
  ---------------------------------------------------------------------
  with i_Opcode select
    s_Main <= "0" & "0" & "000" & "00" & "0" & "1" & "0" & "0" & "0" & "10" when "0110011", -- R-type
              "0" & "1" & "000" & "00" & "0" & "1" & "0" & "0" & "0" & "11" when "0010011", -- I-type ALU
              "0" & "1" & "000" & "01" & "0" & "1" & "0" & "0" & "0" & "00" when "0000011", -- loads
              "0" & "1" & "001" & "00" & "1" & "0" & "0" & "0" & "0" & "00" when "0100011", -- stores
              "0" & "0" & "010" & "00" & "0" & "0" & "1" & "0" & "0" & "01" when "1100011", -- branches
              "0" & "0" & "100" & "10" & "0" & "1" & "0" & "1" & "0" & "00" when "1101111", -- jal
              "0" & "1" & "000" & "10" & "0" & "1" & "0" & "0" & "1" & "00" when "1100111", -- jalr
              "0" & "0" & "011" & "11" & "0" & "1" & "0" & "0" & "0" & "00" when "0110111", -- lui
              "1" & "1" & "011" & "00" & "0" & "1" & "0" & "0" & "0" & "00" when "0010111", -- auipc
              "00000000000000"                                              when others;    -- wfi / unknown

  o_ALUSrcA   <= s_Main(13);
  o_ALUSrc    <= s_Main(12);
  o_ImmType   <= s_Main(11 downto 9);
  o_ResultSrc <= s_Main(8 downto 7);
  o_MemWrite  <= s_Main(6);
  o_RegWrite  <= s_Main(5);
  o_Branch    <= s_Main(4);
  o_Jump      <= s_Main(3);
  o_JALR      <= s_Main(2);
  s_ALUOp     <= s_Main(1 downto 0);

  ---------------------------------------------------------------------
  -- ALU decoder
  ---------------------------------------------------------------------
  -- For addi, inst[30] is part of the immediate, so it must not pick SUB.
  -- (srai still uses inst[30] to pick SRA, handled below.)
  s_SubOK <= i_Funct7b5 and s_ALUOp(1) and (not s_ALUOp(0));

  -- R-type and I-type arithmetic/logic (ALUOp = 10 or 11)
  s_Arith <= "0001" when (i_Funct3 = "000" and s_SubOK = '1')    else  -- sub
             "0000" when (i_Funct3 = "000")                      else  -- add / addi
             "0111" when (i_Funct3 = "001")                      else  -- sll / slli
             "0101" when (i_Funct3 = "010")                      else  -- slt / slti
             "0110" when (i_Funct3 = "011")                      else  -- sltu / sltiu
             "0100" when (i_Funct3 = "100")                      else  -- xor / xori
             "1001" when (i_Funct3 = "101" and i_Funct7b5 = '1') else  -- sra / srai
             "1000" when (i_Funct3 = "101")                      else  -- srl / srli
             "0011" when (i_Funct3 = "110")                      else  -- or / ori
             "0010";                                                   -- and / andi

  -- Branches (ALUOp = 01): compare rs1 and rs2 with the ALU
  with i_Funct3(2 downto 1) select
    s_BrOp <= "0001" when "00",    -- beq / bne   -> SUB  (check Zero)
              "0101" when "10",    -- blt / bge   -> SLT
              "0110" when "11",    -- bltu / bgeu -> SLTU
              "0001" when others;

  with s_ALUOp select
    o_ALUControl <= "0000"  when "00",   -- loads, stores, jalr, auipc, lui: ADD
                    s_BrOp  when "01",
                    s_Arith when others;

  -- Halt: wfi = opcode 1110011, funct3 000, imm 000100000101
  
  o_Halt <= '1' when (i_Opcode = "1110011" and i_Funct3 = "000" and i_Imm12 = "000100000101") else '0';

end dataflow;
