//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_packet_mon.svh
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : AXIS Monitor class
//
//===================================================================

typedef eth_packet_c;
class eth_packet_mon_c;

  //Virtual interface to sample signals
  virtual interface eth_bfm_resp_if bfm_intf;
 
  // Use a mailbox to pass packets to checker
  mailbox mbx_out;
 
  // Dummy variables for pkt new.
  string from_file;
  byte data[$];

  //constructor
  function new(mailbox mbx, virtual interface eth_bfm_resp_if intf);
    this.mbx_out = mbx;
    this.bfm_intf = intf;
  endfunction
 
  // Sample axis port and send the packet to the checker mailbox
  task run;
    $display("packet_mon::run() called");
    fork
      sample_input_pkt();
    join
  endtask
 
  task sample_input_pkt();
    eth_packet_c pkt;
    int count;
    bit [7:0] cur_byte;
    count = 0;
    $display("packet_mon::sample_input_pkt() called");
    forever @(posedge bfm_intf.clk) begin
      bfm_intf.mac_axis_rdy.tready <= 1;  // Randomize??
 
      if(bfm_intf.dut_axis.std.tvalid && (count == 0)) begin
        $display("time=%0t packet_mon::Seeing SOP on input",$time);
        pkt = new(from_file, data);
        count = 1;
        pkt.pkt_data.push_back(bfm_intf.dut_axis.std.tdata);
      end else if (bfm_intf.dut_axis.std.tlast) begin
        pkt.pkt_data.push_back(bfm_intf.dut_axis.std.tdata);
        pkt.pkt_size_bytes = count+1;
        $display("time=%0t packet_mon: Received full packet on input: pkt=%s",$time, pkt.to_string());
        mbx_out.put(pkt);
        count = 0;
      end else if(count > 0) begin
        pkt.pkt_data.push_back(bfm_intf.dut_axis.std.tdata);
        count++;
      end
    end
  endtask

endclass
