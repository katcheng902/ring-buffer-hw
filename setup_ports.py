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
        self.bfrt_info = self.interface.bfrt_info_get(p4program)

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

    def write_register(self, reg_name, reg_idx, reg_val):
        target = gc.Target(device_id=0, pipe_id=0xffff)
        table = self.bfrt_info.table_get(reg_name)
        table.entry_add(
                        target,
                        [table.make_key([gc.KeyTuple('$REGISTER_INDEX', reg_idx)])],
                        [table.make_data(
                        [gc.DataTuple("{}.f1".format(reg_name), reg_val)])])


    def read_register(self, reg_name, reg_idx):
        target = gc.Target(device_id=0, pipe_id=0xffff)
        table = self.bfrt_info.table_get(reg_name)
        resp = table.entry_get(
                        target,
                        [table.make_key([gc.KeyTuple('$REGISTER_INDEX', reg_idx)])],
                      {"from_hw": True})
        data, _ = next(resp)
        data = data.to_dict()
        return data["{}.f1".format(reg_name)]
    def enb_digest(self):

        # Get bfrt_info and set it as part of the test
        # The learn object can be retrieved using a lesser qualified name on the condition
        # that it is unique
        learn_filter = self.bfrt_info.learn_get("digest_a") #digest name
        learn_filter.info.data_field_annotation_add("src_addr", "mac")
        learn_filter.info.data_field_annotation_add("dst_addr", "mac")

        print("Waiting for digest")
        digest = self.interface.digest_get()

'''
    def test_read(self, T, ind): #T is cycle time, ind is ring buffer we want to read
        #res = []
        while True:
            sz = self.read_register("sizes", ind)[1]

            start_time = time.time()

            for i in range(sz):
                self.read_register("ring_buffers", 0)

            end_time = time.time()
            return ((end_time-start_time)*1000)
            #res.append((end_time-start_time)*1000)
            #print(res)
            #if len(res) >= 20:
               # break

            #time.sleep(T)
        #return sum(res)/20
'''

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
    test.enb_digest()
    test.stop_grpc()
