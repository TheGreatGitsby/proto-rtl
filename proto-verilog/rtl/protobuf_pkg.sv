import user_tree_pkg::*;

package protobuf_pkg;

   typedef logic [2:0] proto_wireType;
   typedef logic [3:0] proto_fieldNumber;
   parameter wiretype_varint = 0;
   parameter wiretype_64bit  = 1;
   parameter wiretype_lengthDelimited  = 2;

   parameter MAX_VARINT_BYTES = 10; //considering 64b value max (64/7)

   function logic [2:0] SLICE_WIRE_TYPE(input logic [7:0] keyValue);
     return keyValue[2:0];
   endfunction;

   function logic [3:0] SLICE_FIELD_NUM(input logic [7:0] keyValue);
     return keyValue[6:3];
   endfunction;

   function user_tree_pkg::node_data GET_NODE_DATA(input user_tree_pkg::node_ROM node_meta, input logic [7:0] node_addr);
     return node_meta[node_addr];
   endfunction;

   function user_tree_pkg::msg_size GET_MSG_SIZE(input user_tree_pkg::node_data msg_meta_data);
     return msg_meta_data[user_tree_pkg::NODE_DATA_SIZE-1 -: user_tree_pkg::MAX_MSG_SIZE];
   endfunction;

   function user_tree_pkg::proto_fieldMetaData GET_FIELD_META_DATA(input user_tree_pkg::node_data msg_meta_data, input int idx);
     return msg_meta_data[(idx*user_tree_pkg::FIELD_META_DATA_SIZE)+user_tree_pkg::FIELD_META_DATA_SIZE-1 -: user_tree_pkg::FIELD_META_DATA_SIZE];
   endfunction;

   function logic [user_tree_pkg::IDENTIFIER_SIZE-1:0] GET_FIELD_NUM(input user_tree_pkg::node_data msg_meta_data, input int idx);
     user_tree_pkg::proto_fieldMetaData meta = GET_FIELD_META_DATA(msg_meta_data, idx);
     return meta[user_tree_pkg::IDENTIFIER_SIZE-1 : 0];
   endfunction;


   function logic FIND_FIELD_META_DATA(inout user_tree_pkg::proto_fieldMetaData fieldMetaData, input user_tree_pkg::node_data cur_msg_data, input proto_fieldNumber field_num);
     for(int i=0; i<user_tree_pkg::MAX_FIELDS_PER_MSG; i++) begin
       if (GET_FIELD_NUM(cur_msg_data, i) == field_num) begin
         fieldMetaData = GET_FIELD_META_DATA(cur_msg_data, i);
         return 1;
       end
     end
     return 0;
   endfunction;
   
   function logic [user_tree_pkg::DATA_TYPE_SIZE-1:0] GET_DATA_TYPE(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     return fieldMetaData[user_tree_pkg::IDENTIFIER_SIZE+user_tree_pkg::DATA_TYPE_SIZE-1 -: user_tree_pkg::DATA_TYPE_SIZE];
   endfunction;

   function logic [user_tree_pkg::STRUCT_BYTE_OFFSET_SIZE-1:0] GET_OFFSET(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     return fieldMetaData[user_tree_pkg::IDENTIFIER_SIZE+user_tree_pkg::DATA_TYPE_SIZE+user_tree_pkg::EMBEDDED_MSB_BIT+user_tree_pkg::STRUCT_BYTE_OFFSET_SIZE-1 -: user_tree_pkg::STRUCT_BYTE_OFFSET_SIZE];
   endfunction;

   function logic IS_EMBEDDED_MSG(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     return fieldMetaData[user_tree_pkg::IDENTIFIER_SIZE+user_tree_pkg::DATA_TYPE_SIZE];
   endfunction;

   function logic IS_VARINT_ENCODED(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     logic [user_tree_pkg::DATA_TYPE_SIZE-1:0] data_type;
     data_type = GET_DATA_TYPE(fieldMetaData);
     return data_type[2];
   endfunction;

   function int GET_BYTE_SIZE(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     logic [user_tree_pkg::DATA_TYPE_SIZE-1:0] data_type;
     data_type = GET_DATA_TYPE(fieldMetaData);
     if (data_type[0]) 
       return 4; //32b
     else
       return 8; //64b
   endfunction;

endpackage
