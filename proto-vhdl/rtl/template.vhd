library ieee;
use ieee.std_logic_1164.all;

--! Entity Declaration
-- {{{
entity message_demux is
   port (
     AddressBook_valid : out std_logic;
     AddressBook_last : out std_logic;
     AddressBook_data  : out std_logic_vector(31 downto 0);
     AddressBook_user  : out std_logic_vector(3 downto 0);
     AddressBook_id    : out std_logic_vector(3 downto 0);

           reset   : in std_logic;
           clk 	 : in std_logic
        );
end message_demux;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of message_demux is 
--! @brief Signal Declarations
-- {{{
   signal protoStream  : std_logic_vector(7 downto 0);
-- }}}

begin
       --! @brief Component Port Maps
       -- {{{
protoDeserialize: entity work.protoDeserialize
   port map (
     protoStream_i     => protoStream, -- std_logic_vector(7 downto 0);
     fieldUniqueId_o   => fieldUniqueId, -- std_logic_vector(31 downto 0);
     messageUniqueId_o => messageUniqueId, -- std_logic_vector(31 downto 0);
     data_o            => data, -- std_logic_vector(31 downto 0);
     messageLast_o    => messageLast, -- std_logic;
     fieldValid_o      => fieldValid, -- std_logic;
     delimit_last_o    => delimit_last, -- std_logic;
     clk_i             => clk, -- std_logic;
     reset_i           => reset, -- std_logic
);


       -- }}}
       --! @brief RTL
       -- {{{
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
   
   AddressBook_listener : process(all) 
   begin
         AddressBook_valid <= '0';
         AddressBook_last  <= '0';
         if (fieldValid = '1') then
            -- and uniqe_id == Person
           AddressBook_valid <= '1';
           AddressBook_user  <= fieldUniqueId;
           AddressBook_id    <= messageUniqueId;
           AddressBook_data  <= data;
         if messageLast = '1' and messageId = AddressBook then
            AddressBook_last <= '1';
         end if;
         end if;
   end process;

-- }}}
end arch;
--}}}

