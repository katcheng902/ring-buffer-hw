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
const bit<32> CAPACITY = 1 << 15;

/*REGISTERS*/
Register<bit<REG_SIZE>, bit<32>> (16,0) heads;
Register<bit<REG_SIZE>, bit<32>> (16,0) tails;
Register<bit<REG_SIZE>, bit<32>> (16,0) sizes;
Register<bit<1>, bit<32>> (16,0) firsts;

Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb1;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb2;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb3;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb4;

Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb5;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb6;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb7;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb8;

Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb9;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb10;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb11;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb12;


Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb13;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb14;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb15;
Register<bit<ELT_SIZE>, bit<32>> (CAPACITY, 0) rb16;

control Enqueue(in bit<4> rb_id, in bit<ELT_SIZE> enq_value) {
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
     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb1) write_buffer_reg_action_1 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb2) write_buffer_reg_action_2 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb3) write_buffer_reg_action_3 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb4) write_buffer_reg_action_4 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb5) write_buffer_reg_action_5 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb6) write_buffer_reg_action_6 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb7) write_buffer_reg_action_7 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };


    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb8) write_buffer_reg_action_8 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb9) write_buffer_reg_action_9 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb10) write_buffer_reg_action_10 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb11) write_buffer_reg_action_11 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb12) write_buffer_reg_action_12 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb13) write_buffer_reg_action_13 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb14) write_buffer_reg_action_14 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };

     RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb15) write_buffer_reg_action_15 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };


    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb16) write_buffer_reg_action_16 = {
	void apply(inout bit<ELT_SIZE> val) {
	    val = enq_value;
	}
     };


     action enqueue_action_1() {
	write_buffer_reg_action_1.execute(tail_tmp);
     }

     action enqueue_action_2() {
	write_buffer_reg_action_2.execute(tail_tmp);
     }

     action enqueue_action_3() {
	write_buffer_reg_action_3.execute(tail_tmp);
     }

     action enqueue_action_4() {
	write_buffer_reg_action_4.execute(tail_tmp);
     }

     action enqueue_action_5() {
	write_buffer_reg_action_5.execute(tail_tmp);
     }

     action enqueue_action_6() {
	write_buffer_reg_action_6.execute(tail_tmp);
     }

     action enqueue_action_7() {
	write_buffer_reg_action_7.execute(tail_tmp);
     }

     action enqueue_action_8() {
	write_buffer_reg_action_8.execute(tail_tmp);
     }

     action enqueue_action_9() {
	write_buffer_reg_action_9.execute(tail_tmp);
     }

     action enqueue_action_10() {
	write_buffer_reg_action_10.execute(tail_tmp);
     }

     action enqueue_action_11() {
	write_buffer_reg_action_11.execute(tail_tmp);
     }

     action enqueue_action_12() {
	write_buffer_reg_action_12.execute(tail_tmp);
     }

     action enqueue_action_13() {
	write_buffer_reg_action_13.execute(tail_tmp);
     }

     action enqueue_action_14() {
	write_buffer_reg_action_14.execute(tail_tmp);
     }

     action enqueue_action_15() {
	write_buffer_reg_action_15.execute(tail_tmp);
     }

     action enqueue_action_16() {
	write_buffer_reg_action_16.execute(tail_tmp);
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

   table enqueue_table_1 {
	actions = {
	    enqueue_action_1;
	}
	default_action = enqueue_action_1;
   }

   table enqueue_table_2 {
	actions = {
	    enqueue_action_2;
	}
	default_action = enqueue_action_2;
   }

   table enqueue_table_3 {
	actions = {
	    enqueue_action_3;
	}
	default_action = enqueue_action_3;
   }

   table enqueue_table_4 {
	actions = {
	    enqueue_action_4;
	}
	default_action = enqueue_action_4;
   }

   table enqueue_table_5 {
	actions = {
	    enqueue_action_5;
	}
	default_action = enqueue_action_5;
    }
    
    table enqueue_table_6 {
	actions = {
	    enqueue_action_6;
	}
	default_action = enqueue_action_6;
    }

    table enqueue_table_7 {
	actions = {
	    enqueue_action_7;
	}
	default_action = enqueue_action_7;
    }
    
    table enqueue_table_8 {
	actions = {
	    enqueue_action_8;
	} 
	default_action = enqueue_action_8;
    }

    table enqueue_table_9 {
	actions = {
	    enqueue_action_9;
	}
	default_action = enqueue_action_9;
   }

   table enqueue_table_10 {
	actions = {
	    enqueue_action_10;
	}
	default_action = enqueue_action_10;
   }

   table enqueue_table_11 {
	actions = {
	    enqueue_action_11;
	}
	default_action = enqueue_action_11;
   }

   table enqueue_table_12 {
	actions = {
	    enqueue_action_12;
	}
	default_action = enqueue_action_12;
   }

   table enqueue_table_13 {
	actions = {
	    enqueue_action_13;
	}
	default_action = enqueue_action_13;
    }
    
    table enqueue_table_14 {
	actions = {
	    enqueue_action_14;
	}
	default_action = enqueue_action_14;
    }

    table enqueue_table_15 {
	actions = {
	    enqueue_action_15;
	}
	default_action = enqueue_action_15;
    }
    
    table enqueue_table_16 {
	actions = {
	    enqueue_action_16;
	}
	default_action = enqueue_action_16;
    }

   apply {
	first_table.apply();
	inc_tail_table.apply();
	inc_size_table.apply();
	if (rb_id == 0) {
	    enqueue_table_1.apply();
	} else if (rb_id == 1) {
	    enqueue_table_2.apply();
	} else if (rb_id == 2) {
	    enqueue_table_3.apply();
	} else if (rb_id == 3) {
	    enqueue_table_4.apply();
	} else if (rb_id == 4) {
	    enqueue_table_5.apply();
	} else if (rb_id == 5) {
	    enqueue_table_6.apply();
	} else if (rb_id == 6) {
	    enqueue_table_7.apply();
	} else if (rb_id == 7) {
	    enqueue_table_8.apply();
	} else if (rb_id == 8) {
	    enqueue_table_9.apply();
	} else if (rb_id == 9) {
	    enqueue_table_10.apply();
	} else if (rb_id == 10) {
	    enqueue_table_11.apply();
	} else if (rb_id == 11) {
	    enqueue_table_12.apply();
	} else if (rb_id == 12) {
	    enqueue_table_13.apply();
	} else if (rb_id == 13) {
	    enqueue_table_14.apply();
        } else if (rb_id == 14) {
	    enqueue_table_15.apply();
	} else {
	    enqueue_table_16.apply();
	}
   }

}

