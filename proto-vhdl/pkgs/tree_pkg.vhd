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
      parent_node_id : natural;
      data           : node_data;
   end record;

   type row_t is array (0 to MAX_NODES_PER_LEVEL-1) of natural;
   type tree_t is array (0 to NUM_MSG_HIERARCHY-1) of row_t;
   type path_t is array (0 to NUM_MSG_HIERARCHY-1) of natural;
   type tree_meta_t is record
      cur_node_id : natural;
      level : natural;
      cur_path : path_t;
   end record;
   type node_id_lut_t is array (0 to NUM_MSGS-1) of node_t;
   type tree_object_t is record
      tree : tree_t;
      node_lut : node_id_lut_t;
   end record;

   constant NULL_NODE  : node_t => (
                                    parent_node_id => 0,
                                    data => (field_id => 0,
                                             msg_name => NULL));


--   constant message_tree : tree_t => (0 => (0 => (node_id => 1,
--                                                  parent_node_id => 0,
--                                                  data => AddressBook_msg),
--                                            others => NULL_NODE),
--                                      1 => (0 => (node_id => 2,
--                                                  parent_node_id => 1,
--                                                  data => Person_msg),
--                                            others => NULL_NODE),                                             
--                                      2 => (0 => (node_id => 3,
--                                                  parent_node_id => 2,
--                                                  data => PhoneNumber_msg),
--                                            others => NULL_NODE)),                                             

   function tree_generateTree(dependencies : dependency_arr_t)
                             return tree_object_t is
   begin 
      variable tree : tree_t := (others => (others => 0));
      variable node_lut : node_id_lut_t := (others => NULL_NODE);
      variable unique_id : natural := 1;
      variable cur_parent_node_id : natural := 0;

      for i in 0 to NUM_MSGS-1 loop -- loop all the dependency arrays
         for j in 0 to NUM_MSG_HIERARCHY-1 loop -- loop through each dependency array idx
            if dependencies(i)(j) = null_msg then
               break;
            end if;
            for k in 0 to MAX_NODES_PER_LEVEL-1 loop -- loop through slots in tree level j 
               if node_lut(tree(j)(k)).data = dependencies(i)(j)(k) then
                  -- node exists in the tree
                  cur_parent_node_id := node_lut(tree(j)(k)).data.node_id; 
                  break;
               end if;
               if tree(j)(k) = 0 then
                  node_lut(unique_id).data := dependencies(i)(j)(k);
                  node_lut(unique_id).parent_node_id := cur_parent_node_id;
                  tree(j)(k) := unique_id;
                  unique_id := unique_id + 1;
                  break;
               end if;
         end loop;
      end loop;
      variable tree_obj : tree_object_t := (tree => tree, node_lut => node_lut);
      return tree_obj;
   end function;

   function tree_GetNodeUniqueId(tree : tree_obj_t;
                         level : natural;
                         node_idx : natural)
                         return natural is
   begin
         return tree.tree(level)(node_idx);
   end function;

   function tree_GetNode(tree : tree_obj_t;
                         level : natural;
                         node_idx : natural)
                         return node_t is
   begin
         return tree.node_lut(tree_GetNodeUniqueId(tree, level, node_idx));
   end function;

   function tree_GetNode(tree : tree_obj_t;
                         unique_id : natural)
                         return node_t is
   begin
         return tree.node_lut(unique_id);
   end function;

   function tree_GetNodeData(tree : tree_obj_t;
                         level : natural;
                         node_idx : natural)
                         return node_data is
   begin
         return tree_GetNode(tree, level, node_idx).data;
   end function;

   function tree_GetNodeData(tree : tree_obj_t;
                         unique_id : natural)
                         return node_data is
   begin
         return tree_GetNode(tree, unique_id).data;
   end function;

   function tree_GetNodeFieldId(tree : tree_obj_t;
                         level : natural;
                         node_idx : natural)
                         return natural is
   begin
         return tree_GetNodeData(tree, level, node_idx).field_id;
   end function;

   function tree_GetNodeParentId(tree : tree_obj_t;
                         level : natural;
                         node_idx : natural)
                         return natural is
   begin
         return tree_GetNodeData(tree, level, node_idx).parent_node_id;
   end function;

   function tree_SearchForNode(tree : tree_obj_t;
                             tree_meta : tree_meta_t;
                             field_id_i : natural)
                             return natural is
   begin 
      variable level : natural := tree_meta.level) + 1
      for i in 0 to MAX_NODES_PER_LEVEL-1 loop
         if tree_GetNodeFieldId(tree, level, i) = field_id_i then
            if tree_GetNodeParentId(tree, level, i) = tree_meta.node_id then
               return tree_GetNodeUniqueId(tree, level, i);
            end if;
         end if;
      end loop;
      return 0;
   end function;

   function tree_NodeExists(node_id : natural)
                             return bool is
   begin 
      if node_id != 0 then
         return true;
      end if;
      return 0;
   end function;

   function tree_GetNextNode(tree : tree_obj_t;
                             tree_meta : tree_meta_t;
                             field_id_i : natural)
                             return node_t is
   begin 
      variable unique_id : natural := tree_SearchForNode(tree, tree_meta, field_id_i);
      if unique_id = 0 then
         return NULL_NODE; 
      end if;
      return tree_GetNode(unique_id);
   end function;

   function tree_AdvanceNodePtr(tree : tree_obj_t;
                                tree_meta : tree_meta_t;
                                unique_id : natural)
                                return tree_meta_t is
   begin 
      variable tree_meta_new : tree_meta_t;

      tree_meta_new.cur_node_id                   <= unique_id;
      tree_meta_new.level                         <= tree_meta.level + 1;
      tree_meta_new.cur_path(tree_meta.level + 1) <= unique_id;
      return tree_meta_new;

   end function;

   function tree_RewindNodePtr(tree_meta : tree_meta_t)
                                return tree_meta_t is
   begin 
      variable tree_meta_new : tree_meta_t;

      tree_meta_new.level                         <= tree_meta.level - 1;
      return tree_meta_new;

   end function;

end package tree_pkg;

package body tree_pkg is
end package body tree_pkg;
