-------------------------------------------------------------------------
-- reg_N.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of an N-bit register
-- with parallel access, write enable, and reset, using structural VHDL,
-- generics, and a generate statement. It instantiates N copies of the
-- provided 1-bit flip-flop (dffg.vhd).
--
-- Every bit position stores independently, so there is no interaction
-- between bits. The clock, reset, and write enable lines are shared by
-- all N flip-flops, which is what makes the whole word load or clear as
-- a single unit.
--
-- Reset behavior is inherited from dffg: active high and asynchronous.
-- Write behavior is synchronous, taking effect on the rising clock edge
-- only when i_WE is high.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity reg_N is
  generic(N : integer := 32);
  port(i_CLK        : in  std_logic;                      -- Clock input
       i_RST        : in  std_logic;                      -- Async reset, active high
       i_WE         : in  std_logic;                      -- Write enable
       i_D          : in  std_logic_vector(N-1 downto 0); -- Data input
       o_Q          : out std_logic_vector(N-1 downto 0));-- Data output
end reg_N;

architecture structural of reg_N is

  component dffg is
    port(i_CLK      : in  std_logic;
         i_RST      : in  std_logic;
         i_WE       : in  std_logic;
         i_D        : in  std_logic;
         o_Q        : out std_logic);
  end component;

begin

  -- One flip-flop per bit position. All of them share the same clock,
  -- reset, and write enable so the register behaves as one N-bit word.
  G_NBit_REG: for i in 0 to N-1 generate
    REGI: dffg
      port map(i_CLK => i_CLK,
               i_RST => i_RST,
               i_WE  => i_WE,
               i_D   => i_D(i),   -- ith bit of the input word
               o_Q   => o_Q(i));  -- ith bit of the output word
  end generate G_NBit_REG;

end structural;