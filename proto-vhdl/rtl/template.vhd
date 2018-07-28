library ieee;
use ieee.std_logic_1164.all;

--! Entity Declaration
-- {{{
entity message_demux is
   port (
           Person_data  : out Person;
           Person_valid : out std_logic;
           
           Person_name_o       : out name_t;
           Person_name_valid_o : out std_logic;
           Person_name_last_o  : out std_logic;

           Person_email_o       : out email_t;
           Person_email_valid_o : out std_logic;
           Person_email_last_o  : out std_logic;

           Person_phoneNumber_data_o  : out Person_phoneNumber;
           Person_phoneNumber_valid_o : out std_logic;

           Person_phoneNumber_number_o       : out number_t;
           Person_phoneNumber_number_valid_o : out std_logic;
           Person_phoneNumber_number_last_o  : out std_logic;

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
   signal unique_id    : std_logic_vector(31 downto 0);
   signal data         : std_logic_vector(31 downto 0);
   signal messageValid : std_logic;
   signal fieldValid   : std_logic;
   signal delimit_last : std_logic;
-- }}}

begin
       --! @brief Component Port Maps
       -- {{{
   protoDeserialize: entity work.protoDeserialize
      port map (
        protoStream_i  => protoStream, -- std_logic_vector(7 downto 0);
        unique_id_o    => unique_id, -- std_logic_vector(31 downto 0);
        data_o         => data, -- std_logic_vector(31 downto 0);
        messageValid_o => messageValid, -- std_logic;
        fieldValid_o   => fieldValid, -- std_logic;
        delimit_last_o => delimit_last, -- std_logic;
        clk_i          => clk, -- std_logic;
        reset_i        => reset, -- std_logic
   );

       -- }}}
       --! @brief RTL
       -- {{{
       -- Message Listeners
       --  A message listener exists for each Message in the
       --  proto file, and also any fields of each message that
       --  is repeated. This is so the repeated fields can stream
       
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
         if (message_valid = '1') then
            -- and uniqe_id == Person
            Person_valid <= '1';
         end if;
         if field_valid = '1' then
            case key is 
               when 1 => Person_data.id <= data;
               when OTHERS => Person_valid <= '0';
            end case;
         end if;
      end if;
   end process;

   --Person Delimted types
   -- These types get their own valid and last signals
   process(data)
   begin
        -- defaults
         Person_name_valid_o  <= '0';
         Person_email_valid_o <= '0';
         Person_name_last_o   <= '0';
         Person_email_last_o  <= '0';

      if unique_id = name then
         Person_name_valid_o <= '1';
         Person_name_o       <= data(7 downto 0);
         if delimit_last = '1' then
            Person_name_last_o <= '1';
         end if;
      end if;
      if unique_id = email then
         Person_email_valid_o <= '1';
         Person_email_o       <= data(7 downto 0);
         if delimit_last = '1' then
            Person_email_last_o <= '1';
         end if;
      end if;
   end process;


   Person_phoneNumbers_listener : process(clk)
       -- embedded message which is repeated. since its embedded
       -- its guaranteed to have a length delimiter. So we only
       -- output tvalid when the message is complete.
   begin
      if (rising_edge(clk)) then
         Person_phoneNumber_valid <= '0';
         if (message_valid = '1') and unique_id = Person_phoneNumber then
            Person_phoneNumber_valid <= '1';
         end if;
         if field_valid = '1' then
            case key is 
               when 4 => Person_phoneNumber.phone_type <= data;
               when OTHERS => Person_phoneNumber_valid <= '0';
            end case;
         end if;
      end if;
   end process;

   --Person_phoneNumbers Delimted or repeated Types
   process(data)
   begin
      -- defaults
      Person_phoneNumber_number_valid_o = '0';
      Person_phoneNumber_number_o <= (others => '0');
      if unique_id = number then
         Person_phoneNumber_number_last_o  <= '0';
         Person_phoneNumber_number_valid_o <= '1';
         Person_phoneNumber_number_o       <= data(7 downto 0);
         if delimit_last = '1' then
            Person_phoneNumber_number_last_o <= '1';
         end if;
      end if;
   end process;
                     
   

-- embedded message which is not repeated. outputs tvalid only  
-- when the message is complete since the length delimiter is 
-- known.




-- }}}
end arch;
--}}}

