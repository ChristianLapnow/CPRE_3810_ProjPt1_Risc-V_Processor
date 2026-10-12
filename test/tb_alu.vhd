-------------------------------------------------------------------------
-- Jacob Dang
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- tb_alu.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Runs all 10 ALU operations on each operand pair below and
-- checks o_Result and o_Zero. The expected results were produced by
-- running the matching RV32I instructions (add, sub, and, or, xor, slt,
-- sltu, sll, srl, sra) on the same operands in RARS.
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

  -- Indexed by ALUControl: 0 ADD 1 SUB 2 AND 3 OR 4 XOR 5 SLT 6 SLTU 7 SLL 8 SRL 9 SRA
  type result_array_t is array (0 to 9) of std_logic_vector(31 downto 0);
  type op_name_array_t is array (0 to 9) of string(1 to 4);

  type vector_t is record
    a      : std_logic_vector(31 downto 0);
    b      : std_logic_vector(31 downto 0);
    expect : result_array_t;
  end record;
  type vector_array_t is array (natural range <>) of vector_t;

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

  constant c_OP_NAMES : op_name_array_t := (
    "add ", "sub ", "and ", "or  ", "xor ", "slt ", "sltu", "sll ", "srl ", "sra ");

  --  A            B             add          sub          and          or           xor
  --                             slt          sltu         sll          srl          sra
  constant c_VECTORS : vector_array_t := (
    -- 0: zeros
    (x"00000000", x"00000000", (x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
                             x"00000000", x"00000000", x"00000000", x"00000000", x"00000000")),
    -- 1: ones
    (x"00000001", x"00000001", (x"00000002", x"00000000", x"00000001", x"00000001", x"00000000",
                             x"00000000", x"00000000", x"00000002", x"00000000", x"00000000")),
    -- 2: -1 and 1 (add carries out)
    (x"FFFFFFFF", x"00000001", (x"00000000", x"FFFFFFFE", x"00000001", x"FFFFFFFF", x"FFFFFFFE",
                             x"00000001", x"00000000", x"FFFFFFFE", x"7FFFFFFF", x"FFFFFFFF")),
    -- 3: add overflows to 0x80000000
    (x"7FFFFFFF", x"00000001", (x"80000000", x"7FFFFFFE", x"00000001", x"7FFFFFFF", x"7FFFFFFE",
                             x"00000000", x"00000000", x"FFFFFFFE", x"3FFFFFFF", x"3FFFFFFF")),
    -- 4: sub overflows to 0x7FFFFFFF
    (x"80000000", x"00000001", (x"80000001", x"7FFFFFFF", x"00000000", x"80000001", x"80000001",
                             x"00000001", x"00000000", x"00000000", x"40000000", x"C0000000")),
    -- 5: slt where A-B overflows (-5 vs max)
    (x"FFFFFFFB", x"7FFFFFFF", (x"7FFFFFFA", x"7FFFFFFC", x"7FFFFFFB", x"FFFFFFFF", x"80000004",
                             x"00000001", x"00000000", x"80000000", x"00000001", x"FFFFFFFF")),
    -- 6: slt where A-B overflows (max vs -5)
    (x"7FFFFFFF", x"FFFFFFFB", (x"7FFFFFFA", x"80000004", x"7FFFFFFB", x"FFFFFFFF", x"80000004",
                             x"00000000", x"00000001", x"F8000000", x"0000000F", x"0000000F")),
    -- 7: min vs max
    (x"80000000", x"7FFFFFFF", (x"FFFFFFFF", x"00000001", x"00000000", x"FFFFFFFF", x"FFFFFFFF",
                             x"00000001", x"00000000", x"00000000", x"00000001", x"FFFFFFFF")),
    -- 8: equal operands (sub = 0)
    (x"12345678", x"12345678", (x"2468ACF0", x"00000000", x"12345678", x"12345678", x"00000000",
                             x"00000000", x"00000000", x"78000000", x"00000012", x"00000012")),
    -- 9: 5 vs -5: signed and unsigned disagree
    (x"00000005", x"FFFFFFFB", (x"00000000", x"0000000A", x"00000001", x"FFFFFFFF", x"FFFFFFFE",
                             x"00000000", x"00000001", x"28000000", x"00000000", x"00000000")),
    -- 10: all ones
    (x"FFFFFFFF", x"FFFFFFFF", (x"FFFFFFFE", x"00000000", x"FFFFFFFF", x"FFFFFFFF", x"00000000",
                             x"00000000", x"00000000", x"80000000", x"00000001", x"FFFFFFFF")),
    -- 11: alternating bits
    (x"AAAAAAAA", x"55555555", (x"FFFFFFFF", x"55555555", x"00000000", x"FFFFFFFF", x"FFFFFFFF",
                             x"00000001", x"00000000", x"55400000", x"00000555", x"FFFFFD55")),
    -- 12: shift by 0
    (x"DEADBEEF", x"00000000", (x"DEADBEEF", x"DEADBEEF", x"00000000", x"DEADBEEF", x"DEADBEEF",
                             x"00000001", x"00000000", x"DEADBEEF", x"DEADBEEF", x"DEADBEEF")),
    -- 13: shift by 31, sign bit set
    (x"80000000", x"0000001F", (x"8000001F", x"7FFFFFE1", x"00000000", x"8000001F", x"8000001F",
                             x"00000001", x"00000000", x"00000000", x"00000001", x"FFFFFFFF")),
    -- 14: shift by 31, low bit set
    (x"00000001", x"0000001F", (x"00000020", x"FFFFFFE2", x"00000001", x"0000001F", x"0000001E",
                             x"00000001", x"00000001", x"80000000", x"00000000", x"00000000")),
    -- 15: B=32: only B[4:0] used, shift by 0
    (x"DEADBEEF", x"00000020", (x"DEADBF0F", x"DEADBECF", x"00000020", x"DEADBEEF", x"DEADBECF",
                             x"00000001", x"00000000", x"DEADBEEF", x"DEADBEEF", x"DEADBEEF")),
    -- 16: srai-style B (0x400+5): shift by 5
    (x"80000000", x"00000405", (x"80000405", x"7FFFFBFB", x"00000000", x"80000405", x"80000405",
                             x"00000001", x"00000000", x"00000000", x"04000000", x"FC000000")),
    -- 17: shift by 4
    (x"12345678", x"00000004", (x"1234567C", x"12345674", x"00000000", x"1234567C", x"1234567C",
                             x"00000000", x"00000000", x"23456780", x"01234567", x"01234567"))
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
    variable v_Count   : integer := 0;
    variable v_Exp     : std_logic_vector(31 downto 0);
    variable v_ExpZero : std_logic;
  begin
    for i in c_VECTORS'range loop
      for op in 0 to 9 loop
        v_Exp := c_VECTORS(i).expect(op);
        if v_Exp = x"00000000" then
          v_ExpZero := '1';
        else
          v_ExpZero := '0';
        end if;

        s_A          <= c_VECTORS(i).a;
        s_B          <= c_VECTORS(i).b;
        s_ALUControl <= std_logic_vector(to_unsigned(op, 4));
        s_Op         <= c_OP_NAMES(op);
        wait for 10 ns;
        v_Count := v_Count + 1;

        if s_Result /= v_Exp or s_Zero /= v_ExpZero then
          report "MISMATCH vector " & integer'image(i) & " " & c_OP_NAMES(op) &
                 " A=" & to_hex(c_VECTORS(i).a) & " B=" & to_hex(c_VECTORS(i).b) &
                 " got " & to_hex(s_Result) & " zero=" & std_logic'image(s_Zero) &
                 " expected " & to_hex(v_Exp) & " zero=" & std_logic'image(v_ExpZero)
                 severity error;
          v_Errors := v_Errors + 1;
        end if;
      end loop;
    end loop;

    if v_Errors = 0 then
      report "tb_alu: all " & integer'image(v_Count) & " cases PASSED" severity note;
    else
      report "tb_alu: " & integer'image(v_Errors) & " FAILURES" severity failure;
    end if;
    wait;
  end process;

end behavior;
