-- storeUnit.vhd
-- byte enables + lane shifting for sb, sh, sw

library IEEE;
use IEEE.std_logic_1164.all;

entity storeUnit is
  port(i_Data   : in  std_logic_vector(31 downto 0);  -- rs2
       i_Addr   : in  std_logic_vector(1 downto 0);
       i_Funct3 : in  std_logic_vector(1 downto 0);
       o_Data   : out std_logic_vector(31 downto 0);
       o_BE     : out std_logic_vector(3 downto 0));
end storeUnit;

architecture dataflow of storeUnit is
  signal s_ByteBE, s_HalfBE : std_logic_vector(3 downto 0);
  signal s_ByteD, s_HalfD   : std_logic_vector(31 downto 0);
begin

  -- sb: one byte lane
  with i_Addr select
    s_ByteBE <= "0001" when "00",
                "0010" when "01",
                "0100" when "10",
                "1000" when others;

  with i_Addr select
    s_ByteD <= x"000000" & i_Data(7 downto 0)            when "00",
               x"0000" & i_Data(7 downto 0) & x"00"      when "01",
               x"00" & i_Data(7 downto 0) & x"0000"      when "10",
               i_Data(7 downto 0) & x"000000"            when others;

  -- sh: low or high half
  s_HalfBE <= "1100" when i_Addr(1) = '1' else "0011";
  s_HalfD  <= i_Data(15 downto 0) & x"0000" when i_Addr(1) = '1' else x"0000" & i_Data(15 downto 0);

  -- funct3: 00 sb, 01 sh, 10 sw
  with i_Funct3 select
    o_BE <= s_ByteBE when "00",
            s_HalfBE when "01",
            "1111"   when others;

  with i_Funct3 select
    o_Data <= s_ByteD when "00",
              s_HalfD when "01",
              i_Data  when others;

end dataflow;
