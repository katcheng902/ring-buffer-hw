/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


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

struct pair {
    bit<32>     first;
    bit<32>     second;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}

#define REG_SIZE 32
#define ELT_SIZE 16
const bit<32> CAPACITY = 1 << 4;

/*REGISTERS*/
Register<bit<REG_SIZE>, bit<32>> (1,0) head;
Register<bit<REG_SIZE>, bit<32>> (1,0) tail;
Register<bit<REG_SIZE>, bit<32>> (1,0) buffer_size;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) ring_buffer;
Register<bit<1>, bit<32>> (1,0) first;

control Enqueue(in bit<ELT_SIZE> enq_value) {
     bit<1> first_tmp = 0;
     bit<REG_SIZE> tail_tmp = 0;

     /*first*/
     RegisterAction<bit<1>, bit<32>, bit<1>> (first) set_first_reg_action = {
	void apply(inout bit<1> val, out bit<1> rv) {
	     rv = val;
	     val = 1;
	}
     };

     action first_action() {
	set_first_reg_action.execute(0);
     }

     /*tail*/
     RegisterAction<bit<REG_SIZE>, bit<32>, bit<REG_SIZE>> (tail) inc_tail_reg_action = {
	void apply(inout bit<REG_SIZE> val, out bit<REG_SIZE> rv) {
	    if ((first_tmp == 0) || (val >= CAPACITY-1)) { /*first time around or reaching cap and need to loop around*/
		val = 0;
	    } else {
		val = val+1;
	    }	    
	    rv = val;
	}
     };

     action inc_tail() {
	inc_tail_reg_action.execute(0, tail_tmp);
     }

     /*size*/
     RegisterAction<bit<REG_SIZE>, bit<32>, bit<REG_SIZE>> (buffer_size) inc_size_reg_action = {
	void apply(inout bit<REG_SIZE> val) {
	    if (val < CAPACITY) {
		val = val+1;
	    }
	}
     };

     action inc_size() {
	inc_size_reg_action.execute(0);
     }

     /*buffer (write)*/
     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (ring_buffer) write_buffer_reg_action = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     action enqueue_action() {
	write_buffer_reg_action.execute(0);
     }


    /*TABLES*/ 
    table first_table {
	actions = {
	    first_action;
	}
	default_action = first_action;
    }

    table inc_tail_table {
	actions = {
	    inc_tail;
	}
	default_action = inc_tail;
    }

   table inc_size_table {
	actions = {
	    inc_size;
	}
	default_action = inc_size;
   }

   table enqueue_table {
	actions = {
	    enqueue_action;
	}
	default_action = enqueue_action;
   }

   apply {
	first_table.apply();
	inc_tail_table.apply();
	inc_size_table.apply();
	enqueue_table.apply();
   }

}
/*
control Dequeue(out bit<ELT_SIZE> deq_value) {

}*/

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    /* define the dmac table, serving as the forwarding table */
    table dmac {
        /* match the ethernet destination address */
        key = {
            hdr.ethernet.dst_addr: exact;
        }

        /* define the list of actions */
        actions = {
            NoAction;
        }
        size = 256;
        default_action = NoAction;
    }


    apply {
	switch (dmac.apply().action_run) {
            NoAction: {Enqueue.apply((bit<16>) 0);}
        }

    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) pipe;

Switch(pipe) main;
