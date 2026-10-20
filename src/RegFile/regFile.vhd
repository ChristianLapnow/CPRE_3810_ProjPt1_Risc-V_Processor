-------------------------------------------------------------------------
-- regFile.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of the RISC-V
-- (RV32) register file using structural VHDL. It contains 32 32-bit
-- registers with two read ports (rs1, rs2) and one write port (rd),
-- built entirely from the reg_N, decoder5t32, and mux32t1_N components
-- created earlier in this lab.
--
-- STRUCTURE:
--   - The 5-bit write address i_RD drives the 5:32 decoder, whose
--     enable is the RegWrite control signal i_WE. The decoder output is
--     one-hot, so exactly one register sees a high write enable, and
--     only when RegWrite is asserted.
--   - All 32 registers are written from the same i_WD data bus. Which
--     one actually latches is decided solely by the decoder.
--   - All 32 register outputs are concatenated into one flat bus,
--     s_RegOut, which feeds both read muxes. Reads are therefore
--     combinational and happen continuously, while writes are clocked.
--     That asymmetry is what distinguishes a read from a write, so no
--     separate read-enable port is needed.
--
-- REGISTER ZERO: the ISA requires x0 to read as zero at all times.
-- Its reset port is tied high permanently, so its flip-flops are held
-- cleared and any write targeting it has no effect.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity regFile is
  generic(N : integer := 32);
  port(i_CLK        : in  std_logic;                      -- Clock
       i_RST        : in  std_logic;                      -- Async reset, active high
       i_WE         : in  std_logic;                      -- RegWrite control
       i_RS1        : in  std_logic_vector(4 downto 0);   -- Read address 1
       i_RS2        : in  std_logic_vector(4 downto 0);   -- Read address 2
       i_RD         : in  std_logic_vector(4 downto 0);   -- Write address
       i_WD         : in  std_logic_vector(N-1 downto 0); -- Write data
       o_RS1        : out std_logic_vector(N-1 downto 0); -- Read data 1
       o_RS2        : out std_logic_vector(N-1 downto 0));-- Read data 2
end regFile;

architecture structural of regFile is

  component reg_N is
    generic(N : integer := 32);
    port(i_CLK      : in  std_logic;
         i_RST      : in  std_logic;
         i_WE       : in  std_logic;
         i_D        : in  std_logic_vector(N-1 downto 0);
         o_Q        : out std_logic_vector(N-1 downto 0));
  end component;

  component decoder5t32 is
    port(i_A        : in  std_logic_vector(4 downto 0);
         i_EN       : in  std_logic;
         o_Q        : out std_logic_vector(31 downto 0));
  end component;

  component mux32t1_N is
    generic(N : integer := 32);
    port(i_S        : in  std_logic_vector(4 downto 0);
         i_D        : in  std_logic_vector(32*N-1 downto 0);
         o_O        : out std_logic_vector(N-1 downto 0));
  end component;

  -- One-hot write enable, one bit per register.
  signal s_WriteEn : std_logic_vector(31 downto 0);

  -- All 32 register outputs packed into one bus. Register I occupies
  -- bits ((I+1)*N-1 downto I*N), matching what mux32t1_N expects.
  signal s_RegOut  : std_logic_vector(32*N-1 downto 0);

begin

  ---------------------------------------------------------------------
  -- Write address decode
  ---------------------------------------------------------------------
  -- Asserts exactly one write enable, and only when RegWrite is high.
  g_Decoder : decoder5t32
    port map(i_A  => i_RD,
             i_EN => i_WE,
             o_Q  => s_WriteEn);

  ---------------------------------------------------------------------
  -- The 32 registers
  ---------------------------------------------------------------------
  G_REGISTERS : for i in 0 to 31 generate

    -- Register 0 is hardwired to zero: reset is held asserted forever,
    -- so it never stores anything regardless of the write enable.
    G_REG_ZERO : if i = 0 generate
      REGZERO : reg_N
        generic map(N => N)
        port map(i_CLK => i_CLK,
                 i_RST => '1',              -- permanently cleared
                 i_WE  => s_WriteEn(i),
                 i_D   => i_WD,
                 o_Q   => s_RegOut((i+1)*N-1 downto i*N));
    end generate G_REG_ZERO;

    -- Registers 1 through 31 are ordinary writable registers.
    G_REG_REST : if i /= 0 generate
      REGI : reg_N
        generic map(N => N)
        port map(i_CLK => i_CLK,
                 i_RST => i_RST,
                 i_WE  => s_WriteEn(i),     -- high only when addressed
                 i_D   => i_WD,             -- shared write data bus
                 o_Q   => s_RegOut((i+1)*N-1 downto i*N));
    end generate G_REG_REST;

  end generate G_REGISTERS;

  ---------------------------------------------------------------------
  -- Read ports
  ---------------------------------------------------------------------
  -- Both muxes see every register output; the address picks one.
  g_MuxRS1 : mux32t1_N
    generic map(N => N)
    port map(i_S => i_RS1,
             i_D => s_RegOut,
             o_O => o_RS1);

  g_MuxRS2 : mux32t1_N
    generic map(N => N)
    port map(i_S => i_RS2,
             i_D => s_RegOut,
             o_O => o_RS2);

end structural;