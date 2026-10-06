-------------------------------------------------------------------------
-- Christian Lapnow
-- CprE 3810 Project Part 1
-------------------------------------------------------------------------
-- tb_control_unit.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Feeds one real machine-code instruction per row of the
-- control spreadsheet into control_unit and checks every output against
-- the expected value. '-' entries are don't cares (checked with std_match).
-- Each test case is held for 10 ns so it is easy to read in the waveform;
-- s_Name shows which instruction is on the inputs.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_control_unit is
end tb_control_unit;

architecture behavior of tb_control_unit is

  component control_unit is
    port(i_Opcode     : in  std_logic_vector(6 downto 0);
         i_Funct3     : in  std_logic_vector(2 downto 0);
         i_Funct7b5   : in  std_logic;
         i_Imm12      : in  std_logic_vector(11 downto 0);
         o_ALUSrcA    : out std_logic;
         o_ALUSrc     : out std_logic;
         o_ALUControl : out std_logic_vector(3 downto 0);
         o_ImmType    : out std_logic_vector(2 downto 0);
         o_ResultSrc  : out std_logic_vector(1 downto 0);
         o_MemWrite   : out std_logic;
         o_RegWrite   : out std_logic;
         o_Branch     : out std_logic;
         o_Jump       : out std_logic;
         o_JALR       : out std_logic;
         o_Halt       : out std_logic);
  end component;

  type test_t is record
    inst       : std_logic_vector(31 downto 0);
    ALUSrcA    : std_logic;
    ALUSrc     : std_logic;
    ALUControl : std_logic_vector(3 downto 0);
    ImmType    : std_logic_vector(2 downto 0);
    ResultSrc  : std_logic_vector(1 downto 0);
    MemWrite   : std_logic;
    RegWrite   : std_logic;
    Branch     : std_logic;
    Jump       : std_logic;
    JALR       : std_logic;
    Halt       : std_logic;
  end record;
  type test_array_t is array (natural range <>) of test_t;
  type name_array_t is array (natural range <>) of string(1 to 12);

  --            inst         ASA  ASrc  ALUCtl  ImmT   Res   MW   RW   Br   J    JR   Halt
  constant c_TESTS : test_array_t := (
    (x"007302B3", '0', '0', "0000", "---", "00", '0', '1', '0', '0', '0', '0'),  -- add
    (x"407302B3", '0', '0', "0001", "---", "00", '0', '1', '0', '0', '0', '0'),  -- sub
    (x"007312B3", '0', '0', "0111", "---", "00", '0', '1', '0', '0', '0', '0'),  -- sll
    (x"007322B3", '0', '0', "0101", "---", "00", '0', '1', '0', '0', '0', '0'),  -- slt
    (x"007332B3", '0', '0', "0110", "---", "00", '0', '1', '0', '0', '0', '0'),  -- sltu
    (x"007342B3", '0', '0', "0100", "---", "00", '0', '1', '0', '0', '0', '0'),  -- xor
    (x"007352B3", '0', '0', "1000", "---", "00", '0', '1', '0', '0', '0', '0'),  -- srl
    (x"407352B3", '0', '0', "1001", "---", "00", '0', '1', '0', '0', '0', '0'),  -- sra
    (x"007362B3", '0', '0', "0011", "---", "00", '0', '1', '0', '0', '0', '0'),  -- or
    (x"007372B3", '0', '0', "0010", "---", "00", '0', '1', '0', '0', '0', '0'),  -- and
    (x"FFB30293", '0', '1', "0000", "000", "00", '0', '1', '0', '0', '0', '0'),  -- addi
    (x"FFE32293", '0', '1', "0101", "000", "00", '0', '1', '0', '0', '0', '0'),  -- slti
    (x"FFF33293", '0', '1', "0110", "000", "00", '0', '1', '0', '0', '0', '0'),  -- sltiu
    (x"7FF34293", '0', '1', "0100", "000", "00", '0', '1', '0', '0', '0', '0'),  -- xori
    (x"0F036293", '0', '1', "0011", "000", "00", '0', '1', '0', '0', '0', '0'),  -- ori
    (x"0FF37293", '0', '1', "0010", "000", "00", '0', '1', '0', '0', '0', '0'),  -- andi
    (x"40030293", '0', '1', "0000", "000", "00", '0', '1', '0', '0', '0', '0'),  -- addi (imm[10]=1)
    (x"00731293", '0', '1', "0111", "000", "00", '0', '1', '0', '0', '0', '0'),  -- slli
    (x"00735293", '0', '1', "1000", "000", "00", '0', '1', '0', '0', '0', '0'),  -- srli
    (x"40735293", '0', '1', "1001", "000", "00", '0', '1', '0', '0', '0', '0'),  -- srai
    (x"00830283", '0', '1', "0000", "000", "01", '0', '1', '0', '0', '0', '0'),  -- lb
    (x"00831283", '0', '1', "0000", "000", "01", '0', '1', '0', '0', '0', '0'),  -- lh
    (x"00832283", '0', '1', "0000", "000", "01", '0', '1', '0', '0', '0', '0'),  -- lw
    (x"00834283", '0', '1', "0000", "000", "01", '0', '1', '0', '0', '0', '0'),  -- lbu
    (x"00835283", '0', '1', "0000", "000", "01", '0', '1', '0', '0', '0', '0'),  -- lhu
    (x"FE730E23", '0', '1', "0000", "001", "--", '1', '0', '0', '0', '0', '0'),  -- sb
    (x"FE731E23", '0', '1', "0000", "001", "--", '1', '0', '0', '0', '0', '0'),  -- sh
    (x"FE732E23", '0', '1', "0000", "001", "--", '1', '0', '0', '0', '0', '0'),  -- sw
    (x"FE730CE3", '0', '0', "0001", "010", "--", '0', '0', '1', '0', '0', '0'),  -- beq
    (x"FE731CE3", '0', '0', "0001", "010", "--", '0', '0', '1', '0', '0', '0'),  -- bne
    (x"FE734CE3", '0', '0', "0101", "010", "--", '0', '0', '1', '0', '0', '0'),  -- blt
    (x"FE735CE3", '0', '0', "0101", "010", "--", '0', '0', '1', '0', '0', '0'),  -- bge
    (x"FE736CE3", '0', '0', "0110", "010", "--", '0', '0', '1', '0', '0', '0'),  -- bltu
    (x"FE737CE3", '0', '0', "0110", "010", "--", '0', '0', '1', '0', '0', '0'),  -- bgeu
    (x"010000EF", '-', '-', "0000", "100", "10", '0', '1', '0', '1', '0', '0'),  -- jal
    (x"004300E7", '0', '1', "0000", "000", "10", '0', '1', '0', '0', '1', '0'),  -- jalr
    (x"123452B7", '-', '-', "0000", "011", "11", '0', '1', '0', '0', '0', '0'),  -- lui
    (x"00001297", '1', '1', "0000", "011", "00", '0', '1', '0', '0', '0', '0'),  -- auipc
    (x"10500073", '-', '-', "0000", "---", "--", '0', '0', '0', '0', '0', '1')   -- wfi (halt)
  );

  constant c_NAMES : name_array_t := (
     0 => "add         ",
     1 => "sub         ",
     2 => "sll         ",
     3 => "slt         ",
     4 => "sltu        ",
     5 => "xor         ",
     6 => "srl         ",
     7 => "sra         ",
     8 => "or          ",
     9 => "and         ",
    10 => "addi        ",
    11 => "slti        ",
    12 => "sltiu       ",
    13 => "xori        ",
    14 => "ori         ",
    15 => "andi        ",
    16 => "addi (imm[10",
    17 => "slli        ",
    18 => "srli        ",
    19 => "srai        ",
    20 => "lb          ",
    21 => "lh          ",
    22 => "lw          ",
    23 => "lbu         ",
    24 => "lhu         ",
    25 => "sb          ",
    26 => "sh          ",
    27 => "sw          ",
    28 => "beq         ",
    29 => "bne         ",
    30 => "blt         ",
    31 => "bge         ",
    32 => "bltu        ",
    33 => "bgeu        ",
    34 => "jal         ",
    35 => "jalr        ",
    36 => "lui         ",
    37 => "auipc       ",
    38 => "wfi (halt)  "
  );

  signal s_Inst       : std_logic_vector(31 downto 0) := (others => '0');
  signal s_Name       : string(1 to 12) := (others => ' ');
  signal s_ALUSrcA    : std_logic;
  signal s_ALUSrc     : std_logic;
  signal s_ALUControl : std_logic_vector(3 downto 0);
  signal s_ImmType    : std_logic_vector(2 downto 0);
  signal s_ResultSrc  : std_logic_vector(1 downto 0);
  signal s_MemWrite   : std_logic;
  signal s_RegWrite   : std_logic;
  signal s_Branch     : std_logic;
  signal s_Jump       : std_logic;
  signal s_JALR       : std_logic;
  signal s_Halt       : std_logic;

