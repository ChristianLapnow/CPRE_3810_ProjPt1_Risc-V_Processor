-------------------------------------------------------------------------
-- Jacob Dang
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- tb_addsub_n.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Runs one edge case per row below through the 32-bit
-- adder/subtractor and checks the sum, carry out, and signed overflow.
-- Covers carry out without overflow, overflow in both directions for
-- add and subtract, and borrow (carry out = 0) on subtract.
-- Each case is held for 10 ns for the waveform.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_addsub_n is
end tb_addsub_n;

architecture behavior of tb_addsub_n is

  component addsub_n is
    generic(N : integer := 32);
    port(i_A    : in  std_logic_vector(N-1 downto 0);
         i_B    : in  std_logic_vector(N-1 downto 0);
         i_Sub  : in  std_logic;
         o_S    : out std_logic_vector(N-1 downto 0);
         o_Cout : out std_logic;
         o_Ovfl : out std_logic);
  end component;

  type test_t is record
    sub  : std_logic;
    a    : std_logic_vector(31 downto 0);
    b    : std_logic_vector(31 downto 0);
    s    : std_logic_vector(31 downto 0);
    cout : std_logic;
    ovfl : std_logic;
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

  --  sub  A            B            expected S   Cout Ovfl
  constant c_TESTS : test_array_t := (
    ('0', x"00000000", x"00000000", x"00000000", '0', '0'),  --  0: 0 + 0
    ('0', x"00000001", x"00000001", x"00000002", '0', '0'),  --  1: 1 + 1 = 2
    ('0', x"FFFFFFFF", x"00000001", x"00000000", '1', '0'),  --  2: -1 + 1: carry out, no overflow
    ('0', x"FFFFFFFB", x"00000005", x"00000000", '1', '0'),  --  3: -5 + 5 = 0: carry out, no overflow
    ('0', x"7FFFFFFF", x"00000001", x"80000000", '0', '1'),  --  4: max + 1: overflow (pos + pos = neg)
    ('0', x"80000000", x"80000000", x"00000000", '1', '1'),  --  5: min + min: overflow (neg + neg = pos)
    ('1', x"00000005", x"00000005", x"00000000", '1', '0'),  --  6: 5 - 5 = 0: no borrow (Cout = 1)
    ('1', x"00000001", x"00000002", x"FFFFFFFF", '0', '0'),  --  7: 1 - 2 = -1: borrow (Cout = 0)
    ('1', x"80000000", x"00000001", x"7FFFFFFF", '1', '1'),  --  8: min - 1: overflow (neg - pos = pos)
    ('1', x"7FFFFFFF", x"FFFFFFFF", x"80000000", '0', '1'),  --  9: max - (-1): overflow (pos - neg = neg)
    ('1', x"00000000", x"80000000", x"80000000", '0', '1')   -- 10: 0 - min: overflow (min has no positive)
  );

  signal s_A, s_B, s_S : std_logic_vector(31 downto 0) := (others => '0');
  signal s_Sub         : std_logic := '0';
  signal s_Cout        : std_logic;
  signal s_Ovfl        : std_logic;

begin

  DUT0: addsub_n
    generic map(N => 32)
    port map(i_A    => s_A,
             i_B    => s_B,
             i_Sub  => s_Sub,
             o_S    => s_S,
             o_Cout => s_Cout,
             o_Ovfl => s_Ovfl);

  P_TEST : process
    variable v_Errors : integer := 0;
    variable v_T      : test_t;
  begin
    for i in c_TESTS'range loop
      v_T   := c_TESTS(i);
      s_A   <= v_T.a;
      s_B   <= v_T.b;
      s_Sub <= v_T.sub;
      wait for 10 ns;

      if s_S /= v_T.s or s_Cout /= v_T.cout or s_Ovfl /= v_T.ovfl then
        report "MISMATCH case " & integer'image(i) & " sub=" & std_logic'image(v_T.sub) &
               " A=" & to_hex(v_T.a) & " B=" & to_hex(v_T.b) &
               " got S=" & to_hex(s_S) & " C=" & std_logic'image(s_Cout) & " V=" & std_logic'image(s_Ovfl) &
               " expected S=" & to_hex(v_T.s) & " C=" & std_logic'image(v_T.cout) & " V=" & std_logic'image(v_T.ovfl)
               severity error;
        v_Errors := v_Errors + 1;
      end if;
    end loop;

    if v_Errors = 0 then
      report "tb_addsub_n: all " & integer'image(c_TESTS'length) & " cases PASSED" severity note;
    else
      report "tb_addsub_n: " & integer'image(v_Errors) & " FAILURES" severity failure;
    end if;
    wait;
  end process;

end behavior;
