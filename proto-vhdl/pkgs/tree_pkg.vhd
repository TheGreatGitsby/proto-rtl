library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
 
package tree_pkg is
   
   type msg_t is (NULL_MSG, ADDRESS_BOOK, PERSON, PHONE_NUMBER); 

   type node_data is record
      field_id     : natural;
      msg_name     : msg_t;
   end record;

                                             
   constant AddressBook_msg : node_data := (field_id => 0,
                                        msg_name => ADDRESS_BOOK);

   constant Person_msg : node_data := (field_id => 1,
                                        msg_name => PERSON);

   constant PhoneNumber_msg : node_data := (field_id => 4,
                                        msg_name => PHONE_NUMBER);

   constant null_msg : node_data := (field_id => 0,
                                        msg_name => NULL_MSG);

   type dependency_t is array 0 to NUM_MSG_HEIRARCHY-1 of node_data;

   constant addr_book_dependency : dependency_t := (0 => AddressBook_msg, others => null_msg);
   constant person_dependency : dependency_t := (0 => AddressBook_msg, 1 => Person_msg, others => null_msg);
   constant PhoneNumber_dependency : dependency_t := (0 => AddressBook_msg, 1 => Person_msg, 2 => PhoneNumber_msg)

    type dependency_arr_t is array 0 to NUM_MSGS-1 of dependency_t;
    constant dependencies : dependency_arr_t := (0 => addr_book_dependency,
                                                 1 => person_dependency,
                                                 2 => PhoneNumber_dependency);

-------------------------------------------------------------


   type node_t is record
      node_id        : natural;
      parent_node_id : natural;
      data             : node_data;
   end record;

   type row_t is array (0 to MAX_NODES_PER_LEVEL-1) of node_t;
   --  array (0 to MAX_CHILDREN_PER_LEVEL-1) of std_logic_vector(USER_DEFINED-1 downto 0);
   type tree_t is array (0 to NUM_MSG_HIERARCHY-1) of row_t;
   --   array (0 to NUM_LEVELS-1) of level_node_id_t;

   constant NULL_NODE  : node_t => (node_id => 0,
                                    parent_node_id => 0,
                                    data => (field_id => 0,
                                             msg_name => NULL));


   constant message_tree : tree_t => (0 => (0 => (node_id => 1,
                                                  parent_node_id => 0,
                                                  data => AddressBook_msg),
                                            others => NULL_NODE),
                                      1 => (0 => (node_id => 2,
                                                  parent_node_id => 1,
                                                  data => Person_msg),
                                            others => NULL_NODE),                                             
                                      2 => (0 => (node_id => 3,
                                                  parent_node_id => 2,
                                                  data => PhoneNumber_msg),
                                            others => NULL_NODE)),                                             

   function tree_generateTree(dependencies : dependency_arr_t)
                             return tree_t is
   begin 
      variable tree : tree_t := (others => (others => NULL_NODE));
      variable unique_id : natural := 0;
      variable cur_parent_node_id : natural := 0;

      for i in 0 to NUM_MSGS-1 loop -- loop all the dependency arrays
         for j in 0 to NUM_MSG_HIERARCHY-1 loop -- loop through each dependency array idx
            if dependencies(i)(j) = null_msg then
               break;
            end if;
            for k in 0 to MAX_NODES_PER_LEVEL-1 loop -- loop through slots in tree level j 
               if tree(j)(k) = dependencies(i)(j)(k) then
                  -- node exists in the tree
                  cur_parent_node_id := tree(j)(k).node_id; 
                  break;
               end if;
               if tree(j)(k) = NULL_NODE then
                  tree(j)(k).data := dependencies(i)(j)(k);
                  tree(j)(k).node_id := unique_id;
                  tree(j)(k).parent_node_id := cur_parent_node_id;
                  unique_id := unique_id + 1;
                  break;
               end if;
         end loop;
      end loop;
      return tree;
   end function;

   function tree_SearchForNode(level_i : natural;
                             current_node : node_t;
                             field_id_i : natural)
                             return node_t is
   begin 
      for i in 0 to MAX_NODES_PER_LEVEL-1 loop
         if message_tree(level_i)(i).data.field_id = field_id_i then
            if message_tree(level_i)(i).parent_node_id = current_node.node_id then
               return message_tree(level_i)(i);
            end if;
         end if;
      end loop;
      return NULL_NODE;
   end function;

   function tree_GetBaseNode()
                             return node_t is
   begin 
         return message_tree(0)(0);
   end function;


end package tree_pkg;

package body tree_pkg is
end package body tree_pkg;
