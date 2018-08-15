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

      fieldUniqueId_i   :  in std_logic_vector(31 downto 0);
      messageUniqueId_i :  in std_logic_vector(31 downto 0);
      data_i            :  in std_logic_vector(31 downto 0);
      messageLast_i     :  in std_logic;
      fieldLast_i       :  in std_logic;
      fieldValid_i      :  in std_logic;

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

   signal processing_message :  std_logic := '0';
   signal processing_field   :  std_logic := '0';

begin

   wireType       <= WIRE_TYPE_LUT(to_integer(unsigned(fieldUniqueId_i)));
   wireType_vec   <= std_logic_vector(to_unsigned(wiretype_t'POS(wireType), 3));
   fieldProtoId   <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(fieldUniqueId_i))), 5));
   MessageProtoId <= std_logic_vector(to_unsigned(unique_to_proto_id_map(to_integer(unsigned(messageUniqueId_i))), 5));

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

   process(clk)
   begin
      if rising_edge(clk_i) then
         --defaults
         byte_buf_ptr(0)     <= 0;
         fieldvalid(0)       <= '0';
         fieldUniqueId(0)    <= fieldUniqueId_i;
         wireType_pipe(0)    <= wireType;
         embedded_msg_sof(0) <= '0';
         embedded_msg_eof(0) <= '0';
         delimit_len_ptr(0)  <= delimit_len_ptr(NUM_PIPE_STAGES-1); --hold the value
         delimit_count(0)  <= 0
         for i in 1 to NUM_PIPE_STAGES-1 loop
            if fieldValid_i = '1' then
               byte_buf_ptr(i)     <= byte_buf_ptr(i-1);
               fieldvalid(i)       <= fieldvalid(i-1);
               fieldUniqueId(i)    <= fieldUniqueId(i-1);
               wireType_pipe(i)    <= wireType_pipe(i-1);
               embedded_msg_sof(i) <= embedded_msg_sof(i-1);
               embedded_msg_eof(i) <= embedded_msg_eof(i-1);
               delimit_len_ptr(i) <= delimit_len_ptr(i-1);
               delimit_count(i)    <= delimit_count(i-1);
            end if;
         end loop;

   -- The first stage of the pipeline just looks for new messages
   -- or else does nothing but register the input data for the next
   -- pipe.
         if fieldValid_i = '1' then
            -- TODO: and there is enough space (back pressure if not)
            if processing_message = '0' then
               processing_message <= '1';
               -- start of a new message
               -- add the embedded msg wire type
               byte_buf(0) <= MessageProtoId & std_logic_vector(to_unsigned(wiretype_t'POS(LENGTH_DELIMITED), 3));
               -- need to add a space for length
               byte_buf(1) <= x"00";
               byte_buf_ptr(0) <= 2;
               embedded_msf_sof(0) <= '1';
            end if;
            if messageLast_i = '1' then
               embedded_msg_eof(0) <= '1';
               processing_message <= '0';
            end if;

            fieldvalid(0) <= '1';
         end if;

      -- The second stage of the pipeline looks for the start of 
      -- new fields.
         if fieldvalid(0) = '1' then
            if processing_field = '0' then
               processing_field <= '1';
               -- it is a new field type
               -- need to add wiretype in byte_buffer
               byte_buf(0)(byte_buf_ptr(0)) <= fieldProtoId & wireType_vec;
               byte_buf_ptr(1) <= byte_buf_ptr(0)+1;

               if wireType_pipe(0) = LENGTH_DELIMITED then
                  -- need to add a space for length
                  byte_buf(0)(byte_buf_ptr(0)+1) <= x"00";
                  byte_buf_ptr(1) <= byte_buf_ptr(0)+2;
                  -- delimit_len_ptr is a pointer to the embedded msg
                  -- ring where the length field will be stored.
                  delimit_len_ptr(1) <= embedded_msg_ptr+2;
               end if;

               if fieldLast_i = '1' then
                  --set flag for field no longed in progress
                  processing_field <= '0';
               end if;
            end if;
         end if;

         -- The third stage of the pipeline updates the byte_buf with
         -- payload data.
         if fieldvalid(1) = '1' then
            case wireType_pipe(1) is 
               when VARINT =>
                  -- need to figure out a formula for the max interations
                  -- we need to for a varint.  right now we assume
                  -- 32b and only need 0 to DWIDTH/8. (or 5)
                  varint_done := '0';
                  varint_iter := 0;
                  for i in 0 to DWIDTH/8 loop
                     if varint_done = '0' then
                        byte_buf(byte_buf_ptr(1) + varint_iter) <= '1' & data_varint_arr(i);
                        varint_iter := varint_iter + 1;
                        if data_varint_arr(i)(6) = '0' then
                           varint_done := '1';
                        end if;
                     end if;
                  end loop;
                  byte_buf_ptr(2) <= byte_buf_ptr(1) + varint_iter;

               when LENGTH_DELIMITED =>
                  -- need to support select lines
                  -- right now ends on DWIDTH boundary
                  for i in 0 to DWIDTH/8-1 loop
                     byte_buf(byte_buf_ptr(1)+i) <= data_byte_arr(i);
                  end loop;
                  byte_buf_ptr(2) <= byte_buf_ptr(1) + 4;
                  delimit_count(1) <= delimit_count(1) + 4; 
                  if fieldLast_i(1) = '1' then
                     delimit_count(1) <= 4; 
                     delimit_count(2) <= delimit_count(1) + 4; 
                     delimit_eof(2) <= '1';
                  end if;

               when THIRTYTWOBIT =>
                  for i in 0 to 3 loop
                     byte_buf(byte_buf_ptr(1)+i) <= data_byte_arr(i);
                  end loop;
                  byte_buf_ptr(2) <= byte_buf_ptr(1) + 4;
               when others =>
            -- more to come
            -- do nothing
            end case;
         end if;

         -- The fourth stage of the pipeline copies the byte_buf to the 
         -- embedded Message ring.
         if fieldvalid(2) = '1' then
            for i in 0 to MAX_NUM_OUTPUT_BYTES-1 loop
               if (i < byte_buf_ptr) then
                  embedded_msg_ring(embedded_msg_ptr+i) <= byte_buf(i);
               end if;
            end loop;
            embedded_msg_ptr <= embedded_msg_ptr + byte_buf_ptr;
         end if;
         if delimit_eof(2) = '1' then
            embedded_msg_ring(delimit_len_ptr(2)) <= std_logic_vector(to_unsigned(delimit_count, 8);
         end if;
         if embedded_msg_sof(2) = '1' then
            -- this is the start of a new message
            numActiveMsgs <= numActiveMsgs + 1;
            embeddedMsg_LengthPtrStack(numActiveMsgs) <= embedded_msg_ring_ptr + 1;
         end if;
         if embedded_msg_eof(2) = '1' then
         -- update the length field of embedded msg
            embedded_msg_ring(embeddedMsg_LengthPtrStack(numActiveMsgs-1))) <= std_logic_vector(to_unsigned(embeddedMsgCountStack(numActiveMsgs-1), 8));
            numActiveMsgs <= numActiveMsgs - 1;
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
            -- if there is atleast 1 embedded message or 
            -- a length_delimited message is coming though
            -- we need to wait until the end to output.
            if numActiveMsgs = 0 or () then
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

