library ieee;
use ieee.std_logic_1164.all;

package template_pkg is

   constant NUM_FIELDS : natural := 1;
   constant MAX_STREAM_LENGTH : natural := 255;
   constant VARINT_NUM_BYTES_MAX : natural := 8;

   type fieldSize_arr is array (0 to NUM_FIELDS-1) of natural;
   constant fieldSizes : fieldSize_arr := (
   0 => 32);

   type delimitLength_t is array (0 to NUM_FIELDS-1) of natural range 0 to MAX_STREAM_LENGTH;

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

end package template_pkg;

package body template_pkg is
end package body template_pkg;
