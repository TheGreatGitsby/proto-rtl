library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tree_pkg.all;

--! Entity Declaration
-- {{{
entity tree_id is
   port (
     input_i    : in std_logic_vector(FIELD_NUM_BITS-1 downto 0);
     last_node  : unique_id;
     level_i     : in natural range 0 to NUM_LEVELS-1;
   
     unique_id   : out natural range 0 to NUM_NODES-1;

     clk_i             : in std_logic;
     reset_i           : in std_logic
);
end tree_id;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of tree_id is 
--! @brief Signal Declarations
-- {{{
   signal tree_unique_id : tree_unique_id_t(0 to MAX_CHILDREN_PER_LEVEL-1);
   signal parent_unique_id: parent_unique_id_t(0 to MAX_CHILDREN_PER_LEVEL-1);
   signal tree : tree_t;

-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{
   process(clk)
   begin
      if rising_edge(clk_i) then
         unique_id <= tree_GetUniqueId(level_i, last_node_i, tree, input_i);
      end if;
   -- }}}
      end arch;
      --}}}

