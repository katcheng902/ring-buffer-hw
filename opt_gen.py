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

#GENERATE TXT FILE WITH NAMES OF RING BUFFERS AND CORRESPONDING INDICES??? idk how to do that one

#P4 FILE

template = ("#define ELT_SIZE %d\nRegister<bit<REG_SIZE>, bit<32>> (%d, 0) lefts;\nRegister<bit<REG_SIZE>, bit<32>> (%d, 0) heads; \nRegister<bit<REG_SIZE>, bit<32>> (%d,0) tails;\nRegister<bit<REG_SIZE>, bit<32>> (%d,0) sizes;\nRegister<bit<1>, bit<32>> (%d,0) firsts;\n" % (elt_size, num, num, num, num, num))

total = sum(arr)
template += ("Register<bit<%d>, bit<32>> (%d, 0) ring_buffers;\n"% (elt_size, total))


#PYTHON CONTROL PLANE FILE
