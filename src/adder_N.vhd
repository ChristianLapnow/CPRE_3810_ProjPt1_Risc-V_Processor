-------------------------------------------------------------------------
-- adder_N.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of an N-bit
-- ripple-carry adder using structural VHDL, generics, and a generate
-- statement. It instantiates N copies of the 1-bit fullAdder.
--
-- Unlike the mux and one's complementor, the bit positions here are NOT
-- independent: each stage's carry-out feeds the next stage's carry-in.
-- That chain is held in the internal signal s_Carry, which is one bit
-- wider than the data so it can hold both the incoming carry at index 0
-- and the final carry-out at index N.
--
-- The entity is named adder_N rather than Adder to avoid a name
-- conflict with the provided Adder.vhd used by the MAC unit.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity adder_N is
  generic(N : integer := 32);
  port(i_A          : in  std_logic_vector(N-1 downto 0);
       i_B          : in  std_logic_vector(N-1 downto 0);
       i_Cin        : in  std_logic;
       o_S          : out std_logic_vector(N-1 downto 0);
       o_Cout       : out std_logic);
end adder_N;

architecture structural of adder_N is

  component fullAdder is
    port(i_A        : in  std_logic;
         i_B        : in  std_logic;
         i_Cin      : in  std_logic;
         o_S        : out std_logic;
         o_Cout     : out std_logic);
  end component;

  -- The carry chain. s_Carry(0) is the adder's carry-in, s_Carry(i+1)
  -- is the carry out of stage i, and s_Carry(N) is the final carry-out.
  signal s_Carry : std_logic_vector(N downto 0);

begin

  -- Feed the external carry-in into the bottom of the chain.
  s_Carry(0) <= i_Cin;

  -- One full adder per bit position, each linked to the next by carry.
  G_NBit_ADDER: for i in 0 to N-1 generate
    ADDI: fullAdder
      port map(i_A    => i_A(i),
               i_B    => i_B(i),
               i_Cin  => s_Carry(i),      -- carry from the stage below
               o_S    => o_S(i),
               o_Cout => s_Carry(i+1));   -- carry to the stage above
  end generate G_NBit_ADDER;

  -- The carry out of the top stage is the adder's carry-out.
  o_Cout <= s_Carry(N);

end structural;