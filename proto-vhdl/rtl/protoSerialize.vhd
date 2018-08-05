library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity protoSerialize is
   port 
   (
      protoStream_o     : out std_logic_vector(DWIDTH-1 downto 0);
      select_o          : out std_logic_vector(DWIDTH/8-1 downto 0); 
      valid_o           : out std_logic;

      fieldUniqueId_i   : in std_logic_vector(31 downto 0);
      messageUniqueId_i : in std_logic_vector(31 downto 0);
      data_i            : in std_logic_vector(31 downto 0);
      messageLast_i     : in std_logic;
      fieldValid_i      : in std_logic;
      delimit_last_i    : in std_logic;

      clk_i             : in std_logic;
      reset_i           : in std_logic
   );
end protoSerialize;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of protoSerialize is 
   --! @brief Signal Declarations
   -- {{{
   -- TODO figure out length of array.  needs to be pwr of 2-1
   type embeddedMsg_arr_t is array (0 to 128-1) of std_logic_vector(7 downto 0);
   signal byte_buffer   :  embeddedMsg_arr_t;

   signal wireType      :  wiretype_t;
   signal last_wireType :  wiretype_t;
   signal wireType_vec  :  std_logic_vector(2 downto 0);
   signal fieldProtoId       :  std_logic_vector(4 downto 0);
   signal last_messageUniqueId : std_logic_vector(31 downto 0);
   signal MessageProtoId       :  std_logic_vector(4 downto 0);

   signal delimit_count : natural;
   signal delimit_len_ptr : natural;

   signal data_byte_arr : byte_arr_t; 
   signal data_varint_arr : varint_arr_t;

   signal head_ptr : natural range 0 to 128-1;
   signal tail_ptr : natural range 0 to 128-1;

   type lengthPtr_t is array (0 to MAX_EMBEDDED_DELIMITS) of natural range 0 to 128-1; 
   signal embeddedMsg_LengthPtrStack : lengthPtr_t;
   signal embeddedMsgCountStack : delimitLength_t;

   signal numActiveMsgs : natural range 0 to MAX_EMBEDDED_DELIMITS;

   signal last_fieldUniqueId : std_logic_vector(31 downto 0);

begin

   wireType     <= WIRE_TYPE_LUT(to_integer(unsigned(fieldUniqueId_i)));
   wireType_vec <= std_logic_vector(to_unsigned(wiretype_t'POS(wireType), 3));
   fieldProtoId      <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(fieldUniqueId_i))), 5));
   MessageProtoId      <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(messageUniqueId_i))), 5));

   process(data_i)
   -- pack the byte array for easy byte access in rtl
   begin
      for i in 0 to DWIDTH/8-1 loop
         data_byte_arr(i) <= data_i((8*i)+7 downto i*8);
      end loop;
   end process;

   process(data_i)
   -- pack the varint byte array for easy byte access in rtl
   begin
      for i in 0 to DWIDTH/8 loop
         if i = DWIDTH/8 then
            -- TODO figure out formula to do this generically and
            -- not rely on this being 32b
            data_varint_arr(i) <= "0000" & data_i(31 downto 28);
         else
            data_varint_arr(i) <= data_i((7*i)+6 downto i*7);
      end if;
      end loop;
   end process;

   process(clk_i)
      -- This process analyzes the input data and puts it
      -- into the byte_buffer and updates head pointer.
      variable head_ptr_var : natural range 0 to 6;
      variable varint_done : std_logic;
   begin
      if rising_edge(clk_i) then
         if reset_i = '1' then
            byte_buffer <= (others => (others => '0'));
            head_ptr <= 0;
         else
            head_ptr_var := 0;
            if fieldValid_i = '1' then
               if messageUniqueId_i /= last_messageUniqueId then
                  -- start of a new message
                  -- add the embedded msg wire type
                  byte_buffer(head_ptr + head_ptr_var) <= MessageProtoId & std_logic_vector(to_unsigned(wiretype_t'POS(LENGTH_DELIMITED), 3));
                  head_ptr_var := head_ptr_var + 1;
                  -- need to add a space for length
                  byte_buffer(head_ptr + head_ptr_var) <= x"00";
                  head_ptr_var := head_ptr_var + 1;
               end if;
               if messageLast_i = '1' then
               -- it is the end of a message
               -- update the length field of embedded msg
                  byte_buffer(embeddedMsg_LengthPtrStack(numActiveMsgs-1)) <= std_logic_vector(to_unsigned(embeddedMsgCountStack(numActiveMsgs-1), 8));
               end if;
               if fieldUniqueId_i /= last_fieldUniqueId then
                  -- it is a new field type
                  -- need to add wiretype in byte_buffer
                  byte_buffer(head_ptr + head_ptr_var) <= fieldProtoId & wireType_vec;
                  head_ptr_var := head_ptr_var + 1;
                  last_fieldUniqueId <= fieldUniqueId_i;

                  if wireType = LENGTH_DELIMITED then
                     -- need to add a space for length
                     byte_buffer(head_ptr + head_ptr_var) <= x"00";
                     delimit_len_ptr <= head_ptr + head_ptr_var;
                     head_ptr_var := head_ptr_var + 1;
                     delimit_count <= 0;
                  end if;

                  if last_wireType = LENGTH_DELIMITED then
                     -- need to update the length field
                     -- of the last delimited field
                     byte_buffer(delimit_len_ptr) <= std_logic_vector(to_unsigned(delimit_count, 8));

                  end if;
               end if;
               -- update the byte buffer with data
               case wireType is 
                  when VARINT =>
                     -- need to figure out a formula for the max interations
                     -- we need to for a varint.  right now we assume
                     -- 32b and only need 0 to DWIDTH/8. (or 5)
                     varint_done := '0';
                     for i in 0 to DWIDTH/8 loop
                        if varint_done = '0' then
                           byte_buffer(head_ptr + head_ptr_var) <= '1' & data_varint_arr(i);
                           head_ptr_var := head_ptr_var + 1;
                           if data_varint_arr(i)(6) = '0' then
                              varint_done := '1';
                           end if;
                        end if;
                     end loop;
                  when LENGTH_DELIMITED =>
                     -- need to support select lines
                     -- right now ends on DWIDTH boundary
                     for i in 0 to DWIDTH/8-1 loop
                        byte_buffer(head_ptr + head_ptr_var) <= data_byte_arr(i);
                        head_ptr_var := head_ptr_var + 1;
                     end loop;
                     delimit_count <= delimit_count + 4; 
                  when THIRTYTWOBIT =>
                     for i in 0 to 3 loop
                        byte_buffer(head_ptr + head_ptr_var) <= data_byte_arr(i);
                        head_ptr_var := head_ptr_var + 1;
                     end loop;
                  when others =>
               -- more to come
               -- do nothing
               end case;

               head_ptr <= head_ptr + head_ptr_var;

            end if;
         end if;
      end if;
   end process;

   process(clk_i)
         -- this process outputs available processed data and updates
         -- the tail pointer  
      variable tail_ptr_var : natural range 0 to DWIDTH/8;
   begin
      if rising_edge(clk_i) then
         if reset_i = '1' then
            tail_ptr <= 128-1;
         else
            -- if there is atleast 1 embedded message, we need to wait 
            -- until the end to output.
            if numActiveMsgs = 0 then
               tail_ptr_var := 0;
               for i in 1 to DWIDTH/8 loop
                  if tail_ptr+i /= head_ptr then
                     protoStream_o((i*8) - 1 downto (i*8) - 8) <= byte_buffer(tail_ptr+i);
                     tail_ptr_var := tail_ptr_var + 1;
                     select_o(i-1) <= '1';
                  end if;
               end loop;
               tail_ptr <= tail_ptr + tail_ptr_var;
            end if;
         end if;
      end if;
   end process;

   process(clk_i)
      -- this process manages embededded messages and updates length fields.
      -- it updates the number of available embedded messages for the output
      -- process once the length has been updated.
   begin
      if rising_edge(clk_i) then
         if fieldValid_i ='1' then
            if messageUniqueId_i /= last_messageUniqueId then
               -- this is the start of a new message
               numActiveMsgs <= numActiveMsgs + 1;
               embeddedMsg_LengthPtrStack(numActiveMsgs) <= head_ptr;
            end if;

            if messageLast_i = '1' then
               numActiveMsgs <= numActiveMsgs - 1;
            end if;

            for i in 0 to NUM_MSG_HIERARCHY-1 loop
               if (i < numActiveMsgs) then
                  embeddedMsgCountStack(i) <= embeddedMsgCountStack(i) + 1; 
               end if;
            end loop;
         end if;
      end if;
   end process;


   -- }}}
end arch;
--}}}

