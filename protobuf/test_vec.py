import binascii
import os

# print out vhdl pkg syntax
print("library ieee;")
print("use ieee.std_logic_1164.all;")
print("package tb_stimulus_pkg is")

with open("simple", "rb") as f:
    byte = f.read(1)
    count = 0
    fileSize = os.path.getsize('./simple')
    print("type input_arr_t is array (0 to {}-1) of std_logic_vector(7 downto 0);".format(fileSize))
    print("constant input_vec : input_arr_t :=(");
    while byte != b'':
    # Do stuff with byte.
       print("{} => x\"{}\",".format(count, binascii.b2a_hex(byte).decode("utf-8"),))
       #print(count,"=> ","x\"",binascii.b2a_hex(byte),"\"");
       count += 1
       byte = f.read(1)

print("end package tb_stimulus_pkg;")
print("package body tb_stimulus_pkg is")
print("end package body tb_stimulus_pkg;")

