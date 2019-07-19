import user_tree_pkg::*;
import tree_pkg::*;
import protobuf_pkg::*;

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

protobuf_pkg::proto_wireType      wireType;
protobuf_pkg::proto_fieldNumber   fieldNumber;
protobuf_pkg::proto_dataType      dataType;
protobuf_pkg::proto_fieldMetaData fieldMetaData;
user_tree_pkg::field_meta_data    msg_meta_data;
logic [6:0] varint_reg [0:MAX_VARINT_BYTES-1];
logic fieldMetaDataValid;

logic [3:0] varint_count;
logic [7:0] delimitCount;  //255 byte max?
logic [7:0] delimitCountStack [0 : NUM_MSG_HIERARCHY-1];

logic [7:0] numActiveMsgs;

logic packed_repeated;

typedef enum {
  KEY_DECODE, LENGTH_DELIMITED_DECODE, VARINT_DECODE, DECODE_UNTIL_DELIMIT
} protobuf_state_t;

protobuf_state_t  state = KEY_DECODE;

   dataType      <= LUT_ROM(node_addr);
   fieldNumber_o <= fieldNumber;
   msg_meta_data <= GET_NODE_DATA(ROM_ProtoMetaData, node_addr); 
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

           //default
           fieldMetaDataValid <= 0;

           if (protoStream_valid_i) begin 

             wireType      <= SLICE_WIRE_TYPE(protostream_i);
             fieldNumber   <= SLICE_FIELD_NUM(protostream_i);
             fieldMetaDataValid <= GET_FIELD_META_DATA(fieldMetaData, msg_meta_data, SLICE_FIELD_NUM(protostream_i));

             case (SLICE_WIRE_TYPE(protostream_i))
               protobuf_pkg::wiretype_varint : begin
                 varintCount <= 0;
                 state <= VARINT_DECODE;
               end
               protobuf_pkg::wiretype_lengthDelimited : begin 
                 // could be an embedded message or a
                 // packed repeated field.
                 state <= LENGTH_DELIMITED_DECODE;
               end
               //TODO: add others
              endcase;
            end

            LENGTH_DELIMITED_DECODE : begin
              // here we need to decide if this is a length-delimited
              // type such as a string or repeated value.  OR if 
              // this is a message.
              if (protobuf_pkg::IS_EMBEDDED_MSG(fieldMetaData))
                state <= KEY_DECODE;
              else begin
                delimitCount    <= protoStream_i;
                if (protobuf_pkg::GET_DATATYPE(fieldMetaData) != 0)
                  packed_repeated <= 1;
                if(protobuf_pkg::IS_VARINT_ENCODED(fieldMetaData))
                  state  <= VARINT_DECODE;
                else
                  state  <= DECODE_UNTIL_DELIMIT;
              end
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

         // This is an asynchronous process to control the output
         // data stream
         always_comb
         begin
           //defaults
           parameter_val_o <= '0;

           case (state) begin 

             VARINT_DECODE : begin
               for(int i=0; i<MAX_VARINT_BYTES; i++) begin
                 parameter_val_o[(i*7)+7 -: 7] <= varint_reg[i]; 
               end
               parameter_val_o[(varint_count*7)+7 -: 7] <= protoStream_i;
               valid_o <= !protoStream_i[7];
               //TODO: The byte select needs to be dependent on the data
               //type stored in ROM.
               parameter_byte_sel_o <= 8'b00000001;
             end

             DECODE_UNTIL_DELIMIT : begin
               valid_o <= '1';
               parameter_val_o(7 downto 0) <= protostream_i;
             end

             default : begin 
               //do nothing
             end
           endcase;
         end;

         // This process keeps track of embedded msgs and determines when
         // to toggle messageLast_o
         always_ff @(posedge clk_i)

           automatic int messageEndCount;
           automatic int messageStartCount;

           messageStartCount = 0;
           messageEndCount   = 0;

           if (reset_i == '1')
             numActiveMsgs <= 0;
           else begin            
             if (state == LENGTH_DELIMITED_DECODE) begin
               if (protobuf_pkg::IS_EMBEDDED_MSG(fieldMetaData)) begin
                 messageStartCount = 1;
                 delimitCountStack[numActiveMsgs] <= protoStream_i - 1;
                 message_exists  <= tree_SearchChildNodes(tree, node_addr, fieldNumber);
               end
             end
             for (int i=user_tree_pkg::NUM_MSG_HIERARCHY-1; i>=0; i--) begin
               if (numActiveMsgs > i) begin
                 delimitCountStack[i] <= delimitCountStack(i)-1;
                 if (delimitCountStack[i] == 1) begin
                   // the end of a message.
                   messageEndCount = messageEndCount + 1;
                   node_addr = SLICE_PARENT_NODE_ADDR(tree[node_addr]);
                 end;
               end;
             end;
             numActiveMsgs <= numActiveMsgs + messageStartCount - messageEndCount;
           end;
         end;
       end;

