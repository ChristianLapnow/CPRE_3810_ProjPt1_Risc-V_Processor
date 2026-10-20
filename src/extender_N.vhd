-------------------------------------------------------------------------
-- extender_N.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Extends an N-bit value to 32 bits.
--   i_Sign = '1' : sign extension (fill with i_D(N-1))
--   i_Sign = '0' : zero extension (fill with '0')
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity extender_N is
  generic(N : integer := 12);
  port(i_D          : in  std_logic_vector(N-1 downto 0);
       i_Sign       : in  std_logic;
       o_O          : out std_logic_vector(31 downto 0));
end extender_N;

architecture dataflow of extender_N is
  signal s_Fill : std_logic;
begin

  s_Fill <= i_D(N-1) and i_Sign;

  o_O(N-1 downto 0)  <= i_D;
  o_O(31 downto N)   <= (others => s_Fill);

end dataflow;
