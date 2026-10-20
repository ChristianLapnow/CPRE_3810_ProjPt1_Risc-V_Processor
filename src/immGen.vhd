-------------------------------------------------------------------------
-- immGen.vhd
-- Builds the sign-extended 32-bit immediate from the instruction.
-- i_ImmType (from control_unit):
--   000 I-type  inst[31:20]
--   001 S-type  inst[31:25] & inst[11:7]
--   010 B-type  inst[31] inst[7] inst[30:25] inst[11:8] 0
--   011 U-type  inst[31:12] & x"000"
--   100 J-type  inst[31] inst[19:12] inst[20] inst[30:21] 0
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity immGen is
  port(i_Inst    : in  std_logic_vector(31 downto 0);
       i_ImmType : in  std_logic_vector(2 downto 0);
       o_Imm     : out std_logic_vector(31 downto 0));
end immGen;

architecture dataflow of immGen is
  signal s_I, s_S, s_B, s_U, s_J : std_logic_vector(31 downto 0);
begin
  s_I <= (31 downto 12 => i_Inst(31)) & i_Inst(31 downto 20);
  s_S <= (31 downto 12 => i_Inst(31)) & i_Inst(31 downto 25) & i_Inst(11 downto 7);
  s_B <= (31 downto 13 => i_Inst(31)) & i_Inst(31) & i_Inst(7) & i_Inst(30 downto 25) & i_Inst(11 downto 8) & '0';
  s_U <= i_Inst(31 downto 12) & x"000";
  s_J <= (31 downto 21 => i_Inst(31)) & i_Inst(31) & i_Inst(19 downto 12) & i_Inst(20) & i_Inst(30 downto 21) & '0';

  with i_ImmType select
    o_Imm <= s_I when "000",
             s_S when "001",
             s_B when "010",
             s_U when "011",
             s_J when "100",
             s_I when others;
end dataflow;
