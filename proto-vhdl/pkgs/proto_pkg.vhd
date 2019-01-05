library ieee;
use ieee.std_logic_1164.all;
 
package proto_pkg is

   constant NUM_EMBEDDED_MSG_HIERARCHY : natural := 3;
   constant NUM_EMBEDDED_MSGS : natural := 3;

   --protobuf specified types
   type wiretype_t is (VARINT, SIXTYFOURBIT, LENGTH_DELIMITED, START_GROUP,
                       END_GROUP, THIRTYTWOBIT);

   -- Person Subtypes
   type phoneType is (MOBILE, HOME, WORK);

   -- delimit counter stack size
   constant MAX_EMBEDDED_DELIMITS : natural := 5;
   constant MAX_STREAM_LENGTH : natural := 255;
   type delimitLength_t is array (0 to NUM_EMBEDDED_MSG_HIERARCHY) of natural range 0 to MAX_STREAM_LENGTH;

end package proto_pkg;

package body proto_pkg is
end package body proto_pkg;
