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
	transition parse_ipv4;
    }

    state parse_ipv4 {
	pkt.extract(hdr.ipv4);
	transition select(hdr.ipv4.dst_addr) {
	    16909060: accept;
	    default: reject;
	}
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
        // pkt.emit(hdr);
        pkt.emit(hdr.ethernet);
    }
}

#define REG_SIZE 32
#define ELT_SIZE 32
const bit<32> CAPACITY = 1 << 4;

/*REGISTERS*/
Register<bit<REG_SIZE>, bit<32>> (2, 0) heads;
Register<bit<REG_SIZE>, bit<32>> (2,0) tails;
Register<bit<REG_SIZE>, bit<32>> (2,0) sizes;
Register<bit<1>, bit<32>> (2,0) firsts;

Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb1;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb2;


control Enqueue(in bit<1> rb_id, in bit<ELT_SIZE> enq_value) {
     bit<1> first_tmp = 0;
     bit<REG_SIZE> tail_tmp = 0;

     /*first*/
     RegisterAction<bit<1>, bit<32>, bit<1>> (firsts) set_first_reg_action = {
	void apply(inout bit<1> val, out bit<1> rv) {
	     rv = val;
	     val = 1;
	}
     };

     action first_action() {
	first_tmp = set_first_reg_action.execute((bit<32>) rb_id);
     }

     /*tail*/
     RegisterAction<bit<REG_SIZE>, bit<32>, bit<REG_SIZE>> (tails) inc_tail_reg_action = {
	void apply(inout bit<REG_SIZE> val, out bit<REG_SIZE> rv) {
	    if ((first_tmp == 0) || (val >= CAPACITY-1)) {
		val = 0;
	    } else {
		val = val+1;
	    }	    
	    rv = val;
	}
     };

     action inc_tail() {
	tail_tmp = inc_tail_reg_action.execute((bit<32>) rb_id);
     }

     /*size*/
     RegisterAction<bit<REG_SIZE>, bit<32>, bit<REG_SIZE>> (sizes) inc_size_reg_action = {
	void apply(inout bit<REG_SIZE> val) {
	    if (val < CAPACITY) {
		val = val+1;
	    }
	}
     };

     action inc_size() {
	inc_size_reg_action.execute((bit<32>) rb_id);
     }

     /*buffer (write)*/
     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb1) write_buffer_reg_action_one = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb2) write_buffer_reg_action_two = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     action enqueue_action_1() {
	write_buffer_reg_action_one.execute(tail_tmp);
     }

     action enqueue_action_2() {
	write_buffer_reg_action_two.execute(tail_tmp);
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

   table enqueue_table_one {
	actions = {
	    enqueue_action_1;
	}
	default_action = enqueue_action_1;
   }

   table enqueue_table_two {
	actions = {
	    enqueue_action_2;
	}
	default_action = enqueue_action_2;
   }

   apply {
	first_table.apply();
	inc_tail_table.apply();
	inc_size_table.apply();
	if (rb_id == 0) {
	    enqueue_table_one.apply();
	} else {
	    enqueue_table_two.apply();
	}
   }

}

control Dequeue(in bit<1> rb_id, out bit<ELT_SIZE> deq_value) {
    bit<REG_SIZE> size_tmp = 0;
    bit<REG_SIZE> head_tmp = 0;

    /* size (decrement) */
    RegisterAction<bit<REG_SIZE>, bit<32>, bit<REG_SIZE>> (sizes) dec_size_reg_action = {
	void apply(inout bit<REG_SIZE> val, out bit<REG_SIZE> rv) {
	    rv=val;
	    if (val > 0) {
		val = val - 1;
	    }
	}
    };

    action dec_size() {
	size_tmp = dec_size_reg_action.execute((bit<32>) rb_id);
    }

    /* head (increment) */
    RegisterAction<bit<REG_SIZE>, bit<32>, bit<REG_SIZE>> (heads) inc_head_reg_action = {
	void apply(inout bit<REG_SIZE> val, out bit<REG_SIZE> rv) {
	    rv = val;
            val = val + 1;
	}
    };

    action inc_head() {
	head_tmp = inc_head_reg_action.execute((bit<32>) rb_id);
    }

    /* buffer (read) */
    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb1) read_buffer_reg_action_one = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb2) read_buffer_reg_action_two = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    action dequeue_action_1() {
 	deq_value = read_buffer_reg_action_one.execute(head_tmp);
    }

    action dequeue_action_2() {
	deq_value = read_buffer_reg_action_two.execute(head_tmp);
    }

    /* TABLES */
    table dec_size_table {
	actions = {
	    dec_size;
	}
	default_action = dec_size;
    }

    table inc_head_table {
	actions = {
	    inc_head;
	}
	default_action = inc_head;
    }

    table dequeue_table_one {
	actions = {
	    dequeue_action_1;
	}
	default_action = dequeue_action_1;
    }

    table dequeue_table_two {
	actions = {
	    dequeue_action_2;
	}
	default_action = dequeue_action_2;
    }

    apply {
	dec_size_table.apply();
	if (size_tmp > 0) {
	    inc_head_table.apply();
	    if (rb_id == 0) {
	        dequeue_table_one.apply();
	    } else {
		dequeue_table_two.apply();
	    }
	}
    }

}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action drop() {
	ig_dprsr_md.drop_ctl = 0x1;
    }

    /* define the dmac table, serving as the forwarding table */
    table dmac {
        /* match the ethernet destination address */
        key = {
            hdr.ethernet.src_addr: exact;
        }

        /* define the list of actions */
        actions = {
	    drop;
	    NoAction;
        }
        size = 256;
        default_action = NoAction;

	const entries = {
	   (0x000033445566) : drop; 
	   (0x000011223344) : NoAction;
	}
    }

    apply {
	bit<ELT_SIZE> deq = 0;
	switch (dmac.apply().action_run) {
	    drop: {Enqueue.apply(1, hdr.ipv4.dst_addr);}
	    NoAction: {Dequeue.apply(1, deq);}
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