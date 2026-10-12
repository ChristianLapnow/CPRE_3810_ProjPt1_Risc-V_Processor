-------------------------------------------------------------------------
-- tb_fetchUnit.vhd
-- Self-checking testbench for fetchUnit. Each case sets the control
-- inputs, waits one rising edge, and checks the new PC.
-- Case number is shown on s_Case so each step is easy to find in the wave.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_fetchUnit is
  generic(gCLK_HPER : time := 10 ns);
end tb_fetchUnit;

architecture behavior of tb_fetchUnit is

  constant cCLK_PER : time := gCLK_HPER * 2;

  component fetchUnit is
    generic(N : integer := 32);
    port(i_CLK, i_RST, i_PCWE      : in std_logic;
         i_Branch, i_Jump, i_JALR  : in std_logic;
         i_Zero                    : in std_logic;
         i_Funct3                  : in std_logic_vector(2 downto 0);
         i_Imm, i_ALUResult        : in std_logic_vector(N-1 downto 0);
         o_PC, o_PCPlus4           : out std_logic_vector(N-1 downto 0);
         o_PCSrc                   : out std_logic_vector(1 downto 0));
  end component;

  signal s_CLK, s_RST       : std_logic := '0';
  signal s_PCWE             : std_logic := '1';
  signal s_Branch, s_Jump   : std_logic := '0';
  signal s_JALR, s_Zero     : std_logic := '0';
  signal s_Funct3           : std_logic_vector(2 downto 0) := "000";
  signal s_Imm, s_ALURes    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_PC, s_PCPlus4    : std_logic_vector(31 downto 0);
  signal s_PCSrc            : std_logic_vector(1 downto 0);
  signal s_Case             : integer := 0;
  signal s_Errors           : integer := 0;

  -- 32-bit vector to 8-char hex string (works in VHDL-2002 and 2008)
  function to_hex(v : std_logic_vector(31 downto 0)) return string is
    constant c_HEX : string(1 to 16) := "0123456789ABCDEF";
    variable r     : string(1 to 8);
    variable nib   : std_logic_vector(3 downto 0);
  begin
    for i in 0 to 7 loop
      nib := v(31 - i*4 downto 28 - i*4);
      if is_x(nib) then
        r(i+1) := 'X';
      else
        r(i+1) := c_HEX(to_integer(unsigned(nib)) + 1);
      end if;
    end loop;
    return r;
  end function;

