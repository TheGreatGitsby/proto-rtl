import user_tree_pkg::*;
import tree_pkg::*;
import protobuf_types::*;

module protoDeserialize
(
  input    logic [7:0]  protoStream_i,
  input    logic        protoStream_valid_i,

  output   logic        valid_o,
  output   logic [4:0]  field_num_o, //proto_fieldNumber type
  output   logic [63:0] parameter_val_o

  input    logic        clk_i,
  input    logic        reset_i
);

//Generate the tree and ROM structures for the field numbers
const tree_t tree = tree_generateTree(user_tree_pkg::dependencies);
logic [7:0]       node_addr;

proto_wireType    wireType;
proto_fieldNumber fieldNumber;
proto_dataType    dataType;
typedef logic [6:0] varint;
typedef varint [7:0] varint_arr;
varint_arr varint_reg;

signal fieldNumber_reg       :  std_logic_vector(4 downto 0);
signal varintCount           :  natural range 0 to 8;
signal delimitCountStack     :  delimitLength_t;
logic [7:0] delimitCount;


signal numActiveMsgs          :  natural := 0;

signal packed_repeated : std_logic;

typedef enum {KEY_DECODE, VARINT_DECODE, LENGTH_DELIMITED_DECODE, DECODE_UNTIL_DELIMIT} state_t; 

state_t  state = IDLE;
-- }}}

   wireType    <= protostream_i(2 downto 0);
   fieldNumber <= protostream_i(7 downto 3);
   dataType    <= LUT_ROM(node_addr);

   always_ff @(posedge clk_i)
   begin

     if (reset_i = '1') begin
       state           <= KEY_DECODE;
       varint_reg      <= '0;
       varintCount     <= 0;
       fieldNumber_reg <= '0;
       delimitCount    <= 0;
       packed_repeated <= 0;
     end
     else begin

       //defaults
       field_exists <= 0;

       case (state)

         KEY_DECODE: begin

           if (protoStream_valid_i) begin 

             fieldNumber_reg <= fieldNumber;
             field_exists <= tree_SearchChildNodes(tree, node_addr, fieldNumber))

             case (wireType)
               `VARINT : begin
                 varintCount <= 0;
                 state <= VARINT_DECODE;
               end
               `LENGTH_DELIMITED : begin 
                 // could be an embedded message or a
                 // packed repeated field.
                 state <= LENGTH_DELIMITED_DECODE;
               end
              endcase;
            end

            LENGTH_DELIMITED_DECODE : begin
               // here we need to decide if this is a length-delimited
               // type such as a string or repeated value.  OR if 
               // this is a message.
               case (dataType)
                 `EMBEDDED_MESSAGE : begin
                   state <= KEY_DECODE;
                 end
                 `STRING_t : begin
                   delimitCount <= protoStream_i;
                   state        <= DECODE_UNTIL_DELIMIT;
                   // These stats are packed-repeated since a non-LENGTH_DELIMITED type
                   // came in.
                 end
                 `VARINT : begin
                   packed_repeated <= 1;
                   delimitCount    <= protoStream_i;
                   state           <= VARINT_DECODE;
                 end
                 default : begin
                   // more cases to come...
                   delimitCount    <= protoStream_i;
                   state           <= DECODE_UNTIL_DELIMIT;
                 end
                endcase;
              end

              VARINT_DECODE : begin
                if (packed_repeated == 1)
                  delimitCount <= delimitCount - 1;
                if (protostream_i(7) = 0) begin
                  // end of decode
                  varint_reg   <= '0;
                  varintCount <=  0;
                  if (packed_repeated == 1) begin
                    if (delimitCount == 1) begin
                        packed_repeated <= '0';
                        state <= KEY_DECODE; 
                    end
                    else
                        // packed repeated field continues
                        state <= VARINT_DECODE;
                  end
                  else
                     state  <= KEY_DECODE;
                end
                else begin
                  varintCount <= varintCount + 1;
                  varint_reg(varintCount) <= protostream_i(6 downto 0);
                end;

               DECODE_UNTIL_DELIMIT : begin
                  delimitCount <= delimitCount - 1;
               if (delimitCount == 1)
                  state <= KEY_DECODE; 
               endcase;
             end;
         end;

         // This is an asynchrnous process to control the output
         // data stream
         process(protostream_i, state, FieldUniqueId, varint_reg, varintCount)
         begin
           //default case
           data_o          <= '0;
           fieldValid_o    <= 0;
           fieldUniqueId_o <= std_logic_vector(to_unsigned(FieldUniqueId, 32)); 
           delimit_last_o  <= 0;

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
         -- to toggle messageLast_o

         process(clk_i)
            variable messageEndCount : natural range 0 to NUM_MSG_HIERARCHY-1;
            variable messageStartCount : natural range 0 to 1;
         begin
            if rising_edge(clk_i) then

              messageLast_o <= '0';
              messageStartCount := 0;
              messageEndCount := 0;
              messageUniqueId_o <= (others => '0');
              if numActiveMsgs > 0 then
                messageUniqueId_o <= std_logic_vector(to_unsigned(delimitUniqueIdStack(numActiveMsgs-1),32));
             end if;

               if reset_i = '1' then
                 numActiveMsgs <= 0;
               else            
                  if (state = LENGTH_DELIMITED_DECODE) then
                     if dataType = EMBEDDED_MESSAGE then
                       messageStartCount := 1;
                       delimitCountStack(numActiveMsgs) <= to_integer(unsigned(protoStream_i))-1;
                       delimitUniqueIdStack(numActiveMsgs) <= FieldUniqueId;
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
                           messageUniqueId_o <= std_logic_vector(to_unsigned(delimitUniqueIdStack(i),32));
                           messageEndCount := messageEndCount + 1;
                        end if;
                     end if;
                  end loop;

                  numActiveMsgs <= numActiveMsgs + messageStartCount - messageEndCount;

                end if;

             end if;
      end process;
         -- }}}
      end arch;
      --}}}

