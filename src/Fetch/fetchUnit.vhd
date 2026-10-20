-------------------------------------------------------------------------
-- fetchUnit.vhd
-- Instruction fetch logic for the CprE 3810 single-cycle RISC-V processor.
--
-- Next-PC selection (PCSrc):
--   00 : PC + 4                   (sequential, branch not taken)
--   01 : PC + imm                 (taken branch, jal)
--   10 : {ALUResult[31:1], '0'}   (jalr: rs1 + imm, LSB cleared)
--
--   PCSrc(0) = (Branch AND BrCond) OR Jump
--   PCSrc(1) = JALR                (jalr sets Jump = 0, so PCSrc is never 11)
--
-- Branch condition, using the ALU Zero flag:
--   beq/bne   : ALU does SUB,  Zero = 1 when rs1 = rs2
--   blt/bge   : ALU does SLT,  Zero = 1 when rs1 >= rs2 (signed)
--   bltu/bgeu : ALU does SLTU, Zero = 1 when rs1 >= rs2 (unsigned)
--   BrCond = Zero XOR funct3(0) XOR funct3(2)
--
-- o_PC drives s_PC in the skeleton (instruction memory address).
-- o_PCPlus4 is the link value written to rd by jal/jalr.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity fetchUnit is
  generic(N : integer := 32);
  port(i_CLK       : in  std_logic;
       i_RST       : in  std_logic;
       i_PCWE      : in  std_logic;                       -- tie to '1' (can stall on halt)
       i_Branch    : in  std_logic;
       i_Jump      : in  std_logic;
       i_JALR      : in  std_logic;
       i_Zero      : in  std_logic;                       -- ALU Zero flag
       i_Funct3    : in  std_logic_vector(2 downto 0);    -- instruction[14:12]
       i_Imm       : in  std_logic_vector(N-1 downto 0);  -- B- or J-type immediate from Imm Gen
       i_ALUResult : in  std_logic_vector(N-1 downto 0);  -- rs1 + imm for jalr
       o_PC        : out std_logic_vector(N-1 downto 0);
       o_PCPlus4   : out std_logic_vector(N-1 downto 0);
       o_PCSrc     : out std_logic_vector(1 downto 0));   -- exposed for testing/waveforms
end fetchUnit;

architecture structural of fetchUnit is

  component pcReg is
    generic(N : integer := 32;
            RESET_VAL : std_logic_vector(31 downto 0) := x"00400000");
    port(i_CLK, i_RST, i_WE : in std_logic;
         i_D : in  std_logic_vector(N-1 downto 0);
         o_Q : out std_logic_vector(N-1 downto 0));
  end component;

  component adder_N is
    generic(N : integer := 32);
    port(i_A, i_B : in  std_logic_vector(N-1 downto 0);
         i_Cin    : in  std_logic;
         o_S      : out std_logic_vector(N-1 downto 0);
         o_Cout   : out std_logic);
  end component;

  component mux2t1_N is
    generic(N : integer := 32);
    port(i_S      : in  std_logic;
         i_D0     : in  std_logic_vector(N-1 downto 0);
         i_D1     : in  std_logic_vector(N-1 downto 0);
         o_O      : out std_logic_vector(N-1 downto 0));
  end component;

  component andg2 is
    port(i_A, i_B : in std_logic; o_F : out std_logic);
  end component;

  component org2 is
    port(i_A, i_B : in std_logic; o_F : out std_logic);
  end component;

  component xorg2 is
    port(i_A, i_B : in std_logic; o_F : out std_logic);
  end component;

  constant c_FOUR : std_logic_vector(N-1 downto 0) := x"00000004";

  signal s_PC, s_NextPC   : std_logic_vector(N-1 downto 0);
  signal s_PCPlus4        : std_logic_vector(N-1 downto 0);
  signal s_PCPlusImm      : std_logic_vector(N-1 downto 0);
  signal s_JalrTarget     : std_logic_vector(N-1 downto 0);
  signal s_Mux0Out        : std_logic_vector(N-1 downto 0);
  signal s_Cout4, s_CoutI : std_logic;
  signal s_ZxF0, s_BrCond : std_logic;
  signal s_BrTaken        : std_logic;
  signal s_PCSrc          : std_logic_vector(1 downto 0);

begin

  -- Program counter
  PC_REG : pcReg
    generic map(N => N, RESET_VAL => x"00400000")
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_PCWE,
             i_D => s_NextPC, o_Q => s_PC);

  -- PC + 4
  ADD_PC4 : adder_N
    generic map(N => N)
    port map(i_A => s_PC, i_B => c_FOUR, i_Cin => '0',
             o_S => s_PCPlus4, o_Cout => s_Cout4);

  -- PC + imm (branch / jal target)
  ADD_PCIMM : adder_N
    generic map(N => N)
    port map(i_A => s_PC, i_B => i_Imm, i_Cin => '0',
             o_S => s_PCPlusImm, o_Cout => s_CoutI);

  -- jalr target: clear bit 0 of rs1 + imm
  s_JalrTarget <= i_ALUResult(N-1 downto 1) & '0';

  -- Branch condition: Zero xor funct3(0) xor funct3(2)
  XOR_A : xorg2 port map(i_A => i_Zero, i_B => i_Funct3(0), o_F => s_ZxF0);
  XOR_B : xorg2 port map(i_A => s_ZxF0, i_B => i_Funct3(2), o_F => s_BrCond);

  -- PCSrc(0) = (Branch and BrCond) or Jump ; PCSrc(1) = JALR
  AND_BR : andg2 port map(i_A => i_Branch, i_B => s_BrCond, o_F => s_BrTaken);
  OR_J   : org2  port map(i_A => s_BrTaken, i_B => i_Jump, o_F => s_PCSrc(0));
  s_PCSrc(1) <= i_JALR;

  -- 3:1 next-PC mux built from two 2:1 muxes
  MUX_SEQ : mux2t1_N
    generic map(N => N)
    port map(i_S => s_PCSrc(0), i_D0 => s_PCPlus4, i_D1 => s_PCPlusImm,
             o_O => s_Mux0Out);

  MUX_JALR : mux2t1_N
    generic map(N => N)
    port map(i_S => s_PCSrc(1), i_D0 => s_Mux0Out, i_D1 => s_JalrTarget,
             o_O => s_NextPC);

  o_PC      <= s_PC;
  o_PCPlus4 <= s_PCPlus4;
  o_PCSrc   <= s_PCSrc;

end structural;