begin

  DUT0 : control_unit
    port map(i_Opcode     => s_Inst(6 downto 0),
             i_Funct3     => s_Inst(14 downto 12),
             i_Funct7b5   => s_Inst(30),
             i_Imm12      => s_Inst(31 downto 20),
             o_ALUSrcA    => s_ALUSrcA,
             o_ALUSrc     => s_ALUSrc,
             o_ALUControl => s_ALUControl,
             o_ImmType    => s_ImmType,
             o_ResultSrc  => s_ResultSrc,
             o_MemWrite   => s_MemWrite,
             o_RegWrite   => s_RegWrite,
             o_Branch     => s_Branch,
             o_Jump       => s_Jump,
             o_JALR       => s_JALR,
             o_Halt       => s_Halt);

  P_TEST : process
    variable v_Errors : integer := 0;
    variable v_T      : test_t;
  begin
    for i in c_TESTS'range loop
      v_T    := c_TESTS(i);
      s_Inst <= v_T.inst;
      s_Name <= c_NAMES(i);
      wait for 10 ns;

      if not (std_match(s_ALUSrcA,    v_T.ALUSrcA)    and std_match(s_ALUSrc,   v_T.ALUSrc)   and
              std_match(s_ALUControl, v_T.ALUControl) and std_match(s_ImmType,  v_T.ImmType)  and
              std_match(s_ResultSrc,  v_T.ResultSrc)  and std_match(s_MemWrite, v_T.MemWrite) and
              std_match(s_RegWrite,   v_T.RegWrite)   and std_match(s_Branch,   v_T.Branch)   and
              std_match(s_Jump,       v_T.Jump)       and std_match(s_JALR,     v_T.JALR)     and
              std_match(s_Halt,       v_T.Halt)) then
        report "MISMATCH on " & c_NAMES(i) severity error;
        v_Errors := v_Errors + 1;
      end if;
    end loop;

    if v_Errors = 0 then
      report "tb_control_unit: all " & integer'image(c_TESTS'length) & " instructions PASSED" severity note;
    else
      report "tb_control_unit: " & integer'image(v_Errors) & " FAILURES" severity error;
    end if;
    wait;
  end process;

end behavior;
