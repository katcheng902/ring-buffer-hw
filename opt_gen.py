'''
This file generates the registers & their initialization.
Inputs: element size 8, 16, or 32 and [array of ring buffer capacities]; e.g., 32 2,3,4 will generate 3 ring buffers of capacities 2,3,4 all with element size 32
'''

import sys

try:
    elt_size = int(sys.argv[1])
    arr = str(sys.argv[2]).split(",")
except Exception as e:
    print("Failed to parse arguments")
    exit(1)

num = len(arr)
for i in range(len(arr)):
    tmp = arr[i]
    arr[i] = int(tmp)

#P4 FILE
p4_template = "#include <core.p4>\n#if __TARGET_TOFINO__ == 3\n#include <t3na.p4>\n#elif __TARGET_TOFINO__ == 2\n#include <t2na.p4>\n#else\n#include <tna.p4>\n#endif\n\n#include \"include/headers.p4\"\n#include \"include/util.p4\"\n\nstruct metadata_t {}"
p4_template += ("\n#define REG_SIZE 32\n#define ELT_SIZE %d\nRegister<bit<REG_SIZE>, bit<32>> (%d, 0) lefts;\nRegister<bit<REG_SIZE>, bit<32>> (%d, 0) heads; \nRegister<bit<REG_SIZE>, bit<32>> (%d,0) tails;\nRegister<bit<REG_SIZE>, bit<32>> (%d,0) sizes;\nRegister<bit<1>, bit<32>> (%d,0) firsts;\nRegister<bit<REG_SIZE>, bit<32>> (%d, 0) caps;\n" % (elt_size, num, num, num, num, num, num))

total = sum(arr)
p4_template += ("Register<bit<%d>, bit<32>> (%d, 0) ring_buffers;\n"% (elt_size, total))
#print(p4_template)

#PYTHON CONTROL PLANE FILE
py_template = ""
prev = 0
for i,a in enumerate(arr):
    py_template += ("    test.write_register(\"lefts\", %d, %d)\n" % (i,prev))
    py_template += ("    test.write_register(\"caps\", %d, %d)\n" % (i, a))
    prev += a
py_template += "    test.stop_grpc()"
#print(py_template)

#WRITE TO FILES
f1 = None
try:
    f1 = open("registers.p4", "w")
except Exception as e:
    print("Failed to open registers.p4")

try:
    f1.write(p4_template)
except Exception as e:
    print("Failed to write to registers.p4")

f2 = None
try:
    f2 = open("setup_ports.py", "a")
except Exception as e:
    print("Failed to open setup_ports.py")

try:
    f2.write(py_template)
except Exception as e:
    print("Failed to write to setup_ports.py")

print("Successfully initialized buffer")
