-------------------------------------------------------------------------
-- Jacob Dang
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- barrel_shifter.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: 32-bit barrel shifter (structural, 2:1 muxes).
--   i_Right = 0:              shift left logical
--   i_Right = 1, i_Arith = 0: shift right logical
--   i_Right = 1, i_Arith = 1: shift right arithmetic
-- Five mux stages shift right by 1, 2, 4, 8, 16 when the matching
-- i_Shamt bit is set. A left shift reverses the bits, shifts right, and
-- reverses the result back, so one right-shift network does all three.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity barrel_shifter is
  port(i_D     : in  std_logic_vector(31 downto 0);
       i_Shamt : in  std_logic_vector(4 downto 0);
       i_Right : in  std_logic;
       i_Arith : in  std_logic;
       o_Q     : out std_logic_vector(31 downto 0));
end barrel_shifter;

architecture structural of barrel_shifter is

  component mux2t1 is
    port(i_S  : in  std_logic;
         i_D0 : in  std_logic;
         i_D1 : in  std_logic;
         o_O  : out std_logic);
  end component;

  type stage_array_t is array (0 to 5) of std_logic_vector(31 downto 0);

  signal s_Stage : stage_array_t;  -- s_Stage(0) is the input, s_Stage(5) the shifted value
  signal s_Fill  : std_logic;      -- bit shifted in from the left
  signal s_Left  : std_logic;

begin

  s_Left <= not i_Right;
  s_Fill <= i_Arith and i_Right and i_D(31);

  -- Reverse the input for a left shift.
  G_IN_REV: for j in 0 to 31 generate
    MUX_IN: mux2t1
      port map(i_S  => s_Left,
               i_D0 => i_D(j),
               i_D1 => i_D(31-j),
               o_O  => s_Stage(0)(j));
  end generate G_IN_REV;

  -- Stage k shifts right by 2**k when i_Shamt(k) = 1.
  G_STAGES: for k in 0 to 4 generate
    G_BITS: for j in 0 to 31 generate
      G_IN_RANGE: if j + 2**k <= 31 generate
        MUX_SH: mux2t1
          port map(i_S  => i_Shamt(k),
                   i_D0 => s_Stage(k)(j),
                   i_D1 => s_Stage(k)(j + 2**k),
                   o_O  => s_Stage(k+1)(j));
      end generate G_IN_RANGE;
      G_FILL: if j + 2**k > 31 generate
        MUX_FILL: mux2t1
          port map(i_S  => i_Shamt(k),
                   i_D0 => s_Stage(k)(j),
                   i_D1 => s_Fill,
                   o_O  => s_Stage(k+1)(j));
      end generate G_FILL;
    end generate G_BITS;
  end generate G_STAGES;

  -- Reverse back for a left shift.
  G_OUT_REV: for j in 0 to 31 generate
    MUX_OUT: mux2t1
      port map(i_S  => s_Left,
               i_D0 => s_Stage(5)(j),
               i_D1 => s_Stage(5)(31-j),
               o_O  => o_Q(j));
  end generate G_OUT_REV;

end structural;
