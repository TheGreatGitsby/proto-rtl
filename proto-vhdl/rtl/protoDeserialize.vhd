library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity protoDeserialize is
   port (
     protoStream_i  :  in std_logic_vector(7 downto 0);
     fieldUniqueId_o    :  out std_logic_vector(31 downto 0);
     messageUniqueId_o  : out std_logic_vector(31 downto 0);
     data_o         :  out std_logic_vector(31 downto 0);
     messageValid_o :  out std_logic;
     fieldValid_o   :  out std_logic;
     delimit_last_o :  out std_logic;
     clk_i          :  in std_logic;
     reset_i        :  in std_logic
);
end protoDeserialize;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of protoDeserialize is 
--! @brief Signal Declarations
-- {{{
--signal wireType            :  std_logic_vector(2 downto 0);
signal wireType              :  wiretype_t;
signal fieldNumber           :  std_logic_vector(4 downto 0);
signal fieldNumber_reg       :  std_logic_vector(4 downto 0);
signal varintCount           :  natural range 0 to 8;
signal delimitCountStack     :  delimitLength_t;
signal delimitUniqueIdStack  :  delimitUniqueId_t;
signal delimitCount          : natural range 0 to 255;

signal varint_reg : varint_reg_t;

-- These signals are to build the UNIQUE_ID_LUT address
signal numActiveMsgs          :  natural := 0;
signal uniqueIdLutAddress     :  std_logic_vector(MAX_ARRAY_IDX_BITS - 1 downto 0) := (OTHERS => '0');
signal uniqueIdLutAddressMask :  std_logic_vector(MAX_ARRAY_IDX_BITS - 1 downto 0) := (OTHERS => '0');
signal FieldUniqueId          :  natural range 0 to NUM_FIELDS-1;
signal FieldUniqueIdType      :  varTypes;

signal probe : natural;

type state_t is (IDLE, KEY_DECODE, VARINT_DECODE, LENGTH_DELIMITED_DECODE, DECODE_UNTIL_DELIMIT); 
signal  state : state_t := IDLE;
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{
   probe <= VARINT_NUM_BYTES_MAX;
   
   --wireType <= protostream_i(2 downto 0);
   wireType <= wiretype_t'VAL(to_integer(unsigned(protostream_i(2 downto 0))));
   fieldNumber <= protostream_i(7 downto 3);




   -- Mask off the upper bits of the unique ID Lut if the bits
   -- are not used (ie not enough active embedded msgs to make
   -- this part of the address possible)
   process(numActiveMsgs)
   begin
      for i in 0 to MAX_ARRAY_IDX_BITS-1 loop
         if (i >= ((numActiveMsgs * FIELD_NUM_BITS) + FIELD_NUM_BITS)) then
            uniqueIdLutAddressMask(i) <= '0'; 
         else
            uniqueIdLutAddressMask(i) <= '1'; 
         end if;
      end loop;
   end process;

   -- Always holds the current Unique ID of the field being processed.
   FieldUniqueId <= UNIQUE_ID_LUT(to_integer(unsigned(
                    uniqueIdLutAddress and uniqueIdLutAddressMask)));
   -- Always holds the current Unique ID type of the field being processed.
   FieldUniqueIdType <= UNIQUE_ID_TYPE_LUT(FieldUniqueId);
       
   process(clk_i, fieldNumber_reg)
   variable fieldNumber_var : unsigned(4 downto 0);
   begin

     --asychronous defaults
      -- This section (LSB) of the uniqueIdLutAddress is always the current
      -- fieldNumber.  The MSB portions of this address are registered as
      -- embedded messages are received.
      uniqueIdLutAddress(FIELD_NUM_BITS-1 downto 0) <= fieldNumber_reg;


      if rising_edge(clk_i) then
      --defaults
      
         if reset_i = '1' then
            state <= IDLE;
            varint_reg   <= (OTHERS => (OTHERS => '0'));
            varintCount <= 0;
            fieldNumber_reg <= (OTHERS => '0');
            delimitCount <= 0;
         else

         case state is
            when IDLE =>
               state <= KEY_DECODE;

            when KEY_DECODE => 
               fieldNumber_reg <= fieldNumber;

               case wireType is
                  when VARINT => 
                     varintCount <= 0;
                     state <= VARINT_DECODE;
                  when LENGTH_DELIMITED =>
                     -- could be an embedded message or a
                     -- packed repeated field.
                     state <= LENGTH_DELIMITED_DECODE;
                  when OTHERS =>
                     -- not yet implemented
               end case;

            when LENGTH_DELIMITED_DECODE =>
               -- here we need to decide if this is a length-delimited
               -- type such as a string or repeated value.  OR if 
               -- this is a message.
               case FieldUniqueIdType is
                  when EMBEDDED_MESSAGE =>
                     -- Put the current fieldnumber, which is an ID for an embedded msg
                     -- as part of the uniqueIdLutAddress reg. There is an additional 
                     -- FIELD_NUM_BITS offset since the LSB of the address is always 
                     -- the current field being processed going forward.
                     uniqueIdLutAddress(((numActiveMsgs * FIELD_NUM_BITS) + FIELD_NUM_BITS) + FIELD_NUM_BITS - 1 downto (numActiveMsgs * FIELD_NUM_BITS) + FIELD_NUM_BITS) <= fieldNumber_reg; 

                     state <= KEY_DECODE;
                  when STRING_t =>
                     delimitCount <= to_integer(unsigned(protoStream_i));
                     state <= DECODE_UNTIL_DELIMIT;
                  when OTHERS =>
                     -- more cases to come...
                     state <= VARINT_DECODE;
               end case;

            when VARINT_DECODE =>
               if (protostream_i(7) = '0') then
                  -- end of decode
                  varint_reg   <= (OTHERS => (OTHERS => '0'));
                  state        <= KEY_DECODE;
                  varintCount <=  0;
               else
                  varintCount <= varintCount + 1;
                  varint_reg(varintCount) <= protostream_i(6 downto 0);
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
           data_o       <= (OTHERS => '0');
           fieldValid_o <= '0';
           fieldUniqueId_o <= std_logic_vector(to_unsigned(FieldUniqueId, 32)); 
           delimit_last_o <= '0';

           case state is

            when VARINT_DECODE =>
               if (protostream_i(7) = '0') then
                  -- end of decode
                  for i in 0 to VARINT_NUM_BYTES_MAX-2 loop
                     data_o((i*7)+6 downto (i*7)) <= varint_reg(i);
                  end loop;

                  if varintCount >= MAX_FIELD_BYTE_WIDTH then
                     data_o((MAX_FIELD_BYTE_WIDTH * 8) - 1 downto (varintCount * 7)) <= 
                       protostream_i((MAX_FIELD_BYTE_WIDTH * 8) - 1 - (varintCount * 7)  downto 0);
                  else
                  -- Set the input to be the current index of the VARINT
                     data_o(((varintCount * 7) + 6) downto (varintCount * 7)) <= protostream_i(6 downto 0);
                  end if;

                  fieldValid_o <= '1';
               end if;

            when DECODE_UNTIL_DELIMIT =>
               fieldValid_o <= '1';
               data_o(7 downto 0) <= protostream_i;
               if delimitCount = 1 then
                  delimit_last_o <= '1';
               end if;

            when OTHERS => 
               --do nothing

            end case;

         end process;

         -- This process keeps track of embedded msgs and determines when
         -- to toggle messageValid_o

         process(clk_i)
         begin
            if rising_edge(clk_i) then

              messageValid_o <= '0';

               if reset_i = '1' then
                 numActiveMsgs <= 0;
               else            
                  if (state = LENGTH_DELIMITED_DECODE) then
                     if FieldUniqueIdType = EMBEDDED_MESSAGE then
                       numActiveMsgs <= numActiveMsgs + 1;
                       delimitCountStack(numActiveMsgs) <= to_integer(unsigned(protoStream_i))-1;
                       delimitUniqueIdStack(numActiveMsgs) <= FieldUniqueId;
                     end if;
                  end if;

                  for i in 0 to NUM_MSG_HIERARCHY-1 loop
                     if (numActiveMsgs > i) then
                        delimitCountStack(i) <=
                           delimitCountStack(i)-1;
                     end if;
                  end loop;

                     if (numActiveMsgs > 0) then
                        if (delimitCountStack(numActiveMsgs-1) = 1) then
                           messageValid_o <= '1';
                           messageUniqueId_o <= std_logic_vector(to_unsigned(delimitUniqueIdStack(numActiveMsgs-1),32));
                           numActiveMsgs <= numActiveMsgs - 1;
                        end if;
                     end if;

                end if;

             end if;
      end process;
         -- }}}
      end arch;
      --}}}

