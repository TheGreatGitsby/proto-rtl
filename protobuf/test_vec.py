import binascii
import os

# print out vhdl pkg syntax
print("library ieee;")
print("use ieee.std_logic_1164.all;")
print("package tb_stimulus_pkg is")

with open("simple", "rb") as f:
    fileSize = os.path.getsize('./simple')
    print("constant NUM_INPUT_BYTES : natural := {};".format(fileSize))
    print("type input_arr_t is array (0 to NUM_INPUT_BYTES-1) of std_logic_vector(7 downto 0);".format(fileSize))
    print("constant input_vec : input_arr_t :=(");
    for i in range(fileSize-1):
    # Do stuff with byte.
       byte = f.read(1)
       print("{} => x\"{}\",".format(i, binascii.b2a_hex(byte).decode("utf-8"),))
       #print(count,"=> ","x\"",binascii.b2a_hex(byte),"\"");
    #do last byte
    byte = f.read(1)
    print("{} => x\"{}\");".format(fileSize-1, binascii.b2a_hex(byte).decode("utf-8"),))


print("end package tb_stimulus_pkg;")
print("package body tb_stimulus_pkg is")
print("end package body tb_stimulus_pkg;")

