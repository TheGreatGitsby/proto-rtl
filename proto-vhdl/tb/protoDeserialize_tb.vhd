library ieee;
use ieee.std_logic_1164.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

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
   signal data_o         :  std_logic_vector;
   signal messageValid_o :  std_logic;
   signal fieldValid_o   :  std_logic;
-- }}}
begin

--! @brief DUT Port Map
-- {{{
protoDeserialize: entity work.protoDeserialize
   port map (
     protoStream_i     => protoStream_i,  -- std_logic_vector(7 downto 0);
     key_o             => key_o,          -- std_logic_vector(1 downto 0);
     data_o            => data_o,         -- std_logic_vector;
     messageValid_o    => messageValid_o, -- std_logic;
     fieldValid_o      => fieldValid_o   -- std_logic
);
   -- }}}

   --! @brief Clock Creation
   -- {{{
clk <= not clk after clk_period/2;
   -- }}}

   --! Stimulus process
   --{{{
stim_proc: process
   variable serializedBytes : std_logic_vector(7 downto 0);
   variable serializedline : line;
begin
   file_open(file_Serialized, "simpleMessage",  read_mode);
   wait for 100 ns;
   reset <='1';
   wait for 200 ns;
   reset <='0';
      -- Do something interesting.
   readline(file_Serialized, serializedline);
   while not endfile(file_Serialized) loop
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