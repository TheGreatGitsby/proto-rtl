package template_pkg is

   constant num_keys := 1;
   type fieldSize_arr is array (0 to num_keys-1) of natural;

   fieldSizes : fieldSize_arr : (
   0 => 32);

   -- Person Subtypes
   type phoneType is (MOBILE, HOME, WORK);

   type Person_phoneNumber is record
      number : std_logic_vector(31 downto 0);
      phone_type : phoneType;
   end phoneNumber;

   type Person is record
      name : std_logic_vector(7 downto 0);
      id   : std_logic_vector(7 downto 0);
      email : std_logic_vector(31 downto 0);
   end record Person;

end package template_pkg;

package body template_pkg is
end package body template_pkg;
