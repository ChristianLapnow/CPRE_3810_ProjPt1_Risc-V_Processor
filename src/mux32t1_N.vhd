-------------------------------------------------------------------------
-- mux32t1_N.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of an N-bit wide
-- 32:1 multiplexer using dataflow VHDL and a with-select-when
-- statement. It provides one read port for the RISC-V register file,
-- selecting one register's output out of all 32 that are read in
-- parallel.
--
-- DESIGN JUSTIFICATION (lab part f): three approaches were considered.
--   1. A five-level tree of 31 2:1 muxes built from the mux2t1_N
--      component from Lab 1. Fully structural and closest to the real
--      gate layout, but 31 instantiations and a five-deep select
--      network is a lot of hand-wiring for no new insight.
--   2. A one-hot AND/OR network driven by the decoder. Elegant reuse,
--      but it needs a 32-bit select input rather than a 5-bit address
--      and is the largest amount of code of the three.
--   3. A single with-select-when statement, used here.
-- Option 3 was chosen because structural design was already
-- demonstrated in Lab 1 and in reg_N, so nothing further is proven by
-- hand-building a 31-instance tree, while the dataflow version is much
-- harder to mis-wire and simulates faster. Simulation speed matters
-- here because the register file instantiates two of these muxes and
-- the datapath testbench runs 23 instructions through them.
--
-- The 32 data inputs are passed as one flattened vector rather than 32
-- separate ports. Register I occupies bits ((I+1)*N-1 downto I*N), so
-- the whole register file output bus can be built by concatenation.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux32t1_N is
  generic(N : integer := 32);
  port(i_S          : in  std_logic_vector(4 downto 0);      -- Select
       i_D          : in  std_logic_vector(32*N-1 downto 0); -- 32 packed inputs
       o_O          : out std_logic_vector(N-1 downto 0));   -- Selected input
end mux32t1_N;

architecture dataflow of mux32t1_N is
begin

  -- Slice out the addressed register's N-bit field.
  with i_S select
    o_O <= i_D( 1*N-1 downto  0*N) when "00000",
           i_D( 2*N-1 downto  1*N) when "00001",
           i_D( 3*N-1 downto  2*N) when "00010",
           i_D( 4*N-1 downto  3*N) when "00011",
           i_D( 5*N-1 downto  4*N) when "00100",
           i_D( 6*N-1 downto  5*N) when "00101",
           i_D( 7*N-1 downto  6*N) when "00110",
           i_D( 8*N-1 downto  7*N) when "00111",
           i_D( 9*N-1 downto  8*N) when "01000",
           i_D(10*N-1 downto  9*N) when "01001",
           i_D(11*N-1 downto 10*N) when "01010",
           i_D(12*N-1 downto 11*N) when "01011",
           i_D(13*N-1 downto 12*N) when "01100",
           i_D(14*N-1 downto 13*N) when "01101",
           i_D(15*N-1 downto 14*N) when "01110",
           i_D(16*N-1 downto 15*N) when "01111",
           i_D(17*N-1 downto 16*N) when "10000",
           i_D(18*N-1 downto 17*N) when "10001",
           i_D(19*N-1 downto 18*N) when "10010",
           i_D(20*N-1 downto 19*N) when "10011",
           i_D(21*N-1 downto 20*N) when "10100",
           i_D(22*N-1 downto 21*N) when "10101",
           i_D(23*N-1 downto 22*N) when "10110",
           i_D(24*N-1 downto 23*N) when "10111",
           i_D(25*N-1 downto 24*N) when "11000",
           i_D(26*N-1 downto 25*N) when "11001",
           i_D(27*N-1 downto 26*N) when "11010",
           i_D(28*N-1 downto 27*N) when "11011",
           i_D(29*N-1 downto 28*N) when "11100",
           i_D(30*N-1 downto 29*N) when "11101",
           i_D(31*N-1 downto 30*N) when "11110",
           i_D(32*N-1 downto 31*N) when "11111",
           (others => '0')         when others;  -- covers 'X', 'U', etc.

end dataflow;