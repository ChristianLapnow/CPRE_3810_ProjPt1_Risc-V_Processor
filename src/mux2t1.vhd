-------------------------------------------------------------------------
-- Jacob Dang
-------------------------------------------------------------------------
-- mux2t1.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: 1-bit 2:1 mux (dataflow). o_O = i_D0 when i_S = 0,
-- i_D1 when i_S = 1.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1 is
  port(i_S  : in  std_logic;
       i_D0 : in  std_logic;
       i_D1 : in  std_logic;
       o_O  : out std_logic);
end mux2t1;

architecture dataflow of mux2t1 is
begin

  o_O <= (i_D0 and not i_S) or (i_D1 and i_S);

end dataflow;
