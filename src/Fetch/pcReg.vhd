-------------------------------------------------------------------------
-- pcReg.vhd
-- 32-bit program counter register with a configurable reset value.
-- Each bit is a dffg (resets to 0) or dffg_s (resets to 1) chosen by
-- the matching bit of RESET_VAL. Default reset = 0x00400000 (RARS text base).
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity pcReg is
  generic(N         : integer := 32;
          RESET_VAL : std_logic_vector(31 downto 0) := x"00400000");
  port(i_CLK : in  std_logic;
       i_RST : in  std_logic;
       i_WE  : in  std_logic;
       i_D   : in  std_logic_vector(N-1 downto 0);
       o_Q   : out std_logic_vector(N-1 downto 0));
end pcReg;

architecture structural of pcReg is

  component dffg is
    port(i_CLK, i_RST, i_WE, i_D : in std_logic;
         o_Q : out std_logic);
  end component;

  component dffg_s is
    port(i_CLK, i_RST, i_WE, i_D : in std_logic;
         o_Q : out std_logic);
  end component;

begin

  G_BITS : for i in 0 to N-1 generate

    G_ZERO : if RESET_VAL(i) = '0' generate
      BIT_I : dffg port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
                            i_D => i_D(i), o_Q => o_Q(i));
    end generate G_ZERO;

    G_ONE : if RESET_VAL(i) = '1' generate
      BIT_I : dffg_s port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
                              i_D => i_D(i), o_Q => o_Q(i));
    end generate G_ONE;

  end generate G_BITS;

end structural;
