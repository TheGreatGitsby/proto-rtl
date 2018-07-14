library ieee;
use ieee.std_logic_1164.all;

package template_pkg is

   --protobuf non-specific types
   type wiretype_t is (VARINT, SIXTYFOURBIT, LENGTH_DELIMITED, START_GROUP,
                       END_GROUP, THIRTYTWOBIT);

   constant NUM_FIELDS : natural := 6;
   constant MAX_STREAM_LENGTH : natural := 255;
   constant VARINT_NUM_BYTES_MAX : natural := 4;
   type varint_reg_t is array (0 to VARINT_NUM_BYTES_MAX-1) of std_logic_vector(6 downto 0);

   type fieldSize_arr is array (0 to NUM_FIELDS-1) of natural;
   constant fieldSizes : fieldSize_arr := (
   0 => 32,
   1 => 32,
   2 => 32,
   3 => 32,
   4 => 32,
   5 => 32);


   -- delimit counter stack size
   constant MAX_EMBEDDED_DELIMITS : natural := 5;

   type delimitLength_t is array (0 to MAX_EMBEDDED_DELIMITS) of natural range 0 to MAX_STREAM_LENGTH;

   -- Person Subtypes
   type phoneType is (MOBILE, HOME, WORK);

   type Person_phoneNumber is record
      number : std_logic_vector(31 downto 0);
      phone_type : phoneType;
   end record Person_phoneNumber;

   type Person is record
      name : std_logic_vector(7 downto 0);
      id   : std_logic_vector(7 downto 0);
      email : std_logic_vector(31 downto 0);
   end record Person;
   

   -- Create new unique IDs for all fields
   constant NUM_MSG_HIERARCHY : natural := 3;
   constant FIELD_NUM_BITS : natural := 5;
   constant MAX_ARRAY_IDX_BITS : natural := NUM_MSG_HIERARCHY * FIELD_NUM_BITS; 

   -- used in synthesis code for building the LUT address
   type EmbeddedMsgArrIdx is array (0 to NUM_MSG_HIERARCHY-1) of
      std_logic_vector(FIELD_NUM_BITS-1 downto 0);
      

   -- Embedded message handling
   constant MSG_X_MULTIPLIER : natural := 2 ** FIELD_NUM_BITS;
   constant MSG_X_Y_MULTIPLIER : natural := 2 ** (FIELD_NUM_BITS*2);
   constant MSG_1   :  natural := 1 * MSG_X_MULTIPLIER;
   constant MSG_1_1   :  natural := 4 * MSG_X_Y_MULTIPLIER;

   type msg_identifier_arr_t is array (0 to 2**(MAX_ARRAY_IDX_BITS)-1) of natural range 0 to NUM_FIELDS-1;
   constant UNIQUE_ID_LUT : msg_identifier_arr_t := (
      -- MSG_x & MSG_x_y & PROTO_ID => UNIQUE_NUM
      -- to generate, loop through all fields build array address based on msg containers
      1     => 0, -- this is the top level embedded message
      MSG_1 + 1   => 1,
      MSG_1 + 2  => 2,
      MSG_1 + 3   => 3,
      MSG_1 + MSG_1_1 + 1  => 4,
      MSG_1 + MSG_1_1 + 2  => 5,
      OTHERS => 0);

type Fields is (PERSON_NAME, PERSON_ID, PERSON_EMAIL,
   PERSON_PHONENUMBER_NUMBER, PERSON_PHONENUMBER_TYPE);

type varTypes is (EMBEDDED_MESSAGE, VARINT, STRING_t, INT32, CUSTOM_t);
type varTypeLut_arr is array (0 to NUM_FIELDS-1) of varTypes;

constant UNIQUE_ID_TYPE_LUT : varTypeLut_arr := (
0 => EMBEDDED_MESSAGE,
1 => STRING_t,
2 => INT32,
3 => STRING_t,
4 => STRING_t,
5 => CUSTOM_t);   --enum

   

end package template_pkg;

package body template_pkg is
end package body template_pkg;
