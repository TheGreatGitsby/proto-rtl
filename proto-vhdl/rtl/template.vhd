library ieee;
use ieee.std_logic_1164.all;

--! Entity Declaration
-- {{{
entity template is
   port (
           Person_data	 : out Person;
           Person_valid        : out std_logic;

           Person_phoneNumber_data : out Person_phoneNumber;
           Person_phoneNumber_valid : out std_logic;

           reset   : in std_logic;
           clk 	 : in std_logic
        );
end template;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of template is 
--! @brief Signal Declarations
-- {{{
-- }}}

begin
       --! @brief Component Port Maps
       -- {{{
       -- parse varint key value module
       -- protoStream : in std_logic_vector();
       -- key : out std_logic_vector();
       -- data : out std_logic_vector();
       -- field_valid : out std_logic;

       -- This module will generate a message_valid when an 
       -- embedded (and only embedded) message completes.

       -- message_valid : out std_logic;

       -- }}}
       --! @brief RTL
       -- {{{
       -- Message Listeners
       --  A message listener exists for each Message in the
       --  proto file, and also any fields of each message that
       --  is repeated. This is so the repeated fields can stream
       --  independently. repeated field streams do not contain a
       --  tlast and should look to the parent message for a 
       --  tlast or "end" indicator. This assumes the parent 
       --  message is embedded. (all messages should be per 
       --  our rtl protobuf recommendation, though not required.

   Person_listener : process(clk) 
       -- A Message which is not embedded. This is not
       -- recommended as there is no way to determine if 
       -- the message has finished. (ie no tlast and all message
       -- parameters result in tvalid.
   begin
      if (rising_edge(clk)) then
         Person_valid <= '0';
         if (field_valid = '1') then
            Person_valid <= '1';
            case key is 
               when 0 => Person_data.name <= data;
               when 1 => Person_data.id <= data;
               when 2 => Person_data.email <= data;
               when OTHERS => Person_valid <= '0';
            end case;
         end if;
      end if;
   end process;

   Person_listener_phoneNumbers : process(clk)
       -- embedded message which is repeated. since its embedded
       -- its guaranteed to have a length delimiter. So we only
       -- output tvalid when the message is complete.
   begin
      if (rising_edge(clk)) then
         Person_phoneNumber_valid <= '0';
         if (message_valid = '1') then
            Person_phoneNumber_valid <= '1';
         end if;
         if field_valid = '1' then
            case key is 
               when 3 => Person_phoneNumber.number <= data;
               when 4 => Person_phoneNumber.phone_type <= data;
               when OTHERS => Person_phoneNumber_valid <= '0';
            end case;
         end if;
      end if;
   end process;

-- embedded message which is not repeated. outputs tvalid only  
-- when the message is complete since the length delimiter is 
-- known.




-- }}}
end arch;
--}}}

