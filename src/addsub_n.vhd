-------------------------------------------------------------------------
-- Jacob Dang
-------------------------------------------------------------------------
-- addsub_n.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: N-bit ripple-carry adder/subtractor (structural).
--   i_Sub = 0: o_S = A + B
--   i_Sub = 1: o_S = A - B, computed as A + not(B) + 1
-- o_Cout is the carry out of the MSB. For subtract, o_Cout = 1 means
-- A >= B unsigned (no borrow).
-- o_Ovfl is signed overflow: carry into the MSB xor carry out of the MSB.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity addsub_n is
  generic(N : integer := 32);
  port(i_A    : in  std_logic_vector(N-1 downto 0);
       i_B    : in  std_logic_vector(N-1 downto 0);
       i_Sub  : in  std_logic;
       o_S    : out std_logic_vector(N-1 downto 0);
       o_Cout : out std_logic;
       o_Ovfl : out std_logic);
end addsub_n;

architecture structural of addsub_n is

  component fullAdder is
    port(i_A    : in  std_logic;
         i_B    : in  std_logic;
         i_Cin  : in  std_logic;
         o_S    : out std_logic;
         o_Cout : out std_logic);
  end component;

  signal s_B : std_logic_vector(N-1 downto 0);  -- B, inverted when subtracting
  signal s_C : std_logic_vector(N downto 0);    -- s_C(i) is the carry into bit i

begin

  s_B    <= i_B xor (N-1 downto 0 => i_Sub);
  s_C(0) <= i_Sub;

  G_ADDERS: for i in 0 to N-1 generate
    FA: fullAdder
      port map(i_A    => i_A(i),
               i_B    => s_B(i),
               i_Cin  => s_C(i),
               o_S    => o_S(i),
               o_Cout => s_C(i+1));
  end generate G_ADDERS;

  o_Cout <= s_C(N);
  o_Ovfl <= s_C(N) xor s_C(N-1);

end structural;
