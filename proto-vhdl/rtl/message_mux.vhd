library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity message_mux is
   port 
   (
      protoStream_o     : out std_logic_vector(7 downto 0);

      AddressBook_valid : in std_logic;
      AddressBook_last  : in std_logic;
      AddressBook_data  : in std_logic_vector(31 downto 0);
      AddressBook_user  : in std_logic_vector(3 downto 0);
      AddressBook_id    : in std_logic_vector(3 downto 0);

      reset : in std_logic;
      clk   : in std_logic
   );
end message_mux;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of message_mux is 
   --! @brief Signal Declarations
   -- {{{
   signal fieldUniqueId   :  std_logic_vector(31 downto 0);
   signal messageUniqueId :  std_logic_vector(31 downto 0);
   signal data            :  std_logic_vector(31 downto 0);
   signal messageLast     :  std_logic;
   signal fieldValid      :  std_logic;
   signal delimit_last    :  std_logic;
   signal fieldProtoId    :  std_logic_vector(3 downto 0);
   signal messageProtoId  :  std_logic_vector(3 downto 0);
   signal select_o        :  std_logic_vector(3 downto 0);
   signal valid_o         :  std_logic;
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   protoSerialize: entity work.protoSerialize
   port map 
   
      protoStream_o     => protoStream_o, -- std_logic_vector(7 downto 0);
      select_o          => select_o -- std_logic_vector(3 downto 0);
      valid_o           => valid_o -- std_logic;

      fieldUniqueId_i   => fieldUniqueId, -- std_logic_vector(31 downto 0);
      messageUniqueId_i => messageUniqueId, -- std_logic_vector(31 downto 0);
      data_i            => data, -- std_logic_vector(31 downto 0);
      messageLast_i     => messageLast, -- std_logic;
      fieldValid_i      => fieldValid, -- std_logic;
      clk_i             => clk, -- std_logic;
      reset_i           => reset -- std_logic
   );

   -- }}}
   --! @brief RTL
   -- {{{
   -- converts field and message ID's to unique Ids
   fieldUniqueId   <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(fieldUniqueId))), 4));
   messageUniqueId <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(messageUniqueId))), 4));

-- }}}
end arch;
--}}}