begin

  DUT : fetchUnit
    port map(i_CLK => s_CLK, i_RST => s_RST, i_PCWE => s_PCWE,
             i_Branch => s_Branch, i_Jump => s_Jump, i_JALR => s_JALR,
             i_Zero => s_Zero, i_Funct3 => s_Funct3,
             i_Imm => s_Imm, i_ALUResult => s_ALURes,
             o_PC => s_PC, o_PCPlus4 => s_PCPlus4, o_PCSrc => s_PCSrc);

  P_CLK : process
  begin
    s_CLK <= '0'; wait for gCLK_HPER;
    s_CLK <= '1'; wait for gCLK_HPER;
  end process;

  P_TEST : process

    -- Set controls, clock once, check PC
    procedure step(caseNum  : integer;
                   br, j, jr, z : std_logic;
                   f3       : std_logic_vector(2 downto 0);
                   imm, alu : std_logic_vector(31 downto 0);
                   expPC    : std_logic_vector(31 downto 0)) is
    begin
      s_Case <= caseNum;
      s_Branch <= br; s_Jump <= j; s_JALR <= jr; s_Zero <= z;
      s_Funct3 <= f3; s_Imm <= imm; s_ALURes <= alu;
      wait until rising_edge(s_CLK);
      wait for 1 ns;
      if s_PC /= expPC then
        report "Case " & integer'image(caseNum) & " FAILED: PC = 0x" &
               to_hex(s_PC) & ", expected 0x" & to_hex(expPC)
               severity error;
        s_Errors <= s_Errors + 1;
      end if;
    end procedure;

  begin
    -- Case 0: reset -> PC = 0x00400000
    s_RST <= '1';
    wait for cCLK_PER;
    wait until falling_edge(s_CLK);
    assert s_PC = x"00400000" report "Reset FAILED" severity error;
    assert s_PCPlus4 = x"00400004" report "PC+4 FAILED" severity error;
    s_RST <= '0';
    wait until falling_edge(s_CLK);
    -- (one edge passed with all controls 0, so PC is now 0x00400004)

    --        case br  j   jr  z   f3     imm          alu          expected PC
    -- Sequential
    step(1,  '0','0','0','0',"000", x"00000000", x"00000000", x"00400008");
    step(2,  '0','0','0','0',"000", x"00000000", x"00000000", x"0040000C");
    -- beq taken (rs1 = rs2 -> Zero = 1), imm = +16
    step(3,  '1','0','0','1',"000", x"00000010", x"00000000", x"0040001C");
    -- beq not taken (Zero = 0)
    step(4,  '1','0','0','0',"000", x"00000010", x"00000001", x"00400020");
    -- bne taken (Zero = 0), imm = -8
    step(5,  '1','0','0','0',"001", x"FFFFFFF8", x"00000001", x"00400018");
    -- bne not taken (Zero = 1)
    step(6,  '1','0','0','1',"001", x"FFFFFFF8", x"00000000", x"0040001C");
    -- blt taken (SLT = 1 -> Zero = 0), imm = +32
    step(7,  '1','0','0','0',"100", x"00000020", x"00000001", x"0040003C");
    -- blt not taken (SLT = 0 -> Zero = 1)
    step(8,  '1','0','0','1',"100", x"00000020", x"00000000", x"00400040");
    -- bge taken (SLT = 0 -> Zero = 1), imm = -4
    step(9,  '1','0','0','1',"101", x"FFFFFFFC", x"00000000", x"0040003C");
    -- bge not taken (Zero = 0)
    step(10, '1','0','0','0',"101", x"FFFFFFFC", x"00000001", x"00400040");
    -- bltu taken (SLTU = 1 -> Zero = 0), imm = +8
    step(11, '1','0','0','0',"110", x"00000008", x"00000001", x"00400048");
    -- bltu not taken
    step(12, '1','0','0','1',"110", x"00000008", x"00000000", x"0040004C");
    -- bgeu taken (Zero = 1), imm = +12
    step(13, '1','0','0','1',"111", x"0000000C", x"00000000", x"00400058");
    -- bgeu not taken
    step(14, '1','0','0','0',"111", x"0000000C", x"00000001", x"0040005C");
    -- Branch = 0 ignores Zero (e.g. add with a zero result)
    step(15, '0','0','0','1',"000", x"00000040", x"00000000", x"00400060");
    -- jal forward, imm = +0x100 (Zero and funct3 ignored)
    step(16, '0','1','0','0',"010", x"00000100", x"00000000", x"00400160");
    -- jal backward, imm = -0x100
    step(17, '0','1','0','1',"111", x"FFFFFF00", x"00000000", x"00400060");
    -- jalr: rs1 + imm = 0x00400201 (odd) -> LSB cleared
    step(18, '0','0','1','0',"000", x"00000001", x"00400201", x"00400200");
    -- jalr return to an even address
    step(19, '0','0','1','0',"000", x"00000000", x"00400064", x"00400064");
    -- Back to sequential
    step(20, '0','0','0','0',"000", x"00000000", x"00000000", x"00400068");

    -- Case 21: PC write enable low holds the PC
    s_Case <= 21; s_PCWE <= '0';
    wait until rising_edge(s_CLK); wait for 1 ns;
    assert s_PC = x"00400068" report "Hold FAILED" severity error;
    s_PCWE <= '1';

    -- Case 22: reset in the middle of execution
    s_Case <= 22; s_RST <= '1';
    wait for 1 ns;
    assert s_PC = x"00400000" report "Mid-run reset FAILED" severity error;
    wait until falling_edge(s_CLK);
    s_RST <= '0';

    wait for cCLK_PER;
    if s_Errors = 0 then
      report "tb_fetchUnit: ALL TESTS PASSED" severity note;
    else
      report "tb_fetchUnit: " & integer'image(s_Errors) & " FAILURES" severity error;
    end if;
    wait;
  end process;

end behavior;