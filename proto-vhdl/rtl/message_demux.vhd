library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity message_demux is
   port 
   (
      protoStream_i     : in std_logic_vector(7 downto 0);

      AddressBook_valid : out std_logic;
      AddressBook_last  : out std_logic;
      AddressBook_data  : out std_logic_vector(31 downto 0);
      AddressBook_user  : out std_logic_vector(3 downto 0);
      AddressBook_id    : out std_logic_vector(3 downto 0);

      reset : in std_logic;
      clk   : in std_logic
   );
end message_demux;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of message_demux is 
   --! @brief Signal Declarations
   -- {{{
   signal fieldUniqueId   : std_logic_vector(31 downto 0);
   signal messageUniqueId : std_logic_vector(31 downto 0);
   signal data            : std_logic_vector(31 downto 0);
   signal messageLast     : std_logic;
   signal fieldValid      : std_logic;
   signal delimit_last    : std_logic;
   signal fieldProtoId    : std_logic_vector(3 downto 0);
   signal messageProtoId  : std_logic_vector(3 downto 0);
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   protoDeserialize: entity work.protoDeserialize
   port map 
   (
      protoStream_i     => protoStream_i, -- std_logic_vector(7 downto 0);
      fieldUniqueId_o   => fieldUniqueId, -- std_logic_vector(31 downto 0);
      messageUniqueId_o => messageUniqueId, -- std_logic_vector(31 downto 0);
      data_o            => data, -- std_logic_vector(31 downto 0);
      messageLast_o     => messageLast, -- std_logic;
      fieldValid_o      => fieldValid, -- std_logic;
      delimit_last_o    => delimit_last, -- std_logic;
      clk_i             => clk, -- std_logic;
      reset_i           => reset -- std_logic
   );


   -- }}}
   --! @brief RTL
   -- {{{
   -- convertes field and message ID's back to protobuf Ids
   fieldProtoId   <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(fieldUniqueId))), 4));
   messageProtoId <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(messageUniqueId))), 4));

   -- Message Listeners
   -- The Id field keeps the current message ID as given
   -- in the proto-file, this also goes for embedded messages.
   -- The User field keeps the current field ID as given 
   -- in the proto file. last is asserted on the last data
   -- beat of the highest level mesage. Note that an embedded
   -- message and the highest level message can end on the same
   -- data beat, therefore the last id in TID will read out
   -- the highest level message id even though that last beat
   -- may pertain to an embedded message.

   AddressBook_listener : process(messageUniqueId, fieldValid, messageLast, fieldProtoId, messageProtoId, data) 
      variable myMessage : bit := '0';
   begin
      -- check if the unique message id belongs to
      -- this message type
      myMessage := '0';
      for i in 0 to ADDRESSBOOK_NUM_FIELDS - 1 loop
         if AddressbookId(i) = to_integer(unsigned(messageUniqueId)) then
            myMessage := '1';
         end if;
      end loop;
      AddressBook_user  <= fieldProtoId;
      AddressBook_id    <= messageProtoId;
      AddressBook_data  <= data;
      AddressBook_valid <= '0';
      AddressBook_last  <= '0';
      if (fieldValid = '1') and (myMessage = '1') then
         AddressBook_valid <= '1';
         if messageLast = '1' then
            AddressBook_last <= '1';
         end if;
      end if;
   end process;

-- }}}
end arch;
--}}}

