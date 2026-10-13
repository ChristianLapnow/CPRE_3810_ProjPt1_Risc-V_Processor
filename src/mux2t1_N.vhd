-------------------------------------------------------------------------
-- mux2t1_N.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: N-bit wide 2:1 multiplexer built from N copies of the
-- 1-bit structural mux2t1. All N muxes share one select line, so the
-- whole word switches sources together.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1_N is
  generic(N : integer := 32);
  port(i_S          : in  std_logic;
       i_D0         : in  std_logic_vector(N-1 downto 0);
       i_D1         : in  std_logic_vector(N-1 downto 0);
       o_O          : out std_logic_vector(N-1 downto 0));
end mux2t1_N;

architecture structural of mux2t1_N is

  component mux2t1 is
    port(i_S        : in  std_logic;
         i_D0       : in  std_logic;
         i_D1       : in  std_logic;
         o_O        : out std_logic);
  end component;

begin

  G_NBit_MUX: for i in 0 to N-1 generate
    MUXI: mux2t1
      port map(i_S  => i_S,
               i_D0 => i_D0(i),
               i_D1 => i_D1(i),
               o_O  => o_O(i));
  end generate G_NBit_MUX;

end structural;