import user_tree_pkg::*;
import tree_pkg::*;
import protobuf_types::*;

module protoDeserialize
(
  input    logic [7:0]  protoStream_i,
  input    logic        protoStream_valid_i,

  output   logic        valid_o,
  output   logic [7:0]  parameter_byte_sel_o,
  output   logic [4:0]  fieldNumber_o, //proto_fieldNumber type
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

signal varintCount           :  natural range 0 to 8;
signal delimitCountStack     :  delimitLength_t;
logic [7:0] delimitCount;


signal numActiveMsgs          :  natural := 0;

signal packed_repeated : std_logic;

typedef enum {KEY_DECODE, VARINT_DECODE, LENGTH_DELIMITED_DECODE, DECODE_UNTIL_DELIMIT} state_t; 

state_t  state = IDLE;
-- }}}

   dataType      <= LUT_ROM(node_addr);
   fieldNumber_o <= fieldNumber;
   //wireType      <= protostream_i(2 downto 0);
   //fieldNumber   <= protostream_i(7 downto 3);

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

             field_exists  <= tree_SearchChildNodes(tree, node_addr, `SLICE_FIELD_NUM(protostream_i))
             wireType      <= `SLICE_WIRE_TYPE(protostream_i);
             fieldNumber   <= `SLICE_FIELD_NUM(protostream_i);

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
                if (packed_repeated == 1) begin
                  delimitCount <= delimitCount - 1;
                end
                if (protostream_i[7] = 0) begin
                  // end of decode
                  varint_reg   <= '0;
                  varint_count <=  0;
                  if (packed_repeated == 1) begin
                    if (delimitCount == 1) begin
                        packed_repeated <= '0';
                        state <= KEY_DECODE; 
                    end
                    else begin
                        // packed repeated field continues
                        state <= VARINT_DECODE;
                    end
                  end
                  else begin
                    state  <= KEY_DECODE;
                  end
                end
                else begin
                  varint_count <= varint_count + 1;
                  varint_reg[varint_count] <= protostream_i[6 downto 0];
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
         always_comb
         begin

           //defaults
           parameter_val_o <= '0;

           case (state) begin 

             `VARINT_DECODE : begin
               for(int i=0; i<MAX_VARINT_BYTES; i++) begin
                 parameter_val_o[(i*7)+7 -: 7] <= varint_reg[i]; 
               end
               parameter_val_o[(varint_count*7)+7 -: 7] <= protoStream_i;
               valid_o <= !protoStream_i[7];
               //TODO: The byte select needs to be dependent on the data
               //type stored in ROM.
               parameter_byte_sel_o <= 8'b00000001;
             end

             `DECODE_UNTIL_DELIMIT : begin
               valid_o <= '1';
               parameter_val_o(7 downto 0) <= protostream_i;
             end

             default : begin 
               //do nothing
             end
           endcase;

         end process;

         // This process keeps track of embedded msgs and determines when
         // to toggle messageLast_o
         always_ff @(posedge clk_i)
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
                        // the end of a message. If there are multiple
                        // messages ending at the same time, the outer
                        // most message takes priority with reference to 
                        // messageUniqueId_o
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

