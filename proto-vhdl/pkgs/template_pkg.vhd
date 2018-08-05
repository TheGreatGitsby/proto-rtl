library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
 
package template_pkg is

   -- generic stuff
   constant DWIDTH : natural := 32;
   type byte_arr_t is array (0 to DWIDTH/8-1) of std_logic_vector(7 downto 0);
   type varint_arr_t is array (0 to DWIDTH/8) of std_logic_vector(6 downto 0);


   --protobuf specified types
   type wiretype_t is (VARINT, SIXTYFOURBIT, LENGTH_DELIMITED, START_GROUP,
                       END_GROUP, THIRTYTWOBIT);

   constant NUM_FIELDS : natural := 8;
   constant MAX_STREAM_LENGTH : natural := 255;
   constant MAX_FIELD_BYTE_WIDTH : natural := 4;
   constant VARINT_NUM_BYTES_MAX : natural := natural(ceil(real(real(MAX_FIELD_BYTE_WIDTH*8)/real(7))));
   type varint_reg_t is array (0 to VARINT_NUM_BYTES_MAX-2) of std_logic_vector(6 downto 0);

   type fieldSize_arr is array (0 to NUM_FIELDS-1) of natural;
   constant fieldSizes : fieldSize_arr := (
   0 => 32,
   1 => 32,
   2 => 32,
   3 => 32,
   4 => 32,
   5 => 32,
   6 => 32,
   7 => 32);


   -- delimit counter stack size
   constant MAX_EMBEDDED_DELIMITS : natural := 5;

   type delimitLength_t is array (0 to MAX_EMBEDDED_DELIMITS) of natural range 0 to MAX_STREAM_LENGTH;

   type delimitUniqueId_t is array (0 to MAX_EMBEDDED_DELIMITS) of natural range 0 to NUM_FIELDS-1;

   -- Person Subtypes
   type phoneType is (MOBILE, HOME, WORK);

   -- Create new unique IDs for all fields
   constant NUM_MSG_HIERARCHY : natural := 3;
   constant FIELD_NUM_BITS : natural := 5;
   constant MAX_ARRAY_IDX_BITS : natural := NUM_MSG_HIERARCHY * FIELD_NUM_BITS; 

   -- used in synthesis code for building the LUT address
   type EmbeddedMsgArrIdx is array (0 to NUM_MSG_HIERARCHY-1) of
      std_logic_vector(FIELD_NUM_BITS-1 downto 0);
      

   -- Embedded message handling
   constant MSG_X_MULTIPLIER   :  natural := 2 ** FIELD_NUM_BITS;
   constant MSG_X_Y_MULTIPLIER :  natural := 2 ** (FIELD_NUM_BITS*2);
   constant MSG_1              :  natural := 1 * MSG_X_MULTIPLIER;
   constant MSG_1_1            :  natural := 4 * MSG_X_Y_MULTIPLIER;

   type msg_identifier_arr_t is array (0 to 2**(MAX_ARRAY_IDX_BITS)-1) of natural range 0 to NUM_FIELDS-1;
   constant UNIQUE_ID_LUT : msg_identifier_arr_t := (
      -- MSG_x_y & MSG_x & PROTO_ID => UNIQUE_NUM
      -- to generate, loop through all fields build array address based on msg containers
      1     => 0, -- this is the top level embedded message
      MSG_1 + 1   => 1,
      MSG_1 + 2  => 2,
      MSG_1 + 3   => 3,
      MSG_1 + 4   => 4,
      MSG_1 + MSG_1_1 + 1  => 5,
      MSG_1 + MSG_1_1 + 2  => 6,
      MSG_1 + 5   => 7, -- the timestamp message
      OTHERS => 0);

type Fields is (PERSON_NAME, PERSON_ID, PERSON_EMAIL,
   PERSON_PHONENUMBER_NUMBER, PERSON_PHONENUMBER_TYPE);

type varTypes is (EMBEDDED_MESSAGE, VARINT, STRING_t, INT32, CUSTOM_t);
type varTypeLut_arr is array (0 to NUM_FIELDS-1) of varTypes;
constant UNIQUE_ID_TYPE_LUT : varTypeLut_arr := 
(
   0 => EMBEDDED_MESSAGE,
   1 => STRING_t,
   2 => INT32,
   3 => STRING_t,
   4 => EMBEDDED_MESSAGE,
   5 => STRING_t,
   6 => CUSTOM_t,   --enum
   7 => EMBEDDED_MESSAGE -- the timestamp message
); 


type wireTypeLut_arr is array (0 to NUM_FIELDS-1) of wiretype_t;
constant WIRE_TYPE_LUT : wireTypeLut_arr := (
   0 => VARINT,
   1 => LENGTH_DELIMITED,
   2 => THIRTYTWOBIT,
   3 => LENGTH_DELIMITED,
   4 => LENGTH_DELIMITED,
   5 => LENGTH_DELIMITED,
   6 => THIRTYTWOBIT,
   7 => LENGTH_DELIMITED
);

-- maps unique id back to protobuf id
type unique_to_proto_id_map_t is array (0 to NUM_FIELDS - 1) of natural; 
constant unique_to_proto_id_map : unique_to_proto_id_map_t :=
(
0 => 1,
1 => 1,
2 => 2,
3 => 3,
4 => 4,
5 => 1,
6 => 2,
7 => 5
);


-- The following describes all the message unique ids included in the
-- top level messages
constant ADDRESSBOOK_NUM_FIELDS : natural := 3;
type addressbookId_t is array (0 to ADDRESSBOOK_NUM_FIELDS-1) of natural;
constant AddressbookId : addressbookId_t := (0, 4, 7);
   

end package template_pkg;

package body template_pkg is
end package body template_pkg;
