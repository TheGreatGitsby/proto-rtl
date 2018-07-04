library ieee;
use ieee.std_logic_1164.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use work.tb_stimulus_pkg.all;

--! Entity Declaration
-- {{{
entity tb_template is
   end tb_template;
-- }}}

--! @brief Architecture Description
-- {{{
architecture arch of tb_template is 
   --! @brief Signal Declarations                                                                            
   -- {{{  
   constant clk_period   :  time := 100 ns;
   signal clk            :  std_logic := '0';
   signal reset          :  std_logic := '0';
   signal protoStream_i  :  std_logic_vector(7 downto 0);
   signal key_o          :  std_logic_vector(1 downto 0);
   signal data_o         :  std_logic_vector(7 downto 0);
   signal messageValid_o :  std_logic;
   signal fieldValid_o   :  std_logic;
   
   file file_Serialized : text;
-- }}}
begin

--! @brief DUT Port Map
-- {{{
protoDeserialize_inst: entity work.protoDeserialize
   port map (
     protoStream_i     => protoStream_i,  -- std_logic_vector(7 downto 0);
     key_o             => key_o,          -- std_logic_vector(1 downto 0);
     data_o            => data_o,         -- std_logic_vector;
     messageValid_o    => messageValid_o, -- std_logic;
     fieldValid_o      => fieldValid_o,   -- std_logic
     clk_i             => clk,
     reset_i           => reset
);
   -- }}}

   --! @brief Clock Creation
   -- {{{
clk <= not clk after clk_period/2;
   -- }}}

   --! Stimulus process
   --{{{
stim_proc: process
 --  variable serializedBytes : character;
 --  variable serializedline : line;
begin
 --  file_open(file_Serialized, "C:\proto-rtl\protobuf\simple.txt",  read_mode);
   wait for 100 ns;
   reset <='1';
   wait for 200 ns;
   reset <='0';
      -- Do something interesting.
 --  while not endfile(file_Serialized) loop
 --  readline(file_Serialized, serializedline);
      -- read a byte
      read(serializedline, serializedBytes);
      protoStream_i <= serializedBytes;
      --wait for clock cycle
      wait until rising_edge(clk);
   end loop;
   wait;
end process;
--}}}


end arch;
--}}}
