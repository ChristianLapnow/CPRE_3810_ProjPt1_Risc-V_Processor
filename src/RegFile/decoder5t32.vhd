-------------------------------------------------------------------------
-- decoder5t32.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a 5:32 decoder
-- using dataflow VHDL and a with-select-when statement.
--
-- The RISC-V register file has 32 registers, so the write address rd is
-- 5 bits wide and exactly one of 32 write-enable lines must be asserted
-- per write. That is precisely a 5:32 decoder.
--
-- An enable input is included so the decoder can be driven directly by
-- the RegWrite control signal. When i_EN is low every output is held at
-- '0', meaning no register is written. Without this port the register
-- file would need 32 external AND gates to gate the decoder outputs
-- with RegWrite, so folding the enable in here keeps the top-level
-- schematic to just registers, decoder, and muxes.
--
-- The lab notes it is not worth generalizing this to N:2^N, so the 32
-- cases are written out explicitly.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity decoder5t32 is
  port(i_A          : in  std_logic_vector(4 downto 0);   -- 5-bit address
       i_EN         : in  std_logic;                      -- Enable (RegWrite)
       o_Q          : out std_logic_vector(31 downto 0)); -- One-hot output
end decoder5t32;

architecture dataflow of decoder5t32 is

  -- The raw one-hot decode, before the enable is applied.
  signal s_Dec : std_logic_vector(31 downto 0);

begin

  -- Set bit I of the output when the input equals I in decimal.
  with i_A select
    s_Dec <= x"00000001" when "00000",
             x"00000002" when "00001",
             x"00000004" when "00010",
             x"00000008" when "00011",
             x"00000010" when "00100",
             x"00000020" when "00101",
             x"00000040" when "00110",
             x"00000080" when "00111",
             x"00000100" when "01000",
             x"00000200" when "01001",
             x"00000400" when "01010",
             x"00000800" when "01011",
             x"00001000" when "01100",
             x"00002000" when "01101",
             x"00004000" when "01110",
             x"00008000" when "01111",
             x"00010000" when "10000",
             x"00020000" when "10001",
             x"00040000" when "10010",
             x"00080000" when "10011",
             x"00100000" when "10100",
             x"00200000" when "10101",
             x"00400000" when "10110",
             x"00800000" when "10111",
             x"01000000" when "11000",
             x"02000000" when "11001",
             x"04000000" when "11010",
             x"08000000" when "11011",
             x"10000000" when "11100",
             x"20000000" when "11101",
             x"40000000" when "11110",
             x"80000000" when "11111",
             x"00000000" when others;  -- covers 'X', 'U', etc.

  -- Hold every output low when the decoder is disabled.
  o_Q <= s_Dec when (i_EN = '1') else (others => '0');

end dataflow;