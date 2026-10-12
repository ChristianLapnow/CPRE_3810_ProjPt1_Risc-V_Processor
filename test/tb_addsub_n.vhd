-------------------------------------------------------------------------
-- Jacob Dang
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- tb_addsub_n.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Checks the 32-bit ripple-carry adder/subtractor against
-- numeric_std arithmetic for every pair of a set of corner-case operands,
-- in both add and subtract mode. Checks the sum, carry out, and signed
-- overflow. Each case is held for 10 ns for the waveform.
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
    x"00000000", x"00000001", x"FFFFFFFF", x"7FFFFFFF",
    x"80000000", x"FFFFFFFB", x"12345678", x"AAAAAAAA");

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
    variable v_Count  : integer := 0;
    variable v_A, v_B : std_logic_vector(31 downto 0);
    variable v_BEff   : std_logic_vector(31 downto 0);  -- B as the adder sees it
    variable v_Wide   : unsigned(32 downto 0);
    variable v_ExpS   : std_logic_vector(31 downto 0);
    variable v_ExpC   : std_logic;
    variable v_ExpV   : std_logic;
  begin
    for sub in 0 to 1 loop
      for i in c_VALUES'range loop
        for j in c_VALUES'range loop
          v_A := c_VALUES(i);
          v_B := c_VALUES(j);

          -- Reference: A + B, or A + not(B) + 1 for subtract.
          if sub = 1 then
            v_BEff := not v_B;
            v_Wide := ('0' & unsigned(v_A)) + ('0' & unsigned(v_BEff)) + 1;
          else
            v_BEff := v_B;
            v_Wide := ('0' & unsigned(v_A)) + ('0' & unsigned(v_BEff));
          end if;
          v_ExpS := std_logic_vector(v_Wide(31 downto 0));
          v_ExpC := v_Wide(32);
          -- Signed overflow: operands (as added) share a sign, result does not.
          if v_A(31) = v_BEff(31) and v_ExpS(31) /= v_A(31) then
            v_ExpV := '1';
          else
            v_ExpV := '0';
          end if;

          s_A   <= v_A;
          s_B   <= v_B;
          if sub = 1 then
            s_Sub <= '1';
          else
            s_Sub <= '0';
          end if;
          wait for 10 ns;
          v_Count := v_Count + 1;

          if s_S /= v_ExpS or s_Cout /= v_ExpC or s_Ovfl /= v_ExpV then
            report "MISMATCH sub=" & integer'image(sub) &
                   " A=" & to_hex(v_A) & " B=" & to_hex(v_B) &
                   " got S=" & to_hex(s_S) & " C=" & std_logic'image(s_Cout) & " V=" & std_logic'image(s_Ovfl) &
                   " expected S=" & to_hex(v_ExpS) & " C=" & std_logic'image(v_ExpC) & " V=" & std_logic'image(v_ExpV)
                   severity error;
            v_Errors := v_Errors + 1;
          end if;
        end loop;
      end loop;
    end loop;

    if v_Errors = 0 then
      report "tb_addsub_n: all " & integer'image(v_Count) & " cases PASSED" severity note;
    else
      report "tb_addsub_n: " & integer'image(v_Errors) & " FAILURES" severity failure;
    end if;
    wait;
  end process;

end behavior;
