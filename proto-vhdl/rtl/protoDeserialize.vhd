library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Entity Declaration
-- {{{
entity protoDeserialize is
   port (
     protoStream_i  :  in std_logic_vector(7 downto 0);
     key_o          :  out std_logic_vector(1 downto 0);
     data_o         :  out std_logic_vector;
     messageValid_o :  out std_logic;
     fieldValid_o   :  out std_logic;
     clk_i          :  in std_logic;
     reset_i        :  in std_logic
);
end protoDeserialize;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of protoDeserialize is 
--! @brief Signal Declarations
-- {{{
signal wireType : std_logic_vector(2 downto 0);
signal fieldNumber : unsigned(4 downto 0);
signal fieldNumber_reg : unsigned(4 downto 0);
signal varintCount : natural range 0 to 8;
type state_t is (IDLE, VARINT_KEY, VARINT_DECODE, LENGTH_DELIMITED_DECODE); 
signal  state : state_t := IDLE;
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{
   
   wireType <= protostream_i(2 downto 0);
   fieldNumber <= (unsigned)protostream_i(7 downto 3);

   process(clk_i)
   variable fieldNumber_var : unsigned(4 downto 0);
   begin
      if rising_edge(clk_i) then
         if reset_i = '1' then
            state <= IDLE;
         else

         --defaults
         fieldValid_o <= '0';
         data_o <= (others => '0');
         is reset_i = '1' then
            state <= IDLE;
         else

         case state is
            when IDLE =>

            when VARINT_KEY => 
               fieldNumber_reg <= fieldNumber;
               -- get parameter type and see if it's
               -- repeated based on fieldNumber
               --isRepeated(fieldNumber_var) <= something;

               -- get parameter type and see if its
               -- packed based on fieldNumber
               --isPacked(fieldNumber_var) <= something;

               case wireType is
                  when "000" => 
                     varintCount <= 0;
                     state <= VARINT_DECODE;
                  when "010" =>
                     -- could be an embedded message or a
                     -- packed repeated field.
                     state <= LENGTH_DELIMITED_DECODE;
                     lengthDelimited(fieldNumber_reg) <= '1';
                  when OTHERS =>
                     -- not yet implemented
               end case;

            when LENGTH_DELIMITED_DECODE =>
               lengthDelimited_numBytes(fieldNumber_reg) <= protoStream_i;
               state <= VARINT_KEY;

            when VARINT_DECODE =>
               varintCount <= varintCount + 1;
               varint_reg(varintCount) <= protostream(6 downto 0);
               if (protostream(7) = '0') then
                  -- end of decode
                  for i in 0 to NUM_BYTES_MAX-1 loop
                     data_o((i*7)+6 downto (i*7)) <= varint_reg(i);
                  end loop
                  fieldValid_o <= '1';
                  state <= VARINT_KEY;
               end if;
            end if;
         end if;
         end process

         -- This process figures out when to toggle messageValid_o
         -- based on delimited setting
         process(lengthDelimited,lengthDelimited_count)
         begin
            if reset_i = '1' then
               lengthDelimited <= (others => '0');
            else
               if ((state = VARINT_KEY) and (wireType = "010")) 
                 lengthDelimited(fieldNumber) = '1';
               end if;
               messageValid_o <= '0';
               for i in 0 to numFields-1 loop
                  if lengthDelimited(i) = '1' then
                     if lengthDelimited_count(i) = lengthDelimited_numBytes(i) - 1 then
                        messageValid_o <= '1';
                        lengthDelimited(i) = '0';
                     end if;
                  end if;
               end loop;
             end if;
      end process;

      -- counts the length delimited fields
      process(lengthDelimited)
      begin
         if reset_i = '1' then
            lengthDelimited_count <= (OTHERS => (OTHERS => '0'));
         else
            for i in 0 to numFields-1 loop
               if lengthDelimited(i) = '1' then
                  if lengthDelimited_count = lengthDelimited_numBytes - 1 then
                     lengthDelimited_count(i) <= 0;
                  else
                     lengthDelimited_count(i) <= lengthDelimited_count(i) + 1;
                  end if;
               end if;
            end loop;
         end if;
      end process;

         -- }}}
      end arch;
      --}}}

