-------------------------------------------------------------------------
-- Jacob Dang
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- tb_alu.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Runs one edge case per row below through the ALU and checks
-- o_Result and o_Zero. Every operation gets at least two cases, aimed at
-- the places ALUs usually break: overflow wraparound, SLT when A - B
-- overflows, signed vs unsigned compares, and shifts that must use only
-- B[4:0]. The expected results were produced by running the matching
-- RV32I instruction on the same operands in RARS.
-- Each case is held for 10 ns; s_Op shows the operation in the waveform.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_alu is
end tb_alu;

architecture behavior of tb_alu is

  component alu is
    port(i_A          : in  std_logic_vector(31 downto 0);
         i_B          : in  std_logic_vector(31 downto 0);
         i_ALUControl : in  std_logic_vector(3 downto 0);
         o_Result     : out std_logic_vector(31 downto 0);
         o_Zero       : out std_logic);
  end component;

  -- ALUControl codes (match control_unit.vhd)
  constant c_ADD  : integer := 0;
  constant c_SUB  : integer := 1;
  constant c_AND  : integer := 2;
  constant c_OR   : integer := 3;
  constant c_XOR  : integer := 4;
  constant c_SLT  : integer := 5;
  constant c_SLTU : integer := 6;
  constant c_SLL  : integer := 7;
  constant c_SRL  : integer := 8;
  constant c_SRA  : integer := 9;

  type op_name_array_t is array (0 to 9) of string(1 to 4);
  constant c_OP_NAMES : op_name_array_t := (
    "add ", "sub ", "and ", "or  ", "xor ", "slt ", "sltu", "sll ", "srl ", "sra ");

  type test_t is record
    op     : integer range 0 to 9;
    a      : std_logic_vector(31 downto 0);
    b      : std_logic_vector(31 downto 0);
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

  --  op       A            B            expected
  constant c_TESTS : test_array_t := (
    (c_ADD,  x"00000000", x"00000000", x"00000000"),  --  0: 0 + 0 = 0, Zero = 1
    (c_ADD,  x"FFFFFFFF", x"00000001", x"00000000"),  --  1: -1 + 1 = 0, carry out dropped, Zero = 1
    (c_ADD,  x"7FFFFFFF", x"00000001", x"80000000"),  --  2: max + 1 wraps to min
    (c_SUB,  x"12345678", x"12345678", x"00000000"),  --  3: equal operands -> 0, Zero = 1 (beq taken)
    (c_SUB,  x"80000000", x"00000001", x"7FFFFFFF"),  --  4: min - 1 wraps to max
    (c_SUB,  x"FFFFFFFB", x"7FFFFFFF", x"7FFFFFFC"),  --  5: -5 - max wraps
    (c_AND,  x"AAAAAAAA", x"55555555", x"00000000"),  --  6: no common bits -> 0, Zero = 1
    (c_OR,   x"AAAAAAAA", x"55555555", x"FFFFFFFF"),  --  7: alternating bits -> all ones
    (c_XOR,  x"FFFFFFFB", x"7FFFFFFF", x"80000004"),  --  8: differs from or where both bits are 1
    (c_SLT,  x"80000000", x"00000001", x"00000001"),  --  9: min < 1 = 1 while A - B overflows
    (c_SLT,  x"FFFFFFFB", x"7FFFFFFF", x"00000001"),  -- 10: -5 < max = 1 while A - B overflows
    (c_SLT,  x"7FFFFFFF", x"FFFFFFFB", x"00000000"),  -- 11: max < -5 = 0 while A - B overflows
    (c_SLT,  x"00000005", x"FFFFFFFB", x"00000000"),  -- 12: 5 < -5 = 0 (signed)
    (c_SLT,  x"12345678", x"12345678", x"00000000"),  -- 13: equal -> 0, Zero = 1 (bge taken)
    (c_SLTU, x"00000005", x"FFFFFFFB", x"00000001"),  -- 14: 5 < 0xFFFFFFFB = 1 (unsigned)
    (c_SLTU, x"FFFFFFFB", x"7FFFFFFF", x"00000000"),  -- 15: 0xFFFFFFFB < max = 0 (unsigned)
    (c_SLTU, x"12345678", x"12345678", x"00000000"),  -- 16: equal -> 0
    (c_SLL,  x"00000001", x"0000001F", x"80000000"),  -- 17: 1 << 31
    (c_SLL,  x"DEADBEEF", x"00000020", x"DEADBEEF"),  -- 18: B = 32: only B[4:0] used, shift by 0
    (c_SRL,  x"80000000", x"0000001F", x"00000001"),  -- 19: min >> 31 = 1 (zero fill)
    (c_SRL,  x"80000000", x"00000405", x"04000000"),  -- 20: B = 0x405 (srai encoding): shift by 5
    (c_SRA,  x"80000000", x"0000001F", x"FFFFFFFF"),  -- 21: min >> 31 = all ones (sign fill)
    (c_SRA,  x"80000000", x"00000405", x"FC000000"),  -- 22: B = 0x405 (srai encoding): shift by 5
    (c_SRA,  x"12345678", x"00000004", x"01234567")   -- 23: positive >> 4 fills with 0
  );

  signal s_A, s_B, s_Result : std_logic_vector(31 downto 0) := (others => '0');
  signal s_ALUControl       : std_logic_vector(3 downto 0)  := (others => '0');
  signal s_Zero             : std_logic;
  signal s_Op               : string(1 to 4) := "    ";

begin

  DUT0: alu
    port map(i_A          => s_A,
             i_B          => s_B,
             i_ALUControl => s_ALUControl,
             o_Result     => s_Result,
             o_Zero       => s_Zero);

  P_TEST : process
    variable v_Errors  : integer := 0;
    variable v_T       : test_t;
    variable v_ExpZero : std_logic;
  begin
    for i in c_TESTS'range loop
      v_T := c_TESTS(i);
      if v_T.expect = x"00000000" then
        v_ExpZero := '1';
      else
        v_ExpZero := '0';
      end if;

      s_A          <= v_T.a;
      s_B          <= v_T.b;
      s_ALUControl <= std_logic_vector(to_unsigned(v_T.op, 4));
      s_Op         <= c_OP_NAMES(v_T.op);
      wait for 10 ns;

      if s_Result /= v_T.expect or s_Zero /= v_ExpZero then
        report "MISMATCH case " & integer'image(i) & " " & c_OP_NAMES(v_T.op) &
               " A=" & to_hex(v_T.a) & " B=" & to_hex(v_T.b) &
               " got " & to_hex(s_Result) & " zero=" & std_logic'image(s_Zero) &
               " expected " & to_hex(v_T.expect) & " zero=" & std_logic'image(v_ExpZero)
               severity error;
        v_Errors := v_Errors + 1;
      end if;
    end loop;

    if v_Errors = 0 then
      report "tb_alu: all " & integer'image(c_TESTS'length) & " cases PASSED" severity note;
    else
      report "tb_alu: " & integer'image(v_Errors) & " FAILURES" severity failure;
    end if;
    wait;
  end process;

end behavior;
