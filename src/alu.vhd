-------------------------------------------------------------------------
-- Jacob Dang
-------------------------------------------------------------------------
-- alu.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: 32-bit ALU for the single-cycle RISC-V processor.
--
-- ALUControl encoding (matches control_unit.vhd):
--   0000 ADD   0001 SUB   0010 AND   0011 OR    0100 XOR
--   0101 SLT   0110 SLTU  0111 SLL   1000 SRL   1001 SRA
--
-- SUB, SLT and SLTU all use the adder in subtract mode (A - B):
--   SLT  = sign of (A - B) xor signed overflow
--   SLTU = no carry out of (A - B), i.e. A < B unsigned
-- Shifts use only B[4:0], as RV32I does (srai's immediate has bit 10 set).
-- o_Zero is 1 when the final result is 0. Branches use it for beq/bne
-- (after SUB) and blt/bge/bltu/bgeu (after SLT/SLTU).
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity alu is
  port(i_A          : in  std_logic_vector(31 downto 0);
       i_B          : in  std_logic_vector(31 downto 0);
       i_ALUControl : in  std_logic_vector(3 downto 0);
       o_Result     : out std_logic_vector(31 downto 0);
       o_Zero       : out std_logic);
end alu;

architecture structural of alu is

  component addsub_n is
    generic(N : integer := 32);
    port(i_A    : in  std_logic_vector(N-1 downto 0);
         i_B    : in  std_logic_vector(N-1 downto 0);
         i_Sub  : in  std_logic;
         o_S    : out std_logic_vector(N-1 downto 0);
         o_Cout : out std_logic;
         o_Ovfl : out std_logic);
  end component;

  component barrel_shifter is
    port(i_D     : in  std_logic_vector(31 downto 0);
         i_Shamt : in  std_logic_vector(4 downto 0);
         i_Right : in  std_logic;
         i_Arith : in  std_logic;
         o_Q     : out std_logic_vector(31 downto 0));
  end component;

  signal s_Sub    : std_logic;
  signal s_Sum    : std_logic_vector(31 downto 0);
  signal s_Cout   : std_logic;
  signal s_Ovfl   : std_logic;
  signal s_Slt    : std_logic_vector(31 downto 0);
  signal s_Sltu   : std_logic_vector(31 downto 0);
  signal s_Shift  : std_logic_vector(31 downto 0);
  signal s_Result : std_logic_vector(31 downto 0);

begin

  ---------------------------------------------------------------------
  -- Adder/subtractor (ADD, SUB, SLT, SLTU)
  ---------------------------------------------------------------------
  s_Sub <= '1' when (i_ALUControl = "0001" or i_ALUControl = "0101" or i_ALUControl = "0110") else '0';

  ADDSUB: addsub_n
    generic map(N => 32)
    port map(i_A    => i_A,
             i_B    => i_B,
             i_Sub  => s_Sub,
             o_S    => s_Sum,
             o_Cout => s_Cout,
             o_Ovfl => s_Ovfl);

  s_Slt  <= (31 downto 1 => '0') & (s_Sum(31) xor s_Ovfl);
  s_Sltu <= (31 downto 1 => '0') & (not s_Cout);

  ---------------------------------------------------------------------
  -- Shifter (SLL 0111, SRL 1000, SRA 1001)
  -- ALUControl(3) picks right vs left, ALUControl(0) picks arithmetic
  -- for SRA. The shifter ignores i_Arith on left shifts.
  ---------------------------------------------------------------------
  SHIFTER: barrel_shifter
    port map(i_D     => i_A,
             i_Shamt => i_B(4 downto 0),
             i_Right => i_ALUControl(3),
             i_Arith => i_ALUControl(0),
             o_Q     => s_Shift);

  ---------------------------------------------------------------------
  -- Result select
  ---------------------------------------------------------------------
  with i_ALUControl select
    s_Result <= s_Sum         when "0000" | "0001",
                i_A and i_B   when "0010",
                i_A or i_B    when "0011",
                i_A xor i_B   when "0100",
                s_Slt         when "0101",
                s_Sltu        when "0110",
                s_Shift       when "0111" | "1000" | "1001",
                (others => '0') when others;

  o_Result <= s_Result;
  o_Zero   <= '1' when s_Result = x"00000000" else '0';

end structural;
