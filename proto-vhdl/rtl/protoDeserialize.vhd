library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity protoDeserialize is
   port (
     protoStream_i  :  in std_logic_vector(7 downto 0);
     unique_id_o    :  out std_logic_vector(31 downto 0);
     data_o         :  out std_logic_vector(31 downto 0);
     messageValid_o :  out std_logic;
     fieldValid_o   :  out std_logic;
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
signal delimitStack_idx      :  natural range 0 to MAX_EMBEDDED_DELIMITS;
signal lengthDelimited_count :  delimitLength_t;

signal varint_reg : varint_reg_t;

-- These signals are to build the UNIQUE_ID_LUT address
signal embeddedMsgIdentifier : EmbeddedMsgArrIdx := (OTHERS => (OTHERS => '0'));
signal embeddedMsgIdentifierPtr : natural := 0;
signal embeddedMsgIdentifierAddress : std_logic_vector(MAX_ARRAY_IDX_BITS - 1 downto 0) := (OTHERS => '0');
signal FieldUniqueId : natural range 0 to NUM_FIELDS-1;
signal VariableTypeLUT : varTypes;

type state_t is (IDLE, KEY_DECODE, VARINT_DECODE, LENGTH_DELIMITED_DECODE, DECODE_UNTIL_DELIMIT); 
signal  state : state_t := IDLE;
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{
   
   --wireType <= protostream_i(2 downto 0);
   wireType <= wiretype_t'VAL(to_integer(unsigned(protostream_i(2 downto 0))));
   fieldNumber <= protostream_i(7 downto 3);

   --Always generate the current UNIQUE_ID_LUT Address
   --  which is the embedded message types concatenated with the current field ID
   process(embeddedMsgIdentifier, fieldNumber_reg)
   begin
     for i in 1 to NUM_MSG_HIERARCHY-1 loop
        embeddedMsgIdentifierAddress(((i * FIELD_NUM_BITS) + FIELD_NUM_BITS - 1) 
          downto (i * FIELD_NUM_BITS)) <= embeddedMsgIdentifier(i-1); 
     end loop;
     embeddedMsgIdentifierAddress(FIELD_NUM_BITS-1 downto 0) <= fieldNumber_reg;
   end process;

   FieldUniqueId   <= UNIQUE_ID_LUT(to_integer(unsigned(embeddedMsgIdentifierAddress)));
   VariableTypeLUT <= UNIQUE_ID_TYPE_LUT(FieldUniqueId);
       
   process(clk_i)
   variable fieldNumber_var : unsigned(4 downto 0);
   begin
      
      -- asynchronous default case
     -- data_o <= (OTHERS => '0');
     -- data_o(7 downto 0) <= protoStream_i;

      if rising_edge(clk_i) then
      --defaults
      
         if reset_i = '1' then
            state <= IDLE;
            varint_reg   <= (OTHERS => (OTHERS => '0'));
            varintCount <= 0;
         else

         case state is
            when IDLE =>
               state <= KEY_DECODE;

            when KEY_DECODE => 
               fieldNumber_reg <= fieldNumber;
               -- get parameter type and see if it's
               -- repeated based on fieldNumber
               --isRepeated(fieldNumber_var) <= something;

               -- get parameter type and see if its
               -- packed based on fieldNumber
               --isPacked(fieldNumber_var) <= something;

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
               case VariableTypeLUT is
                  when EMBEDDED_MESSAGE =>
                     embeddedMsgIdentifier(embeddedMsgIdentifierPtr) <= fieldNumber_reg;
                     state <= KEY_DECODE;
                  when STRING_t =>
                     state <= DECODE_UNTIL_DELIMIT;
                  when OTHERS =>
                     -- more cases to come...
                     state <= VARINT_DECODE;
               end case;

            when VARINT_DECODE =>
               varintCount <= varintCount + 1;
               varint_reg(varintCount) <= protostream_i(6 downto 0);
               if (protostream_i(7) = '0') then
                  -- end of decode
                  varint_reg   <= (OTHERS => (OTHERS => '0'));
                  state        <= KEY_DECODE;
               end if;

            when DECODE_UNTIL_DELIMIT =>
               if delimitCountStack(delimitStack_idx)-1 = 0 then
                  state <= KEY_DECODE; 
               end if;
            end case;
             end if;
         end if;
         end process;

         -- This is an asynchrnous process to control the output
         -- data stream
         process(protostream_i, state)
         begin
           --default case
           data_o       <= (OTHERS => '0');
           fieldValid_o <= '0';
           unique_id_o  <= (OTHERS => '0');

           case state is

            when VARINT_DECODE =>
               if (protostream_i(7) = '0') then
                  -- end of decode
                  for i in 0 to VARINT_NUM_BYTES_MAX-1 loop
                     data_o((i*7)+6 downto (i*7)) <= varint_reg(i);
                  end loop;

                  -- Set the input to be the current index of the VARINT
                  data_o(((VarintCount * 7) + 6) downto (VarintCount * 7)) <= protostream_i(6 downto 0);
                  fieldValid_o <= '1';
               end if;

            when DECODE_UNTIL_DELIMIT =>
               fieldValid_o <= '1';
               data_o(7 downto 0) <= protostream_i;
               unique_id_o <= std_logic_vector(to_unsigned(FieldUniqueId, 32)); 

            when OTHERS => 
               --do nothing

            end case;

         end process;

         -- This process figures out when to toggle messageValid_o
         -- based on delimited setting
         process(clk_i)
            variable delimitStack_idx_var : natural := 0; 
         begin
            if rising_edge(clk_i) then
              messageValid_o <= '0';
               if reset_i = '1' then
                  delimitStack_idx_var := 0;
               else
                  delimitStack_idx_var := delimitStack_idx;
                  
                  if (state = LENGTH_DELIMITED_DECODE) then
                     delimitStack_idx_var := delimitStack_idx_var + 1;
                     delimitCountStack(delimitStack_idx_var) <= to_integer(unsigned(protoStream_i));
                     if VariableTypeLUT = EMBEDDED_MESSAGE then
                       embeddedMsgIdentifierPtr <= embeddedMsgIdentifierPtr + 1;
                     end if;
                  end if;

                  for i in 0 to MAX_EMBEDDED_DELIMITS-1 loop
                  if (delimitStack_idx >= i)  and (delimitCountStack(i) > 0) then
                     delimitCountStack(i) <=
                        delimitCountStack(i)-1;
                  end if;
               end loop;

                     if (delimitCountStack(delimitStack_idx) = 1) and (delimitStack_idx > 0) then
--                        if (VariableTypeLUT = EMBEDDED_MESSAGE) then
                        if (VariableTypeLUT = EMBEDDED_MESSAGE) then
                           messageValid_o <= '1';
                           embeddedMsgIdentifierPtr <= embeddedMsgIdentifierPtr - 1;
                        end if;
                        delimitStack_idx_var := delimitStack_idx_var - 1;
                     end if;

                end if;

                delimitStack_idx <= delimitStack_idx_var;

             end if;
      end process;
         -- }}}
      end arch;
      --}}}

