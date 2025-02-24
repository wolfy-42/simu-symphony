//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : AXIS Packet driver class.svh
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : AXIS Packet driver class
//
//===================================================================

typedef eth_packet_c;
class eth_packet_drv_c;

  // Virtual interface
  virtual interface eth_bfm_init_if bfm_intf;

  //Use a mailbox to receive packets from generator
  mailbox mbx_input;

  function new (mailbox mbx, virtual interface eth_bfm_init_if intf);
    mbx_input = mbx;
    this.bfm_intf = intf;
  endfunction

  // Implement a function that can drive the AXI streaming interface signals
  task run;
    eth_packet_c pkt;
    forever begin
      mbx_input.get(pkt);
      $display("time=%t eth_packet_drv::Got packet = %s", $time, pkt.to_string());
      drive_pkt(pkt);
    end
  endtask

  task drive_pkt(eth_packet_c pkt);
    // Drive signals using axi streaming protocol.
    // Note that tuser.sop is optional.
    int count;
    int numbytes;
    // Minumum inter packet gap.
    int ipg = 12;
    bit [7:0] cur_byte;
    count = 0;
    numbytes = pkt.pkt_size_bytes;
    $display("eth_packet_drv::drive_pkt: numbytes=%0d ",numbytes);
    forever @(posedge bfm_intf.clk) begin
      if(bfm_intf.mac_axis_rdy.tready) begin
        bfm_intf.dut_axis.std.tvalid <= 0;
        bfm_intf.dut_axis.tuser.sop <= 0;
        bfm_intf.dut_axis.std.tlast <= 0;
        bfm_intf.dut_axis.std.tkeep <= 1;
        cur_byte[7:0] = pkt.pkt_full[count];
        if(count==0) begin
          bfm_intf.dut_axis.std.tvalid <= 1;
          bfm_intf.dut_axis.tuser.sop <= 1;
          bfm_intf.dut_axis.std.tdata <= cur_byte;
          count = count+1;
        end
        else if (count == numbytes-1) begin
          bfm_intf.dut_axis.std.tvalid <= 1;
          bfm_intf.dut_axis.std.tlast <= 1;
          bfm_intf.dut_axis.std.tdata <= cur_byte;
          count = count+1;
        end
        else if (count == numbytes+ipg-1) begin
          count = 0;
          break;
        end
        else if (count >= numbytes) begin
          bfm_intf.dut_axis.std.tvalid <= 0;
          count = count+1;
        end
        else begin
          bfm_intf.dut_axis.std.tvalid <= 1;
          bfm_intf.dut_axis.std.tdata <= cur_byte;
          count= count+1;
        end
      end
      else
        bfm_intf.dut_axis.std.tvalid <= 0;
    end
  endtask

endclass
