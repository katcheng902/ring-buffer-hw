#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "include/headers.p4"
#include "include/util.p4"

struct metadata_t {}
#define REG_SIZE 32
#define ELT_SIZE 32
Register<bit<REG_SIZE>, bit<32>> (3, 0) lefts;
Register<bit<REG_SIZE>, bit<32>> (3, 0) heads; 
Register<bit<REG_SIZE>, bit<32>> (3,0) tails;
Register<bit<REG_SIZE>, bit<32>> (3,0) sizes;
Register<bit<1>, bit<32>> (3,0) firsts;
Register<bit<REG_SIZE>, bit<32>> (3, 0) caps;
Register<bit<32>, bit<32>> (6, 0) ring_buffers;
