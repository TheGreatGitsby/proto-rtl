library ieee;
use ieee.std_logic_1164.all;
--use STD.textio.all;
--use ieee.std_logic_textio.all;
use work.tb_stimulus_pkg.all;
use work.proto_pkg.all;
use work.tree_pkg.all;

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
   signal field_id    : std_logic_vector(4 downto 0);
   signal message_id          :  message_id_arr;
   signal data            :  std_logic_vector(7 downto 0);
   signal fieldLast        : std_logic;
   signal messageLast    :  std_logic;
   signal fieldValid      :  std_logic;

   
 --  file file_Serialized : text;
-- }}}
begin

--! @brief DUT Port Map
-- {{{
wire_demux: entity work.protoWireDemux
   port map 
   (
      protoStream_i     => protoStream_i, -- std_logic_vector(7 downto 0);
     message_id_o  => message_id, --:  out message_id_arr(0 to NUM_MSG_HIERARCHY-1);
      field_id_o   => field_id, -- :  out std_logic_vector(4 downto 0);
      data_o       => data, -- :  out std_logic_vector(7 downto 0);
      fieldLast_o  => fieldLast, -- :  out std_logic;
      messageLast_o => messageLast, --:  out std_logic;
      fieldValid_o  => fieldValid, --:  out std_logic;
      reset_i => reset, -- std_logic;
      clk_i   => clk -- std_logic
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