control Dequeue(in bit<4> rb_id, out bit<ELT_SIZE> deq_value) {
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
    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb1) read_buffer_reg_action_1 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb2) read_buffer_reg_action_2 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb3) read_buffer_reg_action_3 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb4) read_buffer_reg_action_4 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb5) read_buffer_reg_action_5 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb6) read_buffer_reg_action_6 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb7) read_buffer_reg_action_7 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb8) read_buffer_reg_action_8 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb9) read_buffer_reg_action_9 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb10) read_buffer_reg_action_10 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb11) read_buffer_reg_action_11 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb12) read_buffer_reg_action_12 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb13) read_buffer_reg_action_13 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb14) read_buffer_reg_action_14 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb15) read_buffer_reg_action_15 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    RegisterAction<bit<ELT_SIZE>, bit<32>, bit<ELT_SIZE>> (rb16) read_buffer_reg_action_16 = {
	void apply(inout bit<ELT_SIZE> val, out bit<ELT_SIZE> rv) {
	    rv = val;
	}
    };

    action dequeue_action_1() {
 	deq_value = read_buffer_reg_action_1.execute(head_tmp);
    }

    action dequeue_action_2() {
	deq_value = read_buffer_reg_action_2.execute(head_tmp);
    }

    action dequeue_action_3() {
	deq_value = read_buffer_reg_action_3.execute(head_tmp);
    }

    action dequeue_action_4() {
	deq_value = read_buffer_reg_action_4.execute(head_tmp);
    }

    action dequeue_action_5() {
 	deq_value = read_buffer_reg_action_5.execute(head_tmp);
    }

    action dequeue_action_6() {
 	deq_value = read_buffer_reg_action_6.execute(head_tmp);
    }

    action dequeue_action_7() {
 	deq_value = read_buffer_reg_action_7.execute(head_tmp);
    }

    action dequeue_action_8() {
 	deq_value = read_buffer_reg_action_8.execute(head_tmp);
    }

    action dequeue_action_9() {
 	deq_value = read_buffer_reg_action_9.execute(head_tmp);
    }

    action dequeue_action_10() {
	deq_value = read_buffer_reg_action_10.execute(head_tmp);
    }

    action dequeue_action_11() {
	deq_value = read_buffer_reg_action_11.execute(head_tmp);
    }

    action dequeue_action_12() {
	deq_value = read_buffer_reg_action_12.execute(head_tmp);
    }

    action dequeue_action_13() {
 	deq_value = read_buffer_reg_action_13.execute(head_tmp);
    }

    action dequeue_action_14() {
 	deq_value = read_buffer_reg_action_14.execute(head_tmp);
    }

    action dequeue_action_15() {
 	deq_value = read_buffer_reg_action_15.execute(head_tmp);
    }

    action dequeue_action_16() {
 	deq_value = read_buffer_reg_action_16.execute(head_tmp);
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

    table dequeue_table_1 {
	actions = {
	    dequeue_action_1;
	}
	default_action = dequeue_action_1;
    }

    table dequeue_table_2 {
	actions = {
	    dequeue_action_2;
	}
	default_action = dequeue_action_2;
    }

    table dequeue_table_3 {
	actions = {
	    dequeue_action_3;
	}
	default_action = dequeue_action_3;
    }

    table dequeue_table_4 {
	actions = {
	    dequeue_action_4;
	}
	default_action = dequeue_action_4;
    }

    table dequeue_table_5 {
	actions = {
	    dequeue_action_5;
	}
	default_action = dequeue_action_5;
    }

    table dequeue_table_6 {
	actions = {
	    dequeue_action_6;
	}
	default_action = dequeue_action_6;
    }

    table dequeue_table_7 {
	actions = {
	    dequeue_action_7;
	}
	default_action = dequeue_action_7;
    }

    table dequeue_table_8 {
	actions = {
	    dequeue_action_8;
	}
	default_action = dequeue_action_8;
    }

    table dequeue_table_9 {
	actions = {
	    dequeue_action_9;
	}
	default_action = dequeue_action_9;
    }

    table dequeue_table_10 {
	actions = {
	    dequeue_action_10;
	}
	default_action = dequeue_action_10;
    }

    table dequeue_table_11 {
	actions = {
	    dequeue_action_11;
	}
	default_action = dequeue_action_11;
    }

    table dequeue_table_12 {
	actions = {
	    dequeue_action_12;
	}
	default_action = dequeue_action_12;
    }

    table dequeue_table_13 {
	actions = {
	    dequeue_action_13;
	}
	default_action = dequeue_action_13;
    }

    table dequeue_table_14 {
	actions = {
	    dequeue_action_14;
	}
	default_action = dequeue_action_14;
    }

    table dequeue_table_15 {
	actions = {
	    dequeue_action_15;
	}
	default_action = dequeue_action_15;
    }

    table dequeue_table_16 {
	actions = {
	    dequeue_action_16;
	}
	default_action = dequeue_action_16;
    }

    apply {
	dec_size_table.apply();
	if (size_tmp > 0) {
	    inc_head_table.apply();
	    if (rb_id == 0) {
		dequeue_table_1.apply();
	    } else if (rb_id == 1) {
		dequeue_table_2.apply();
	    } else if (rb_id == 2) {
		dequeue_table_3.apply();
	    } else if (rb_id == 3) {
		dequeue_table_4.apply();
	    } else if (rb_id == 4) {
		dequeue_table_5.apply();
	    } else if (rb_id == 5) {
		dequeue_table_6.apply();
	    } else if (rb_id == 6) {
		dequeue_table_7.apply();
	    } else if (rb_id == 7) {
		dequeue_table_8.apply();
	    } else if (rb_id == 8) {
		dequeue_table_9.apply();
	    } else if (rb_id == 9) {
		dequeue_table_10.apply();
	    } else if (rb_id == 10) {
		dequeue_table_11.apply();
	    } else if (rb_id == 11) {
		dequeue_table_12.apply();
	    } else if (rb_id == 12) {
		dequeue_table_13.apply();
	    } else if (rb_id == 13) {
		dequeue_table_14.apply();
	    } else if (rb_id == 14) {
		dequeue_table_15.apply();
	    } else {
		dequeue_table_16.apply();
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
	bit<2> id = 0;
	if (hdr.ipv4.dst_addr[0:0] == 0) {
		Dequeue.apply(hdr.ipv4.dst_addr[3:0], deq);
	} else {
	 	Enqueue.apply(hdr.ipv4.dst_addr[3:0], hdr.ipv4.dst_addr);
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
