package user_tree_pkg;
 
   parameter NUM_MSG_HIERARCHY = 2;
   parameter NUM_MSGS = 2;
   parameter MAX_NODES_PER_LEVEL = 1;
   parameter IDENTIFIER_SIZE = 4; //TODO: this is a varint and can be larger
   
   // This is the address that logic will
   // receive and uses to map to node_data.
   typedef logic [IDENTIFIER_SIZE-1:0] identifier;
   typedef identifier [NUM_MSG_HIERARCHY-1:0] dependency;
   typedef dependency [NUM_MSGS-1:0] dependencies_t;

   //const dependency addressbook_dependency = {4'h0, 4'h0, 4'h0};
   const dependency person_dependency      = {4'h0, 4'h1};
   const dependency phonenumber_dependency = {4'h4, 4'h1};

   //const dependencies_t dependencies  = {phonenumber_dependency, person_dependency, addressbook_dependency};
   const dependencies_t dependencies  = {phonenumber_dependency, person_dependency};

   // -------------------------------------------------------------
   
   //this is what goes in the RAM/ROM lookup
   //after the node address is found
   parameter MAX_FIELDS_PER_MSG = 4;

   //this is the size of the user address space. no message should be
   //larger than this size (considering all embedded messages and repeated
   //values)
   parameter ADDRESS_SIZE = 16;

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
   
   //TODO:  This number is calculated. This is the largest message size (in
   //bytes) only considering pointers for repeated/embedded msgs.
   // NOTE - This is for a single msg not considering embedded msgs.
   parameter MAX_MSG_SIZE = $bits(256);
   typedef logic[MAX_MSG_SIZE - 1 : 0] msg_size;

   parameter NODE_DATA_SIZE = (MAX_FIELDS_PER_MSG * FIELD_META_DATA_SIZE) + MAX_MSG_SIZE;
   typedef logic[NODE_DATA_SIZE - 1 : 0] node_data;
   const proto_fieldMetaData null_field = '0;

   // Address Book Message
   const msg_size AddressBook_minSize        =  256; //TODO:not accurate, should calculate
   const proto_fieldMetaData people = {1'b0, 1'b1, 8'h00, 1'b1, 3'b000, 4'h1};
   const node_data AddressBook_msg = {AddressBook_minSize, null_field, null_field, null_field, people};

   // Person Message
   const msg_size Person_minSize             =  256; //TODO:not accurate, should calculate
   const proto_fieldMetaData name   = {1'b0, 1'b1, 8'h00, 1'b0, 3'b000, 4'h1};
   const proto_fieldMetaData id     = {1'b0, 1'b1, 8'h04, 1'b0, 3'b101, 4'h2};
   const proto_fieldMetaData email  = {1'b0, 1'b0, 8'h08, 1'b0, 3'b000, 4'h3};
   const proto_fieldMetaData phones = {1'b1, 1'b0, 8'h0c, 1'b1, 3'b000, 4'h4};
   const node_data Person_msg       = {Person_minSize, name, id, email, phones};

   // Phone Number Message
   const msg_size PhoneNumber_minSize        =  256; //TODO:not accurate, should calculate
   const proto_fieldMetaData PhoneNumber_number   = {1'b0, 1'b1, 8'h00, 1'b0, 3'b000, 4'h1};
   const proto_fieldMetaData PhoneNumber_type     = {1'b0, 1'b0, 8'h04, 1'b0, 3'b001, 4'h2};
   const node_data PhoneNumber_msg = {PhoneNumber_minSize, null_field, null_field, PhoneNumber_type, PhoneNumber_number};

   typedef node_data [NUM_MSGS:0] node_ROM;
   const node_ROM ROM_ProtoMetaData = {PhoneNumber_msg, Person_msg, AddressBook_msg};

endpackage
