-------------------------------------------------------------------------
-- Jacob Dang
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- tb_barrel_shifter.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Runs one edge case per row below through the 32-bit
-- barrel shifter in the three modes the ALU uses (sll, srl, sra).
-- Covers a shift by 0, shifts that use each mux stage (1, 4, 8, 16,
-- and 31 = all stages), bits dropping off the end, and zero fill vs
-- sign fill on right shifts.
-- Each case is held for 10 ns for the waveform.
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

  type test_t is record
    right  : std_logic;  -- 0 = left, 1 = right
    arith  : std_logic;  -- 1 = sign fill (sra)
    d      : std_logic_vector(31 downto 0);
    shamt  : integer range 0 to 31;
    expect : std_logic_vector(31 downto 0);
  end record;
  type test_array_t is array (natural range <>) of test_t;

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

  --  Right Arith D           shamt  expected
  constant c_TESTS : test_array_t := (
    ('0', '0', x"00000001",  0, x"00000001"),  --  0: sll by 0: unchanged
    ('0', '0', x"00000001",  1, x"00000002"),  --  1: sll by 1
    ('0', '0', x"00000001", 31, x"80000000"),  --  2: sll by 31: all stages on
    ('0', '0', x"12345678",  4, x"23456780"),  --  3: sll by 4: top nibble drops off
    ('0', '0', x"FFFFFFFF", 16, x"FFFF0000"),  --  4: sll by 16: zeros shift in
    ('1', '0', x"80000000", 31, x"00000001"),  --  5: srl by 31
    ('1', '0', x"F0000000",  4, x"0F000000"),  --  6: srl by 4: zero fill even with MSB = 1
    ('1', '0', x"12345678",  8, x"00123456"),  --  7: srl by 8
    ('1', '1', x"80000000", 31, x"FFFFFFFF"),  --  8: sra by 31: sign fill gives all ones
    ('1', '1', x"F0000000",  4, x"FF000000"),  --  9: sra by 4: sign fill with MSB = 1
    ('1', '1', x"70000000",  4, x"07000000"),  -- 10: sra by 4: positive fills with 0
    ('1', '1', x"DEADBEEF",  0, x"DEADBEEF")   -- 11: sra by 0: unchanged
  );

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
    variable v_T      : test_t;
  begin
    for i in c_TESTS'range loop
      v_T     := c_TESTS(i);
      s_D     <= v_T.d;
      s_Shamt <= std_logic_vector(to_unsigned(v_T.shamt, 5));
      s_Right <= v_T.right;
      s_Arith <= v_T.arith;
      wait for 10 ns;

      if s_Q /= v_T.expect then
        report "MISMATCH case " & integer'image(i) &
               " right=" & std_logic'image(v_T.right) & " arith=" & std_logic'image(v_T.arith) &
               " D=" & to_hex(v_T.d) & " shamt=" & integer'image(v_T.shamt) &
               " got " & to_hex(s_Q) & " expected " & to_hex(v_T.expect)
               severity error;
        v_Errors := v_Errors + 1;
      end if;
    end loop;

    if v_Errors = 0 then
      report "tb_barrel_shifter: all " & integer'image(c_TESTS'length) & " cases PASSED" severity note;
    else
      report "tb_barrel_shifter: " & integer'image(v_Errors) & " FAILURES" severity failure;
    end if;
    wait;
  end process;

end behavior;
