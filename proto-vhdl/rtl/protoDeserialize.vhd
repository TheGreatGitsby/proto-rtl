library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.template_pkg.all;

--! Entity Declaration
-- {{{
entity protoDeserialize is
   port (
     protoStream_i  :  in std_logic_vector(7 downto 0);
     key_o          :  out std_logic_vector(1 downto 0);
     data_o         :  out std_logic_vector(31 downto 0);
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
signal fieldNumber_reg : natural;
signal varintCount : natural range 0 to 8;
signal delimitCountStack : delimitLength_t; 
signal delimitStack_idx : natural range 0 to MAX_EMBEDDED_DELIMITS;
signal lengthDelimited_count : delimitLength_t; 

type varint_reg_t is array (0 to VARINT_NUM_BYTES_MAX-1) of std_logic_vector(6 downto 0);
signal varint_reg : varint_reg_t;

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
   fieldNumber <= unsigned(protostream_i(7 downto 3));

   process(clk_i)
   variable fieldNumber_var : unsigned(4 downto 0);
   begin
      if rising_edge(clk_i) then
      --defaults
      fieldValid_o <= '0';
      data_o <= (others => '0');
      
         if reset_i = '1' then
            state <= IDLE;
         else

         case state is
            when IDLE =>
               state <= VARINT_KEY;

            when VARINT_KEY => 
               fieldNumber_reg <= to_integer(unsigned(fieldNumber));
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
                  when OTHERS =>
                     -- not yet implemented
               end case;

            when LENGTH_DELIMITED_DECODE =>
               -- do nothing, handled in other process
               state <= VARINT_KEY;

            when VARINT_DECODE =>
               varintCount <= varintCount + 1;
               varint_reg(varintCount) <= protostream_i(6 downto 0);
               if (protostream_i(7) = '0') then
                  -- end of decode
                  for i in 0 to VARINT_NUM_BYTES_MAX-1 loop
                     data_o((i*7)+6 downto (i*7)) <= varint_reg(i);
                  end loop;
                  fieldValid_o <= '1';
                  state <= VARINT_KEY;
               end if;
               end case;
             end if;
         end if;
         end process;

         -- This process figures out when to toggle messageValid_o
         -- based on delimited setting
         process(clk_i)
            variable delimitStack_idx_var : natural := 0; 
         begin
            if rising_edge(clk_i) then
              messageValid_o <= '0';
               if reset_i = '1' then
                  delimitStack_idx_var := 0;
               else
                  delimitStack_idx_var := delimitStack_idx;
                  
                  if (state = LENGTH_DELIMITED_DECODE) then
                     delimitStack_idx_var := delimitStack_idx_var + 1;
                     delimitCountStack(delimitStack_idx_var) <= to_integer(unsigned(protoStream_i));
                  end if;

                  if (delimitStack_idx > 0)  then
                     delimitCountStack(delimitStack_idx) <=
                        delimitCountStack(delimitStack_idx)-1;

                     if delimitCountStack(delimitStack_idx)-1 = 0 then
                        messageValid_o <= '1';
                        delimitStack_idx_var := delimitStack_idx_var - 1;
                     end if;

                  end if;

                end if;

                delimitStack_idx <= delimitStack_idx_var;

             end if;
      end process;
         -- }}}
      end arch;
      --}}}

