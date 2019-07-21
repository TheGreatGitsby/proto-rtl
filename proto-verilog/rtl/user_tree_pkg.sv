package user_tree_pkg;
 
   parameter NUM_MSG_HIERARCHY = 3;
   parameter NUM_MSGS = 3;
   parameter MAX_NODES_PER_LEVEL = 1;
   parameter IDENTIFIER_SIZE = 4; //TODO: this is a varint and can be larger
   
   // This is the address that logic will
   // receive and uses to map to node_data.
   typedef logic [IDENTIFIER_SIZE-1:0] identifier;
   typedef identifier [NUM_MSG_HIERARCHY-1:0] dependency;
   typedef dependency [NUM_MSGS-1:0] dependencies_t;

   const dependency addressbook_dependency = {4'h0, 4'h0, 4'hA};
   const dependency person_dependency      = {4'h0, 4'hB, 4'hA};
   const dependency phonenumber_dependency = {4'hC, 4'hB, 4'hA};

   const dependencies_t dependencies  = {phonenumber_dependency, person_dependency, addressbook_dependency};

   // -------------------------------------------------------------
   
   //this is what goes in the RAM/ROM lookup
   //after the node address is found
   parameter MAX_FIELDS_PER_MSG = 4;

   //Data Type
   // bit 0 - 32b, 
   // bit 1 - 64b, 
   // bit 2 - varint, 
   parameter DATA_TYPE_SIZE = 3;
   parameter STRUCT_BYTE_OFFSET_SIZE = 8; //TODO Calculate this
   parameter REQUIRED_BIT = 1;
   parameter REPEATED_BIT = 1;
   parameter EMBEDDED_MSB_BIT = 1;

   parameter FIELD_META_DATA_SIZE = IDENTIFIER_SIZE + DATA_TYPE_SIZE + EMBEDDED_MSB_BIT + STRUCT_BYTE_OFFSET_SIZE + REQUIRED_BIT + REPEATED_BIT;

   typedef logic[FIELD_META_DATA_SIZE-1 : 0] proto_fieldMetaData;
   // Field Meta Data
   // {MSB.......................................................LSB}
   // {Repeated, required, struct_byte_offset, embedded_msg, data_type, identifier}
   
   typedef logic[(MAX_FIELDS_PER_MSG * FIELD_META_DATA_SIZE) - 1 : 0] node_data; //this would be msg/var_type/etc

   // Address Book Message
   const proto_fieldMetaData people = {1'b0, 1'b1, 8'h00, 1'b1, 3'b000, 4'h1};
   const node_data AddressBook_msg = {'0, people};

   // Person Message
   const proto_fieldMetaData name   = {1'b0, 1'b1, 8'h04, 1'b0, 3'b000, 4'h1};
   const proto_fieldMetaData id     = {1'b0, 1'b1, 8'h08, 1'b0, 3'b101, 4'h2};
   const proto_fieldMetaData email  = {1'b0, 1'b0, 8'h0C, 1'b0, 3'b000, 4'h3};
   const proto_fieldMetaData phones = {1'b1, 1'b0, 8'h10, 1'b1, 3'b000, 4'h4};
   const proto_fieldMetaData Person_msg   = {name, id, email, phones};

   // Phone Number Message
   const proto_fieldMetaData PhoneNumber_number   = {1'b0, 1'b1, 8'h14, 1'b0, 3'b000, 4'h1};
   const proto_fieldMetaData PhoneNumber_type     = {1'b0, 1'b0, 8'h18, 1'b0, 3'b001, 4'h2};
   const node_data PhoneNumber_msg = {'0, PhoneNumber_type, PhoneNumber_number};

   typedef node_data [NUM_MSGS-1:0] node_ROM;
   const node_ROM ROM_ProtoMetaData = {PhoneNumber_msg, Person_msg, AddressBook_msg};

endpackage
