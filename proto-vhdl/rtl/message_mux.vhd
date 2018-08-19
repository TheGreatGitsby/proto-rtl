library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity message_mux is
   port 
   (
      protoStream_o     : out std_logic_vector(7 downto 0);

      AddressBook_valid : in std_logic;
      -- last is used to indicate EOF at the highest
      -- level (ie all embedded messages also end)
      AddressBook_last  : in std_logic;
      AddressBook_data  : in std_logic_vector(31 downto 0);
      -- user stores the proto field id
      AddressBook_user  : in std_logic_vector(3 downto 0);
      -- id stores the proto message id
      -- AddressBook_id(BIT_SOF) - Start of Frame Indicator
      -- AddressBook_id(BIT_EOF) - End of Frame Indicator
      AddressBook_id    : in std_logic_vector(3 downto 0);

      reset : in std_logic;
      clk   : in std_logic
   );
end message_mux;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of message_mux is 
   --! @brief Signal Declarations
   -- {{{
   signal fieldUniqueId   :  std_logic_vector(31 downto 0);
   signal messageUniqueId :  std_logic_vector(31 downto 0);
   signal data            :  std_logic_vector(31 downto 0);
   signal messageLast     :  std_logic;
   signal fieldValid      :  std_logic;
   signal delimit_last    :  std_logic;
   signal fieldProtoId    :  std_logic_vector(3 downto 0);
   signal messageProtoId  :  std_logic_vector(3 downto 0);
   signal select_o        :  std_logic_vector(3 downto 0);
   signal valid_o         :  std_logic;
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   protoSerialize: entity work.protoSerialize
   port map 
   
      protoStream_o     => protoStream_o, -- std_logic_vector(7 downto 0);
      select_o          => select_o -- std_logic_vector(3 downto 0);
      valid_o           => valid_o -- std_logic;

      fieldUniqueId_i   => fieldUniqueId, -- std_logic_vector(31 downto 0);
      messageUniqueId_i => messageUniqueId, -- std_logic_vector(31 downto 0);
      data_i            => data, -- std_logic_vector(31 downto 0);
      messageLast_i     => messageLast, -- std_logic;
      fieldLast_i       => fieldLast, --std_logic;
      fieldValid_i      => fieldValid, -- std_logic;
      clk_i             => clk, -- std_logic;
      reset_i           => reset -- std_logic
   );

protoUniqueId: entity work.protoUniqueId
   port map (
     protoMessageId_i    => protoMessageId_i, -- std_logic_vector(FIELD_NUM_BITS-1 downto 0);
     -- unfortunately we need a message SOF to cover the case of there
     -- being an embedded message id identical to the parent id.
     protoMessageId_sof => AddressBook_id(BIT_SOF), -- std_logic;
     protoMessageId_eof => AddressBook_id(BIT_EOF), -- std_logic;
     protoFieldId_i     => protoFieldId_i, -- std_logic_vector(FIELD_NUM_BITS-1 downto 0);

     protoWireType_o   => protoWireType_o, -- wiretype_t;

     clk_i             => clk_i, -- std_logic;
     reset_i           => reset_i, -- std_logic
);


   -- }}}
   --! @brief RTL
   -- {{{
   -- Need a single stage pipe here to delay a clock
   -- cycle for the wiretype mapping.
   process(clk)
   begin
      if rising_edge(clk) then 
      end if;

   end process;
   -- }}}
end arch;
--}}}

