library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity protoWireDemux is
   port (
     protoStream_i :  in std_logic_vector(7 downto 0);
     message_id_o  :  out message_id_arr(0 to MAX_EMBEDD_MSGS-1);
     field_id_o    :  out std_logic_vector(4 downto 0);
     data_o        :  out std_logic_vector(7 downto 0);
     fieldLast_o   :  out std_logic;
     messageLast_o :  out std_logic;
     fieldValid_o  :  out std_logic;
     clk_i         :  in std_logic;
     reset_i       :  in std_logic
);
end protoWireDemux;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of protoWireDemux is 
--! @brief Signal Declarations
-- {{{
--signal wireType            :  std_logic_vector(2 downto 0);
signal wireType              :  wiretype_t;
signal fieldNumber           :  std_logic_vector(4 downto 0);
signal varintCount           :  natural range 0 to 8;
signal delimitCountStack     :  delimitLength_t;
signal delimitCount          : natural range 0 to 255;

signal numActiveMsgs          :  natural := 0;

type state_t is (IDLE, KEY_DECODE, VARINT_DECODE, LENGTH_DELIMITED_DECODE, DECODE_UNTIL_DELIMIT); 
signal  state : state_t := IDLE;
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{
   wireType <= wiretype_t'VAL(to_integer(unsigned(protostream_i(2 downto 0))));
   fieldNumber <= protostream_i(7 downto 3);
       
   process(clk_i)
   variable fieldNumber_var : unsigned(4 downto 0);
   begin

      if rising_edge(clk_i) then
      --defaults
      recv_msg <= '0';
      
         if reset_i = '1' then
            state <= IDLE;
            delimitCount <= 0;
            current_msg <= tree_GetBaseNode();
         else

         case state is
            when IDLE =>
               state <= KEY_DECODE;

            when KEY_DECODE => 
               field_id_o <= fieldNumber;

               case wireType is
                  when VARINT => 
                     varintCount <= 0;
                     state <= VARINT_DECODE;
                  when LENGTH_DELIMITED =>
                     -- could be an embedded message or a
                     -- packed repeated field.
                     state <= LENGTH_DELIMITED_DECODE;
                     --fetch from the tree 
                     embedded_msg := tree_SearchForNode(numActiveMsgs+1, current_msg, fieldNumber );
                     if embedded_msg != NULL_NODE then
                        recv_msg <= '1';
                        current_msg <= embedded_msg;
                     end if;
                  when OTHERS =>
                     -- not yet implemented
               end case;

            when LENGTH_DELIMITED_DECODE =>
               -- here we need to decide if this is a length-delimited
               -- type such as a string or repeated value.  OR if 
               -- this is a message.
               if (recv_msg = '1')
                     -- update msg name outputs

                     state <= KEY_DECODE;
               else
                     delimitCount <= to_integer(unsigned(protoStream_i));
                     state <= DECODE_UNTIL_DELIMIT;
                  -- These stats are packed-repeated since a non-LENGTH_DELIMITED type
                  -- came in.
                  when VARINT =>
                     packed_repeated <= '1';
                     delimitCount    <= to_integer(unsigned(protoStream_i));
                     state           <= VARINT_DECODE;
                  when OTHERS =>
                     -- more cases to come...
                     delimitCount    <= to_integer(unsigned(protoStream_i));
                     state           <= DECODE_UNTIL_DELIMIT;
               end case;

            when VARINT_DECODE =>
               if (protostream_i(7) = '0') then
                  -- end of decode
                     state        <= KEY_DECODE;
               end if;

            when DECODE_UNTIL_DELIMIT =>
                  delimitCount <= delimitCount - 1;
               if delimitCount = 1 then
                  state <= KEY_DECODE; 
               end if;
            end case;
             end if;
         end if;
         end process;

         -- This is an asynchrnous process to control the output
         -- data stream
         process(protostream_i, state, FieldUniqueId, varint_reg, varintCount)
         begin
           --default case
           data_o(7 downto 0) <= (others => '0');
           fieldValid_o <= '0';
           fieldLast_o <= '0';

           case state is

            when VARINT_DECODE =>
               data_o(7 downto 0) <= protostream_i;
               fieldValid_o <= '1';
               if (protostream_i(7) = '0') then
                  -- end of decode
                  fieldLast_o <= '1';
               end if;

            when DECODE_UNTIL_DELIMIT =>
               data_o(7 downto 0) <= protostream_i;
               fieldValid_o <= '1';
               if delimitCount = 1 then
                  fieldLast_o <= '1';
               end if;

            when OTHERS => 
            --do default case

            end case;

         end process;

         -- This process keeps track of embedded msgs and determines when
         -- to toggle messageLast_o
         process(clk_i)
            variable messageEndCount : natural range 0 to NUM_MSG_HIERARCHY-1;
            variable messageStartCount : natural range 0 to 1;
         begin
            if rising_edge(clk_i) then

              messageLast_o <= '0';
              messageStartCount := 0;
              messageEndCount := 0;



               if reset_i = '1' then
                 numActiveMsgs <= 0;
               else            

                  if (state = LENGTH_DELIMITED_DECODE) then
                     if (recv_msg = '1') then
                       messageStartCount := 1;
                       delimitCountStack(numActiveMsgs) <= to_integer(unsigned(protoStream_i))-1;
                     end if;
                  end if;

                  for i in NUM_MSG_HIERARCHY-1 downto 0 loop
                     if (numActiveMsgs > i) then
                        delimitCountStack(i) <=
                           delimitCountStack(i)-1;
                        -- the end of a message. If there are multiple
                        -- messages ending at the same time, the outer
                        -- most message takes priority with reference to 
                        -- messageUniqueId_o
                        if (delimitCountStack(i) = 1) then
                           messageLast_o    <= '1';
                           messageEndCount := messageEndCount + 1;
                        end if;
                     end if;
                  end loop;

                  numActiveMsgs <= numActiveMsgs + messageStartCount - messageEndCount;

                  message_id_o(numActiveMsgs) <= current_msg.data.msg_name;

                  for i in 0 to NUM_MSG_HIERARCHY-1 loop
                     if (i > numActiveMsgs) then
                        message_id_o(i) <= NULL_MSG;
                     end if;
                  end loop;

                end if;

             end if;
      end process;
         -- }}}
      end arch;
      --}}}

