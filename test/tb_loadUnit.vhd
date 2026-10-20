-- tb_loadUnit.vhd
-- test word 0x8001FF7F has bytes 7F, FF, 01, 80 so we get pos and neg values

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_loadUnit is
end tb_loadUnit;

architecture behavior of tb_loadUnit is

  component loadUnit is
    port(i_Word   : in  std_logic_vector(31 downto 0);
         i_Addr   : in  std_logic_vector(1 downto 0);
         i_Funct3 : in  std_logic_vector(2 downto 0);
         o_Data   : out std_logic_vector(31 downto 0));
  end component;

  signal s_Word   : std_logic_vector(31 downto 0) := (others => '0');
  signal s_Addr   : std_logic_vector(1 downto 0)  := "00";
  signal s_Funct3 : std_logic_vector(2 downto 0)  := "010";
  signal s_Data   : std_logic_vector(31 downto 0);
  signal s_Expect : std_logic_vector(31 downto 0) := (others => '0');
  signal s_Case   : integer := 0;

  constant LB  : std_logic_vector(2 downto 0) := "000";
  constant LH  : std_logic_vector(2 downto 0) := "001";
  constant LW  : std_logic_vector(2 downto 0) := "010";
  constant LBU : std_logic_vector(2 downto 0) := "100";
  constant LHU : std_logic_vector(2 downto 0) := "101";

begin

  DUT: loadUnit
    port map(i_Word => s_Word, i_Addr => s_Addr, i_Funct3 => s_Funct3, o_Data => s_Data);

  P_TEST: process
    variable v_Errors : integer := 0;
    variable v_Case   : integer := 0;

    procedure check(w   : in std_logic_vector(31 downto 0);
                    a   : in std_logic_vector(1 downto 0);
                    f3  : in std_logic_vector(2 downto 0);
                    exp : in std_logic_vector(31 downto 0)) is
    begin
      v_Case   := v_Case + 1;
      s_Case   <= v_Case;
      s_Word   <= w;
      s_Addr   <= a;
      s_Funct3 <= f3;
      s_Expect <= exp;
      wait for 10 ns;
      if s_Data /= exp then
        v_Errors := v_Errors + 1;
        report "Mismatch in case " & integer'image(v_Case) severity error;
      end if;
    end procedure;

  begin
    -- lb
    check(x"8001FF7F", "00", LB,  x"0000007F");
    check(x"8001FF7F", "01", LB,  x"FFFFFFFF");
    check(x"8001FF7F", "10", LB,  x"00000001");
    check(x"8001FF7F", "11", LB,  x"FFFFFF80");
    -- lbu
    check(x"8001FF7F", "00", LBU, x"0000007F");
    check(x"8001FF7F", "01", LBU, x"000000FF");
    check(x"8001FF7F", "10", LBU, x"00000001");
    check(x"8001FF7F", "11", LBU, x"00000080");
    -- lh / lhu
    check(x"8001FF7F", "00", LH,  x"FFFFFF7F");
    check(x"8001FF7F", "10", LH,  x"FFFF8001");
    check(x"8001FF7F", "00", LHU, x"0000FF7F");
    check(x"8001FF7F", "10", LHU, x"00008001");
    -- lw
    check(x"8001FF7F", "00", LW,  x"8001FF7F");
    -- all positive word
    check(x"12345678", "00", LB,  x"00000078");
    check(x"12345678", "11", LB,  x"00000012");
    check(x"12345678", "10", LH,  x"00001234");
    check(x"12345678", "00", LHU, x"00005678");
    check(x"12345678", "00", LW,  x"12345678");

    report "tb_loadUnit done: " & integer'image(v_Errors) & " errors" severity note;
    wait;
  end process;

end behavior;
