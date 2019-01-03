library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tree_pkg.all;

--! Entity Declaration
-- {{{
entity tree_test is
   port (
     field_id_i    :  out std_logic_vector(4 downto 0);
     clk_i         :  in std_logic;
     reset_i       :  in std_logic
);
end tree_test;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of tree_test is 
--! @brief Signal Declarations
-- {{{
   signal tree_test_obj : tree_object_t := tree_generateTree(dependencies);
   signal node : node_t;
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{

       
   process(clk_i)
   begin

      if rising_edge(clk_i) then
      
         if reset_i = '1' then
         else
         end if;
      end if;
   end process;

         -- }}}
      end arch;
      --}}}

