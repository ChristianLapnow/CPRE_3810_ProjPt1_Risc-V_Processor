-------------------------------------------------------------------------
-- Jacob Dang
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- tb_barrel_shifter.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Checks the 32-bit barrel shifter against numeric_std
-- shifts for every shift amount (0-31) in all three modes the ALU uses:
-- logical left, logical right, and arithmetic right. Each case is held
-- for 10 ns for the waveform.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_barrel_shifter is
end tb_barrel_shifter;

architecture behavior of tb_barrel_shifter is

  component barrel_shifter is
    port(i_D     : in  std_logic_vector(31 downto 0);
         i_Shamt : in  std_logic_vector(4 downto 0);
         i_Right : in  std_logic;
         i_Arith : in  std_logic;
         o_Q     : out std_logic_vector(31 downto 0));
  end component;

  type word_array_t is array (natural range <>) of std_logic_vector(31 downto 0);

  -- Hex string for report messages (to_hstring needs VHDL-2008).
  function to_hex(v : std_logic_vector(31 downto 0)) return string is
    constant c_DIGITS : string(1 to 16) := "0123456789ABCDEF";
    variable v_Str    : string(1 to 8);
    variable v_Nibble : std_logic_vector(3 downto 0);
  begin
    for i in 0 to 7 loop
      v_Nibble := v(31 - 4*i downto 28 - 4*i);
      if Is_X(v_Nibble) then
        v_Str(i+1) := 'X';
      else
        v_Str(i+1) := c_DIGITS(to_integer(unsigned(v_Nibble)) + 1);
      end if;
    end loop;
    return v_Str;
  end function;

  constant c_VALUES : word_array_t := (
    x"80000000", x"00000001", x"DEADBEEF", x"7FFFFFFF", x"FFFFFFFF", x"12345678");

  signal s_D, s_Q : std_logic_vector(31 downto 0) := (others => '0');
  signal s_Shamt  : std_logic_vector(4 downto 0)  := (others => '0');
  signal s_Right  : std_logic := '0';
  signal s_Arith  : std_logic := '0';

begin

  DUT0: barrel_shifter
    port map(i_D     => s_D,
             i_Shamt => s_Shamt,
             i_Right => s_Right,
             i_Arith => s_Arith,
             o_Q     => s_Q);

  P_TEST : process
    variable v_Errors : integer := 0;
    variable v_Count  : integer := 0;
    variable v_Exp    : std_logic_vector(31 downto 0);
  begin
    -- mode 0: sll, mode 1: srl, mode 2: sra
    for mode in 0 to 2 loop
      for i in c_VALUES'range loop
        for sh in 0 to 31 loop
          case mode is
            when 0      => v_Exp := std_logic_vector(shift_left(unsigned(c_VALUES(i)), sh));
            when 1      => v_Exp := std_logic_vector(shift_right(unsigned(c_VALUES(i)), sh));
            when others => v_Exp := std_logic_vector(shift_right(signed(c_VALUES(i)), sh));
          end case;

          s_D     <= c_VALUES(i);
          s_Shamt <= std_logic_vector(to_unsigned(sh, 5));
          if mode = 0 then
            s_Right <= '0';
          else
            s_Right <= '1';
          end if;
          if mode = 2 then
            s_Arith <= '1';
          else
            s_Arith <= '0';
          end if;
          wait for 10 ns;
          v_Count := v_Count + 1;

          if s_Q /= v_Exp then
            report "MISMATCH mode=" & integer'image(mode) & " D=" & to_hex(c_VALUES(i)) &
                   " shamt=" & integer'image(sh) &
                   " got " & to_hex(s_Q) & " expected " & to_hex(v_Exp)
                   severity error;
            v_Errors := v_Errors + 1;
          end if;
        end loop;
      end loop;
    end loop;

    if v_Errors = 0 then
      report "tb_barrel_shifter: all " & integer'image(v_Count) & " cases PASSED" severity note;
    else
      report "tb_barrel_shifter: " & integer'image(v_Errors) & " FAILURES" severity failure;
    end if;
    wait;
  end process;

end behavior;
