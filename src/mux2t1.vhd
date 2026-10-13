-------------------------------------------------------------------------
-- mux2t1.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: 2:1 multiplexer implemented in structural VHDL using the
-- provided invg, andg2, and org2 gate primitives.
--
-- o_O = (i_D0 AND (NOT i_S)) OR (i_D1 AND i_S)
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1 is
  port(i_S          : in  std_logic;
       i_D0         : in  std_logic;
       i_D1         : in  std_logic;
       o_O          : out std_logic);
end mux2t1;

architecture structural of mux2t1 is

  component invg is
    port(i_A        : in  std_logic;
         o_F        : out std_logic);
  end component;

  component andg2 is
    port(i_A        : in  std_logic;
         i_B        : in  std_logic;
         o_F        : out std_logic);
  end component;

  component org2 is
    port(i_A        : in  std_logic;
         i_B        : in  std_logic;
         o_F        : out std_logic);
  end component;

  signal s_nS    : std_logic;   -- inverted select
  signal s_and0  : std_logic;   -- i_D0 path
  signal s_and1  : std_logic;   -- i_D1 path

begin

  -- Invert the select line so we can gate the D0 path with it.
  g_Not : invg
    port map(i_A => i_S,
             o_F => s_nS);

  -- Pass i_D0 through only when i_S = '0'.
  g_And0 : andg2
    port map(i_A => i_D0,
             i_B => s_nS,
             o_F => s_and0);

  -- Pass i_D1 through only when i_S = '1'.
  g_And1 : andg2
    port map(i_A => i_D1,
             i_B => i_S,
             o_F => s_and1);

  -- Exactly one AND path can be high at a time, so OR them together.
  g_Or : org2
    port map(i_A => s_and0,
             i_B => s_and1,
             o_F => o_O);

end structural;