library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity protoUniqueId is
   port (
     protoMessageId_i    : in std_logic_vector(FIELD_NUM_BITS-1 downto 0);
     protoMessageId_last : in std_logic;
     protoFieldId_i      : in std_logic_vector(FIELD_NUM_BITS-1 downto 0);

     protoWireType_o   : out wiretype_t;

     clk_i             : in std_logic;
     reset_i           : in std_logic
);
end protoUniqueId;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of protoUniqueId is 
--! @brief Signal Declarations
-- {{{
   type uniqueIdLutAddress_arr_t is array (0 to NUM_MSG_HIERARCHY-1) of std_logic_vector(FIELD_NUM_BITS-1 downto 0);
   signal uniqueIdLutAddress_arr : uniqueIdLutAddress_arr_t;

   signal UniqueId : natural;

-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{
   protoWireType_o <= WIRE_TYPE_LUT(UniqueId);

   -- Mask off the upper bits of the unique ID Lut if the bits
   -- are not used (ie not enough active embedded msgs to make
   -- this part of the address possible)
   process(numActiveMsgs)
   begin
      for i in 0 to MAX_ARRAY_IDX_BITS-1 loop
         if (i >= ((numActiveMsgs * FIELD_NUM_BITS) + FIELD_NUM_BITS)) then
            uniqueIdLutAddressMask(i) <= '0'; 
         else
            uniqueIdLutAddressMask(i) <= '1'; 
         end if;
      end loop;
   end process;

   process(uniqueIdLutAddress_arr)
   begin
      -- unpack the array
      for i in 0 to NUM_MSG_HIERARCHY-1 loop
         uniqueIdLutAddress((i*FIELD_NUM_BITS)+FIELD_NUM_BITS-1 downto i*FIELD_NUM_BITS) <= uniqueIdLutAddress_arr(i);
      end loop;
   end process;

   -- Always holds the current Unique ID of the field being processed.
   UniqueId <= UNIQUE_ID_LUT(to_integer(unsigned(
                    uniqueIdLutAddress and uniqueIdLutAddressMask)));
       
   process(clk_i)
   begin
      if rising_edge(clk_i) then
      --defaults
         if reset_i = '1' then
            uniqueIdLutAddress_arr(numActiveMsgs) <= (others => (others => '0'));
         else
            uniqueIdLutAddress_arr(numActiveMsgs) <= protoMessageId_i;
            uniqueIdLutAddress_arr(0)             <= protoFieldId_i;
         end if;
      end if;
   end process;

         process(clk_i)
         begin
            if rising_edge(clk_i) then
               if reset_i = '1' then
                 numActiveMsgs <= 0;
               else            
                  protoMessageId_prev <= protoMessageId_i;
                  if (protoMessageId_i /= protoMessageId_prev) and protoMessageId_last = '0' then
                       numActiveMsgs <= numActiveMsgs + 1;
                  elsif protoMessageId_last = '1' then 
                       for i in NUM_MSG_HIERARCHY-1 downto 0 loop
                          if (numActiveMsgs > i) then
                             -- the end of a message. If there are multiple
                             -- messages ending at the same time, the outer
                             -- most message takes priority with reference to 
                             -- messageUniqueId_o
                             if (protoMessageId_i /= uniqueIdLutAddress_arr(i) ) then
                                messageEndCount := messageEndCount + 1;
                             end if;
                          end if;
                          numActiveMsgs <= numActiveMsgs - messageEndCount;
                       end loop;
                end if;
             end if;
      end process;
         -- }}}
      end arch;
      --}}}

