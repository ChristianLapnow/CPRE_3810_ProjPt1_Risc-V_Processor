-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- RISCV_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a skeleton of a RISCV_Processor
-- implementation.

-- 01/29/2019 by H3::Design created.
-- 04/10/2025 by AP::Coverted to RISC-V.
-- 02/19/2026 by H3::Renamed PC and handled OVFL
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0)); -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.

end  RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemBE       : std_logic_vector(3 downto 0); -- TODO: enable the addressed byte for SB, halfword for SH, or all bytes for SW
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output

  -- Required register file signals
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_PC instead
  signal s_PC : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the instruction signal

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Use WFI with Opcode: 111 0011 func3: 000 and func12: 000100000101 -- func12 is imm field from I-format)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- this signal indicates an overflow exception would have been initiated

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          be           : in std_logic_vector(3 downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;
  ---------------------------------------------------------------------
  -- Components added for Project Part 1
  ---------------------------------------------------------------------
  component fetchUnit is
    generic(N : integer := 32);
    port(i_CLK, i_RST, i_PCWE   : in  std_logic;
         i_Branch, i_Jump, i_JALR, i_Zero : in std_logic;
         i_Funct3    : in  std_logic_vector(2 downto 0);
         i_Imm       : in  std_logic_vector(N-1 downto 0);
         i_ALUResult : in  std_logic_vector(N-1 downto 0);
         o_PC        : out std_logic_vector(N-1 downto 0);
         o_PCPlus4   : out std_logic_vector(N-1 downto 0);
         o_PCSrc     : out std_logic_vector(1 downto 0));
  end component;

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

  component regFile is
    generic(N : integer := 32);
    port(i_CLK, i_RST, i_WE : in std_logic;
         i_RS1, i_RS2, i_RD : in std_logic_vector(4 downto 0);
         i_WD         : in  std_logic_vector(N-1 downto 0);
         o_RS1, o_RS2 : out std_logic_vector(N-1 downto 0));
  end component;

  component immGen is
    port(i_Inst    : in  std_logic_vector(31 downto 0);
         i_ImmType : in  std_logic_vector(2 downto 0);
         o_Imm     : out std_logic_vector(31 downto 0));
  end component;

  component alu is
    port(i_A, i_B     : in  std_logic_vector(31 downto 0);
         i_ALUControl : in  std_logic_vector(3 downto 0);
         o_Result     : out std_logic_vector(31 downto 0);
         o_Zero       : out std_logic);
  end component;

  component loadUnit is
    port(i_Word   : in  std_logic_vector(31 downto 0);
         i_Addr   : in  std_logic_vector(1 downto 0);
         i_Funct3 : in  std_logic_vector(2 downto 0);
         o_Data   : out std_logic_vector(31 downto 0));
  end component;

  component storeUnit is
    port(i_Data   : in  std_logic_vector(31 downto 0);
         i_Addr   : in  std_logic_vector(1 downto 0);
         i_Funct3 : in  std_logic_vector(1 downto 0);
         o_Data   : out std_logic_vector(31 downto 0);
         o_BE     : out std_logic_vector(3 downto 0));
  end component;

  component mux2t1_N is
    generic(N : integer := 32);
    port(i_S          : in  std_logic;
         i_D0, i_D1   : in  std_logic_vector(N-1 downto 0);
         o_O          : out std_logic_vector(N-1 downto 0));
  end component;

  -- control signals
  signal s_ALUSrcA, s_ALUSrc, s_MemWrite, s_RegWrite : std_logic;
  signal s_Branch, s_Jump, s_JALR, s_HaltCtl         : std_logic;
  signal s_ALUControl : std_logic_vector(3 downto 0);
  signal s_ImmType    : std_logic_vector(2 downto 0);
  signal s_ResultSrc  : std_logic_vector(1 downto 0);
  signal s_PCSrc      : std_logic_vector(1 downto 0);

  -- datapath signals
  signal s_PCPlus4  : std_logic_vector(N-1 downto 0);
  signal s_RS1Data  : std_logic_vector(N-1 downto 0);
  signal s_RS2Data  : std_logic_vector(N-1 downto 0);
  signal s_Imm      : std_logic_vector(N-1 downto 0);
  signal s_ALUA     : std_logic_vector(N-1 downto 0);
  signal s_ALUB     : std_logic_vector(N-1 downto 0);
  signal s_ALURes   : std_logic_vector(N-1 downto 0);
  signal s_Zero     : std_logic;
  signal s_LoadData : std_logic_vector(N-1 downto 0);
  signal s_ResLo    : std_logic_vector(N-1 downto 0);  -- ALU or load
  signal s_ResHi    : std_logic_vector(N-1 downto 0);  -- PC+4 or imm

begin
  s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.

  with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;

  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(ADDR_WIDTH+1 downto 2),
             data => iInstExt,
             be   => "1111",
             we   => iInstLd,
             q    => s_Inst);

  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(ADDR_WIDTH+1 downto 2),
             data => s_DMemData,
             be   => s_DMemBE,
             we   => s_DMemWr,
             q    => s_DMemOut);

  ---------------------------------------------------------------------
  -- Fetch: PC register, PC+4, branch/jal/jalr target select
  ---------------------------------------------------------------------
  FETCH: fetchUnit
    generic map(N => N)
    port map(i_CLK       => iCLK,
             i_RST       => iRST,
             i_PCWE      => '1',
             i_Branch    => s_Branch,
             i_Jump      => s_Jump,
             i_JALR      => s_JALR,
             i_Zero      => s_Zero,
             i_Funct3    => s_Inst(14 downto 12),
             i_Imm       => s_Imm,
             i_ALUResult => s_ALURes,
             o_PC        => s_PC,
             o_PCPlus4   => s_PCPlus4,
             o_PCSrc     => s_PCSrc);

  ---------------------------------------------------------------------
  -- Control
  ---------------------------------------------------------------------
  CONTROL: control_unit
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
             o_Halt       => s_HaltCtl);

  s_Halt <= s_HaltCtl;

  ---------------------------------------------------------------------
  -- Register file (Lab 2)
  ---------------------------------------------------------------------
  s_RegWr     <= s_RegWrite;
  s_RegWrAddr <= s_Inst(11 downto 7);

  REGS: regFile
    generic map(N => N)
    port map(i_CLK => iCLK,
             i_RST => iRST,
             i_WE  => s_RegWr,
             i_RS1 => s_Inst(19 downto 15),
             i_RS2 => s_Inst(24 downto 20),
             i_RD  => s_RegWrAddr,
             i_WD  => s_RegWrData,
             o_RS1 => s_RS1Data,
             o_RS2 => s_RS2Data);

  ---------------------------------------------------------------------
  -- Immediate generator
  ---------------------------------------------------------------------
  IMMGEN0: immGen
    port map(i_Inst    => s_Inst,
             i_ImmType => s_ImmType,
             o_Imm     => s_Imm);

  ---------------------------------------------------------------------
  -- ALU operand muxes and ALU
  ---------------------------------------------------------------------
  MUX_ALUA: mux2t1_N
    generic map(N => N)
    port map(i_S => s_ALUSrcA, i_D0 => s_RS1Data, i_D1 => s_PC, o_O => s_ALUA);

  MUX_ALUB: mux2t1_N
    generic map(N => N)
    port map(i_S => s_ALUSrc, i_D0 => s_RS2Data, i_D1 => s_Imm, o_O => s_ALUB);

  ALU0: alu
    port map(i_A          => s_ALUA,
             i_B          => s_ALUB,
             i_ALUControl => s_ALUControl,
             o_Result     => s_ALURes,
             o_Zero       => s_Zero);

  oALUOut <= s_ALURes;

  ---------------------------------------------------------------------
  -- Data memory connections
  ---------------------------------------------------------------------
  s_DMemAddr <= s_ALURes;
  s_DMemWr   <= s_MemWrite;

  -- store unit (sb/sh/sw)
  STORE0: storeUnit
    port map(i_Data   => s_RS2Data,
             i_Addr   => s_DMemAddr(1 downto 0),
             i_Funct3 => s_Inst(13 downto 12),
             o_Data   => s_DMemData,
             o_BE     => s_DMemBE);

  -- load unit (lb/lh/lbu/lhu)
  LOAD0: loadUnit
    port map(i_Word   => s_DMemOut,
             i_Addr   => s_DMemAddr(1 downto 0),
             i_Funct3 => s_Inst(14 downto 12),
             o_Data   => s_LoadData);

  ---------------------------------------------------------------------
  -- Write-back select (ResultSrc): 00 ALU, 01 load, 10 PC+4, 11 imm
  ---------------------------------------------------------------------
  MUX_RES_LO: mux2t1_N
    generic map(N => N)
    port map(i_S => s_ResultSrc(0), i_D0 => s_ALURes, i_D1 => s_LoadData, o_O => s_ResLo);

  MUX_RES_HI: mux2t1_N
    generic map(N => N)
    port map(i_S => s_ResultSrc(0), i_D0 => s_PCPlus4, i_D1 => s_Imm, o_O => s_ResHi);

  MUX_RES: mux2t1_N
    generic map(N => N)
    port map(i_S => s_ResultSrc(1), i_D0 => s_ResLo, i_D1 => s_ResHi, o_O => s_RegWrData);

end structure;
