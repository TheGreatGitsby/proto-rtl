library ieee;
use ieee.std_logic_1164.all;

--! Entity Declaration
-- {{{
entity template is
   port (
     protoStream_i  :  in std_logic_vector(7 downto 0);
     key_o          :  out std_logic_vector(1 downto 0);
     data_o         :  out std_logic_vector;
     messageValid_o :  out std_logic;
     fieldValid_o   :  out std_logic
);
end template;
-- }}}
--! @brief Architecture Description
-- {{{
architecture arch of template is 
--! @brief Signal Declarations
-- {{{
-- }}}

begin
   --! @brief Component Port Maps
   -- {{{
   -- }}}
   --! @brief RTL
   -- {{{
   process(clk)
   begin
      if rising_edge(clk) then

         --defaults
         fieldValid_o <= '0';
         data_o <= (others => '0');

         case state is
            when IDLE =>

            when VARINT_KEY => 
               wwireType_var := protostream(2 downto 0);
               wireType <= wireType_var;
               fieldNumber_var := unsigned(protostream(7 downto 3));
               fieldNumber <= fieldNumber_var;
               -- get parameter type and see if it's
               -- repeated based on fieldNumber
               isRepeated(fieldNumber_var) <= something;

               -- get parameter type and see if its
               -- packed based on fieldNumber
               isPacked(fieldNumber_var) <= something;

               case wireType_var is
                  when 0 => 
                     varintCount <= 0;
                     state <= VARINT_DECODE;
                  when 2 =>
                     -- could be an embedded message or a
                     -- packed repeated field.
                     state <= LENGTH_DELIMITED_DECODE;
                     lengthDelimited(fieldNumber) <= '1';
               end case;

            when LENGTH_DELIMITED_DECODE =>
               lengthDelimited_numBytes(fieldNumber) <= protoStream_i;
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
         end process

         -- This process figures out when to toggle messageValid_o
         -- based on delimited setting
         process()
         begin
            messageValid_o <= '0';

            for i in 0 to numFields-1 loop
               if lengthDelimited(i) = '1' then
                  if lengthDelimited_count(i) = lengthDelimited_numBytes(i) - 1 then
                     messageValid_o <= '1';
                  end if;
               end if;
            end loop;
         end if;
      end process;

         -- counts the length delimited fields
      process(clk)
      begin
         for i in 0 to numFields-1 loop
            if lengthDelimited(i) = '1' then
               if lengthDelimited_count = lengthDelimited_numBytes - 1 then
                  lengthDelimited_count(i) <= 0;
               else
                  lengthDelimited_count(i) <= lengthDelimited_count(i) + 1;
               end if;
            end if;
         end loop;

         -- }}}
      end arch;
      --}}}

