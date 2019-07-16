package user_tree_pkg;
 
   parameter NUM_MSG_HIERARCHY = 3;
   parameter NUM_MSGS = 3;
   parameter MAX_NODES_PER_LEVEL = 1;
   parameter IDENTIFIER_SIZE = 8;
   
   // This is the address that logic will
   // receive and uses to map to node_data.
   typedef logic [IDENTIFIER_SIZE-1:0] identifier;
   typedef identifier [NUM_MSG_HIERARCHY-1:0] dependency;
   typedef dependency [NUM_MSGS-1:0] dependencies_t;

   const dependency addressbook_dependency = {8'h00, 8'h00, 8'hAA};
   const dependency person_dependency      = {8'h00, 8'hBB, 8'hAA};
   const dependency phonenumber_dependency = {8'hCC, 8'hBB, 8'hAA};

   const dependencies_t dependencies  = {phonenumber_dependency, person_dependency, addressbook_dependency};

   // -------------------------------------------------------------
   
   //this is what goes in the RAM/ROM lookup
   //after the node address is found
   parameter MAX_FIELDS_PER_MSG = 4;
   parameter DATA_TYPE_SIZE = 2;  // 0 - other, 1 - 32b, 2 - 64b, 3 - embedded_msg
   parameter FIELD_META_DATA_SIZE = IDENTIFIER_SIZE + DATA_TYPE_SIZE + STRUCT_BYTE_OFFSET_SIZE + REQUIRED_BIT + REPEATED_BIT;

   typedef logic[FIELD_META_DATA_SIZE-1 : 0] proto_fieldMetaData;
   // Field Meta Data
   // {MSB.......................................................LSB}
   // {Repeated, required, struct_byte_offset, data_type, identifier}
   
   typedef logic[(MAX_FIELDS_PER_MSG * FIELD_META_DATA_SIZE) - 1 : 0] node_data; //this would be msg/var_type/etc

   // Address Book Message
   const proto_fieldMetaData people = {1'b0, 1'b1, 8'h00, 2'b11, 8'h01};
   const node_data AddressBook_msg = {'0, people};

   // Person Message
   const field_meta_data name   = {1'b0, 1'b1, 8'h04, 2'b00, 8'h01};
   const field_meta_data id     = {1'b0, 1'b1, 8'h08, 2'b01, 8'h02};
   const field_meta_data email  = {1'b0, 1'b0, 8'h0C, 2'b00, 8'h03};
   const field_meta_data phones = {1'b1, 1'b0, 8'h10, 2'b11, 8'h04};
   const node_data Person_msg   = {name, id, email, phones};

   // Phone Number Message
   const field_meta_data PhoneNumber_number   = {1'b0, 1'b1, 8'h14, 2'b00, 8'h01};
   const field_meta_data PhoneNumber_type     = {1'b0, 1'b0, 8'h18, 2'b01, 8'h02};
   const node_data PhoneNumber_msg = {'0, PhoneNumber_type, PhoneNumber_number};

   typedef node_data [NUM_MSGS-1:0] node_ROM;
   const ROM_ProtoMetaData = {PhoneNumber_msg, Person_msg, AddressBook_msg};

endpackage
