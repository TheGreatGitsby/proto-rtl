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
   constant clk_period      :  time := 100 ns;
   signal clk               :  std_logic := '0';
   signal reset             :  std_logic := '0';
   signal protoStream_i     :  std_logic_vector(7 downto 0);
   signal fieldUniqueId_o   :  std_logic_vector(31 downto 0);
   signal messageUniqueId_o :  std_logic_vector(31 downto 0);
   signal data_o            :  std_logic_vector(31 downto 0);
   signal messageLast_o    :  std_logic;
   signal fieldValid_o      :  std_logic;
   signal delimit_last_o    :  std_logic;
   
   file file_Serialized : text;
-- }}}
begin

--! @brief DUT Port Map
-- {{{
protoDeserialize_inst: entity work.protoDeserialize
   port map (
     protoStream_i     => protoStream_i,  -- std_logic_vector(7 downto 0);
     fieldUniqueId_o   => fieldUniqueId_o,          -- std_logic_vector(1 downto 0);
     messageUniqueId_o => messageUniqueId_o,
     data_o            => data_o,         -- std_logic_vector;
     messageLast_o     => messageLast_o, -- std_logic;
     delimit_last_o    => delimit_last_o,
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
begin
   wait for 100 ns;
   reset <='1';
   wait for 200 ns;
   reset <='0';
      -- Do something interesting.
   wait until rising_edge(clk);
   for i in 0 to NUM_INPUT_BYTES-1 loop
      protoStream_i <= input_vec(i);
      wait until rising_edge(clk);
   end loop;
   wait;
end process;
--}}}


end arch;
--}}}
