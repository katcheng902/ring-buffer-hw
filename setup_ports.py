# Based on p4example l2.py and Vic's control.py
import sys

import pd_base_tests
from ptf.testutils import *
from ptf.thriftutils import *
import pal_rpc
import bfrt_grpc.client as gc

from pal_rpc.ttypes import *
from res_pd_rpc.ttypes import *
from ptf_port import *

import time

# Enable ports on the Tofino hardware switch 
class SlimAtpTest(pd_base_tests.ThriftInterface):
        def __init__(self):
            pd_base_tests.ThriftInterface.__init__(self, [""], ["pgrs"])
            pd_base_tests.ThriftInterface.setUp(self)

        def setup_grpc(self, p4program="ring_buffer"):
            grpc_addr = "localhost:50052"
            self.interface = gc.ClientInterface(grpc_addr, client_id=0, device_id=0)
            self.interface.bind_pipeline_config(p4program)

        def stop_grpc(self):
            self.interface.tear_down_stream()

        def enable_ports(self):
            # 176 is PORT 7/0  (TIMI: ConnectX5 100G ens2f1)
            dev_port_list = [176]
            for port in dev_port_list:
                self.pal.pal_port_add(0, port, pal_port_speed_t.BF_SPEED_100G, pal_fec_type_t.BF_FEC_TYP_NONE) 
                #self.pal.pal_port_add(0, port, pal_port_speed_t.BF_SPEED_100G, pal_fec_type_t.BF_FEC_TYP_NONE) 
                self.pal.pal_port_an_set(0, port, pal_autoneg_policy_t.BF_AN_FORCE_DISABLE)
                self.pal.pal_port_enable(0, port)
                                                                                                                                                                                
if __name__ == "__main__":
    config["log_dir"] = "log"
    # parse p4program name
    n = len(sys.argv)
    if(n > 1):
        p4program = str(sys.argv[1])
        test = SlimAtpTest()
        test.setup_grpc(p4program)
        
    # Enable ports connected (100G / NONE)
    test.enable_ports()                   
    test.stop_grpc()
