-- loadUnit.vhd
-- picks the byte/half out of the dmem word for lb, lh, lbu, lhu

library IEEE;
use IEEE.std_logic_1164.all;

entity loadUnit is
  port(i_Word   : in  std_logic_vector(31 downto 0);
       i_Addr   : in  std_logic_vector(1 downto 0);
       i_Funct3 : in  std_logic_vector(2 downto 0);
       o_Data   : out std_logic_vector(31 downto 0));
end loadUnit;

architecture structural of loadUnit is

  component mux2t1_N is
    generic(N : integer := 32);
    port(i_S        : in  std_logic;
         i_D0, i_D1 : in  std_logic_vector(N-1 downto 0);
         o_O        : out std_logic_vector(N-1 downto 0));
  end component;

  component extender_N is
    generic(N : integer := 12);
    port(i_D    : in  std_logic_vector(N-1 downto 0);
         i_Sign : in  std_logic;
         o_O    : out std_logic_vector(31 downto 0));
  end component;

  component invg is
    port(i_A : in  std_logic;
         o_F : out std_logic);
  end component;

  signal s_ByteLo, s_ByteHi, s_Byte : std_logic_vector(7 downto 0);
  signal s_Half                     : std_logic_vector(15 downto 0);
  signal s_Sign                     : std_logic;
  signal s_ByteExt, s_HalfExt, s_Sub : std_logic_vector(31 downto 0);

begin

  -- funct3(2) = 1 for lbu/lhu
  INV0: invg port map(i_A => i_Funct3(2), o_F => s_Sign);

  -- byte select
  MUX_B01: mux2t1_N generic map(N => 8)
    port map(i_S => i_Addr(0), i_D0 => i_Word(7 downto 0), i_D1 => i_Word(15 downto 8), o_O => s_ByteLo);
  MUX_B23: mux2t1_N generic map(N => 8)
    port map(i_S => i_Addr(0), i_D0 => i_Word(23 downto 16), i_D1 => i_Word(31 downto 24), o_O => s_ByteHi);
  MUX_B: mux2t1_N generic map(N => 8)
    port map(i_S => i_Addr(1), i_D0 => s_ByteLo, i_D1 => s_ByteHi, o_O => s_Byte);

  -- half select
  MUX_H: mux2t1_N generic map(N => 16)
    port map(i_S => i_Addr(1), i_D0 => i_Word(15 downto 0), i_D1 => i_Word(31 downto 16), o_O => s_Half);

  -- extenders from lab 2
  EXT_B: extender_N generic map(N => 8)
    port map(i_D => s_Byte, i_Sign => s_Sign, o_O => s_ByteExt);
  EXT_H: extender_N generic map(N => 16)
    port map(i_D => s_Half, i_Sign => s_Sign, o_O => s_HalfExt);

  -- funct3(0): byte or half, funct3(1): word
  MUX_SZ: mux2t1_N generic map(N => 32)
    port map(i_S => i_Funct3(0), i_D0 => s_ByteExt, i_D1 => s_HalfExt, o_O => s_Sub);
  MUX_W: mux2t1_N generic map(N => 32)
    port map(i_S => i_Funct3(1), i_D0 => s_Sub, i_D1 => i_Word, o_O => o_Data);

end structural;
