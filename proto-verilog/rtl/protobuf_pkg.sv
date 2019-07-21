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

   function logic [2:0] SLICE_FIELD_NUM(input logic [7:0] keyValue);
     return keyValue[7:3];
   endfunction;

   function user_tree_pkg::node_data GET_NODE_DATA(input user_tree_pkg::node_ROM node_meta, input logic [7:0] node_addr);
     return node_meta[node_addr];
   endfunction;

   function logic GET_FIELD_META_DATA(inout user_tree_pkg::proto_fieldMetaData fieldMetaData, input user_tree_pkg::node_data cur_msg_data, input proto_fieldNumber field_num);
     for(int i=0; i<user_tree_pkg::MAX_FIELDS_PER_MSG-1; i++) begin
       if (cur_msg_data[(i*user_tree_pkg::FIELD_META_DATA_SIZE)+user_tree_pkg::FIELD_META_DATA_SIZE-1 -: user_tree_pkg::IDENTIFIER_SIZE] == field_num) begin
         fieldMetaData = cur_msg_data[(i*user_tree_pkg::FIELD_META_DATA_SIZE)+user_tree_pkg::FIELD_META_DATA_SIZE-1 -: user_tree_pkg::FIELD_META_DATA_SIZE];
         return 1;
       end
     end
     return 0;
   endfunction;
   
   function logic [user_tree_pkg::DATA_TYPE_SIZE-1:0] GET_DATA_TYPE(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     return fieldMetaData[user_tree_pkg::IDENTIFIER_SIZE+user_tree_pkg::DATA_TYPE_SIZE-1 -: user_tree_pkg::DATA_TYPE_SIZE];
   endfunction;

   function logic IS_EMBEDDED_MSG(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     return fieldMetaData[user_tree_pkg::IDENTIFIER_SIZE+user_tree_pkg::DATA_TYPE_SIZE];
   endfunction;

   function logic IS_VARINT_ENCODED(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     logic [user_tree_pkg::DATA_TYPE_SIZE-1:0] data_type;
     data_type = GET_DATA_TYPE(fieldMetaData);
     return data_type[2];
   endfunction;

endpackage
