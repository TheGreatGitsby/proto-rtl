import user_tree_pkg::*;
import tree_pkg::*;
import protobuf_pkg::*;

module protoDeserialize
(
  input    logic [7:0]  protoStream_i,
  input    logic        protoStream_valid_i,
  input    logic [31:0] dest_base_addr, //this is the translation address base from system memory

  output   logic        wr_en_o,
  output   logic [7:0]  byte_sel_o,
  
  output   logic [user_tree_pkg::ADDRESS_SIZE-1:0]  addr_o,
  output   logic [64:0] data_o,

  input    logic        clk_i,
  input    logic        reset_i
);

//Generate the tree and ROM structures for the field numbers
const tree_t tree = tree_pkg::tree_generateTree(user_tree_pkg::dependencies);
logic [7:0]       node_addr;
logic             message_exists;

protobuf_pkg::proto_wireType      wireType;
protobuf_pkg::proto_fieldNumber   fieldNumber;
user_tree_pkg::proto_fieldMetaData fieldMetaData;
user_tree_pkg::node_data    msg_meta_data;
logic [6:0] varint_reg [0:protobuf_pkg::MAX_VARINT_BYTES-1];
logic fieldMetaDataValid;

logic [3:0]  varint_count;
logic [7:0]  delimitCount;  //255 byte max?
logic [7:0]  delimitCountStack [0 : user_tree_pkg::NUM_MSG_HIERARCHY-1];
logic [user_tree_pkg::ADDRESS_SIZE-1:0] baseAddressStack  [0 : user_tree_pkg::NUM_MSG_HIERARCHY-1];
logic [user_tree_pkg::ADDRESS_SIZE-1:0] write_address_tail;

logic [$clog2(NUM_MSG_HIERARCHY)-1:0] numActiveMsgs;

logic packed_repeated;
//TODO: num_values needs a max number of repeated values (not just 32b)
logic [31:0] num_values;

typedef enum {
  KEY_DECODE, LENGTH_DELIMITED_DECODE, VARINT_DECODE, DECODE_UNTIL_DELIMIT
} protobuf_state_t;

protobuf_state_t  state;

assign msg_meta_data = user_tree_pkg::ROM_ProtoMetaData[node_addr]; 
//wireType      <= protostream_i(2 downto 0);
//fieldNumber   <= protostream_i(7 downto 3);

