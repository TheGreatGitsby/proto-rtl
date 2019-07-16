import user_tree_pkg::*;

package protobuf_pkg;

   typedef logic [2:0] proto_wireType;
   typedef logic [4:0] proto_fieldNumber;

   function logic [2:0] SLICE_WIRE_TYPE(input logic [7:0] keyValue);
     return keyValue[2:0];
   endfunction;

   function logic [2:0] SLICE_FIELD_NUM(input logic [7:0] keyValue);
     return keyValue[7:3];
   endfunction;

   function node_data GET_NODE_DATA(input node_ROM node_meta, input logic [7:0] node_addr);
     return node_meta[node_addr];
   endfunction;

   function logic GET_FIELD_META_DATA(inout user_tree_pkg::proto_fieldMetaData fieldMetaData, input user_tree_pkg::node_data cur_msg_data, input proto_fieldNumber field_num);
     for(int i=0; i<MAX_FIELDS_PER_MSG-1; i++) begin
       if (cur_msg_data[i*FIELD_META_DATA_SIZE)+FIELD_META_DATA_SIZE-1 -: user_tree_pkg::IDENTIFIER_SIZE] == field_num) begin
         fieldMetaData = cur_msg_data[i*FIELD_META_DATA_SIZE)+FIELD_META_DATA_SIZE-1 -: FIELD_META_DATA_SIZE];
         return 1;
       end
     end
     return 0;
   endfunction;
   
   function logic [1:0] GET_DATA_TYPE(input user_tree_pkg::proto_fieldMetaData fieldMetaData);
     return fieldMetaData[user_tree_pkg::IDENTIFIER_SIZE+2-1 : user_tree_pkg::IDENTIFIER_SIZE];
   endfunction;

endpackage
