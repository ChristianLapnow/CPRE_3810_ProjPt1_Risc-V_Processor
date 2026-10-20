-------------------------------------------------------------------------
-- dffg_s.vhd
-- Same as Lab 2 dffg, but async reset SETS the output to '1'.
-- Used for the PC bits that must be 1 at reset (PC resets to 0x00400000).
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity dffg_s is
  port(i_CLK : in  std_logic;
       i_RST : in  std_logic;
       i_WE  : in  std_logic;
       i_D   : in  std_logic;
       o_Q   : out std_logic);
end dffg_s;

architecture mixed of dffg_s is
  signal s_D : std_logic;
  signal s_Q : std_logic;
begin
  o_Q <= s_Q;

  with i_WE select
    s_D <= i_D when '1',
           s_Q when others;

  process (i_CLK, i_RST)
  begin
    if (i_RST = '1') then
      s_Q <= '1';
    elsif (rising_edge(i_CLK)) then
      s_Q <= s_D;
    end if;
  end process;
end mixed;
