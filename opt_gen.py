'''
This file generates the registers & their initialization.
Inputs: element size 8, 16, or 32 and [array of ring buffer capacities]; e.g., 32 2,3,4 will generate 3 ring buffers of capacities 2,3,4 all with element size 32
'''

import sys
import math

try:
    elt_size = int(sys.argv[1])
    num = int(sys.argv[2])
    buf_cap = int(sys.argv[3])

except Exception as e:
    print("Failed to parse arguments")
    exit(1)

lognum = math.log2(num)+1

#P4 FILE
p4_template = "#include <core.p4>\n#if __TARGET_TOFINO__ == 3\n#include <t3na.p4>\n#elif __TARGET_TOFINO__ == 2\n#include <t2na.p4>\n#else\n#include <tna.p4>\n#endif\n\n#include \"include/headers.p4\"\n#include \"include/util.p4\"\n\nstruct metadata_t {}"
p4_template += ("\n\nconst bit<32> CAPACITY = %d;\nconst bit<32> TOTAL = CAPACITY*%d;\n#define ID_LEN %d\n#define REG_SIZE 32\n#define ELT_SIZE %d\nRegister<bit<REG_SIZE>, bit<32>> (%d, 0) lefts;\nRegister<bit<REG_SIZE>, bit<32>> (%d, 0) heads; \nRegister<bit<REG_SIZE>, bit<32>> (%d,0) tails;\nRegister<bit<REG_SIZE>, bit<32>> (%d,0) sizes;\nRegister<bit<1>, bit<32>> (%d,0) firsts;\n" % (buf_cap, num, lognum, elt_size, num, num, num, num, num))

p4_template += ("Register<bit<%d>, bit<32>> (TOTAL, 0) ring_buffers;\n" % (elt_size,))
#print(p4_template)

#PYTHON CONTROL PLANE FILE
py_template = ""
prev = 0
for i in range(num):
    py_template += ("    test.write_register(\"lefts\", %d, %d)\n" % (i,i*buf_cap))
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