always_ff @(posedge clk_i)
begin
  if(reset_i == 1) begin
    state           <= KEY_DECODE;
    varint_reg      <= '{default:0};
    delimitCount    <= 0;
    packed_repeated <= 0;
  end
  else begin

    //defaults

    case (state)

      KEY_DECODE: begin

        //TODO:  Handle decoding this as a varint.  right now we
        //       are assuming 4b or less field num.
        
        //default
        fieldMetaDataValid <= 0;
        packed_repeated <= 0;

        //update tail_ptr if this is the start of a new msg
        //if(message_exists)
        //  write_address_tail <= write_address_tail + user_tree_pkg::ADDRESS_SIZE'(protobuf_pkg::GET_MSG_SIZE(msg_meta_data)); 


        if (protoStream_valid_i) begin 

          wireType      <= protobuf_pkg::SLICE_WIRE_TYPE(protoStream_i);
          fieldNumber   <= protobuf_pkg::SLICE_FIELD_NUM(protoStream_i);
          fieldMetaDataValid <= protobuf_pkg::FIND_FIELD_META_DATA(fieldMetaData, msg_meta_data, protobuf_pkg::SLICE_FIELD_NUM(protoStream_i));

          case (protobuf_pkg::SLICE_WIRE_TYPE(protoStream_i))

            protobuf_pkg::wiretype_varint : begin
              varint_count <= 0;
              state <= VARINT_DECODE;
            end

            protobuf_pkg::wiretype_lengthDelimited : begin 
              // could be an embedded message or a
              // packed repeated field.
              state <= LENGTH_DELIMITED_DECODE;
            end

            //TODO: add others
            
          endcase
        end
      end

      LENGTH_DELIMITED_DECODE : begin
        // here we need to decide if this is a length-delimited
        // type such as a string or repeated value.  OR if 
        // this is a message.
        // TODO: add if(field_metadata_valid)
        if (protobuf_pkg::IS_EMBEDDED_MSG(fieldMetaData)) begin
          state <= KEY_DECODE;
          write_address_tail <= write_address_tail + user_tree_pkg::ADDRESS_SIZE'(protobuf_pkg::GET_MSG_SIZE(msg_meta_data)); 
        end
        else begin
          delimitCount    <= protoStream_i;
          if (protobuf_pkg::GET_DATA_TYPE(fieldMetaData) != 0) begin
            packed_repeated <= 1;
            num_values <= '0;
          end
          if(protobuf_pkg::IS_VARINT_ENCODED(fieldMetaData))
            state  <= VARINT_DECODE;
          else
            state  <= DECODE_UNTIL_DELIMIT;
        end
      end

      VARINT_DECODE : begin
        if (packed_repeated == 1)
          delimitCount <= delimitCount - 1;
        if (protoStream_i[7] == 1'b0) begin
          // end of decode
          varint_reg   <= '{default:0};
          varint_count <=  0;
          state <= KEY_DECODE; 
          if (packed_repeated == 1) begin
            num_values <= num_values + 1;
            if (delimitCount != 1) begin
              // packed repeated field continues
              state <= VARINT_DECODE;
              write_address_tail <= write_address_tail + user_tree_pkg::ADDRESS_SIZE'(protobuf_pkg::GET_BYTE_SIZE(fieldMetaData)); 
            end
          end
        end
        else begin
          varint_count <= varint_count + 1;
          varint_reg[varint_count] <= protoStream_i[6:0];
        end
      end

      DECODE_UNTIL_DELIMIT : begin
        delimitCount <= delimitCount - 1;
        write_address_tail <= write_address_tail + 1;
        if (delimitCount == 1)
          state <= KEY_DECODE; 
      end

    endcase

      end
    end

    // output data stream control
    always_comb
    begin

      //defaults
      data_o     = '0;
      wr_en_o    = 0;
      byte_sel_o = '0;
      addr_o     = '0;

      case (state)

        KEY_DECODE: begin
          //here we write the number of instances of a repeated
          //type or a varint that was previously written.
          if(packed_repeated == 1) begin
            wr_en_o     = 1;
            data_o[31 : 0] = num_values;
            byte_sel_o    = 8'b00001111;
            addr_o   = user_tree_pkg::ADDRESS_SIZE'(protobuf_pkg::GET_OFFSET(fieldMetaData)) - 4 + baseAddressStack[numActiveMsgs];
          end
        end

        LENGTH_DELIMITED_DECODE : begin
          //here we write the pointer in the struct to either this 
          //embedded message or this array/repeated value
          wr_en_o     = 1;
          data_o[31 : 0] = dest_base_addr + 32'(write_address_tail);
          byte_sel_o    = 8'b00001111;
          addr_o   = baseAddressStack[numActiveMsgs] + user_tree_pkg::ADDRESS_SIZE'(protobuf_pkg::GET_OFFSET(fieldMetaData));
        end

        VARINT_DECODE : begin
          for(int i=0; i<protobuf_pkg::MAX_VARINT_BYTES; i++) begin
            data_o[(i*7)+7 -: 7] = varint_reg[i]; 
          end
          data_o[(varint_count*7)+7 -: 7] = protoStream_i[6:0];
          if (!protoStream_i[7]) begin
            wr_en_o = 1;
          end
          for(int i=0; i<8; i++) begin
            if (i < protobuf_pkg::GET_BYTE_SIZE(fieldMetaData))
              byte_sel_o[i] = 1;
            else
              byte_sel_o[i] = 0;
          end
          if (packed_repeated)
            addr_o     = write_address_tail;
          else
            addr_o     = user_tree_pkg::ADDRESS_SIZE'(protobuf_pkg::GET_OFFSET(fieldMetaData)) + baseAddressStack[numActiveMsgs];
        end

        DECODE_UNTIL_DELIMIT : begin
          wr_en_o = 1;
          data_o[7:0] = protoStream_i;
          byte_sel_o = 8'b00000001; //1 byte
          addr_o     = write_address_tail;
        end

        default : begin 
        //do nothing
      end
    endcase;
  end;

  // This process keeps track of embedded msgs
  always_ff @(posedge clk_i)
  begin

    logic [$clog2(NUM_MSG_HIERARCHY)-1:0] messageEndCount;
    logic [$clog2(NUM_MSG_HIERARCHY)-1:0] messageStartCount = 0;

    messageStartCount = 0;
    messageEndCount   = 0;
    message_exists <= 0;

    if (reset_i == 1) begin
      numActiveMsgs <= 0;
      baseAddressStack <= '{default:'0};
    end
    else begin            
      if (state == LENGTH_DELIMITED_DECODE) begin
        if (protobuf_pkg::IS_EMBEDDED_MSG(fieldMetaData)) begin
          messageStartCount = 1;
          baseAddressStack[numActiveMsgs]  <= write_address_tail;
          delimitCountStack[numActiveMsgs] <= protoStream_i - 1;
          //TODO: handle the case when a message doesnt exist
          message_exists  <= tree_pkg::tree_SearchChildNodes(tree, node_addr, fieldNumber);
        end
      end
      for (int i=user_tree_pkg::NUM_MSG_HIERARCHY-1; i>=0; i--) begin
        if (numActiveMsgs > i[$bits(numActiveMsgs)-1:0]) begin
          delimitCountStack[i] <= delimitCountStack[i]-1;
          if (delimitCountStack[i] == 1) begin
            // the end of a message.
            messageEndCount = messageEndCount + 1;
            node_addr = tree_pkg::SLICE_PARENT_NODE_ADDR(tree[node_addr]);
          end
        end
      end
      numActiveMsgs <= numActiveMsgs + messageStartCount - messageEndCount;
    end
  end

endmodule
