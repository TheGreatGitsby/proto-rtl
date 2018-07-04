library ieee;
use ieee.std_logic_1164.all;

package template_pkg is

   constant NUM_FIELDS : natural := 6;
   constant MAX_STREAM_LENGTH : natural := 255;
   constant VARINT_NUM_BYTES_MAX : natural := 4;

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
   constant MAX_IDENTIFIER_NUM_BITS : natural := 3;
   constant MAX_ARRAY_IDX_BITS : natural := NUM_MSG_HIERARCHY * MAX_IDENTIFIER_NUM_BITS; 

   -- Embedded message handling
   constant MSG_X_MULTIPLIER : natural := 2 * MAX_IDENTIFIER_NUM_BITS;
   constant MSG_X_Y_MULTIPLIER : natural := 2 * (2 * MAX_IDENTIFIER_NUM_BITS);
   constant MSG_1   :  natural := 1 * MSG_X_MULTIPLIER;
   constant MSG_1_1   :  natural := 4 * MSG_X_Y_MULTIPLIER;

   type msg_identifier_arr_t is array (0 to 2**(MAX_ARRAY_IDX_BITS)-1) of natural range 0 to NUM_FIELDS-1;
   constant fieldIdentifier : msg_identifier_arr_t := (
      -- MSG_x_y & MSG_x & PROTO_ID => UNIQUE_NUM
      -- CONCATED_PROTOBUF_ID => UNIQUE_NUM,
      -- to generate, loop through all fields build array address based on msg containers
      MSG_1 + 1   => 0,
      MSG_1 + 2  => 1,
      MSG_1 + 3   => 2,
      MSG_1 + MSG_1_1 + 1  => 3,
      MSG_1 + MSG_1_1 + 2  => 4,
      OTHERS => 0);

type Fields is (PERSON_NAME, PERSON_ID, PERSON_EMAIL,
   PERSON_PHONENUMBER_NUMBER, PERSON_PHONENUMBER_TYPE);

   

end package template_pkg;

package body template_pkg is
end package body template_pkg;
