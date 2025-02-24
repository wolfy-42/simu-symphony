//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_packet_chk.svh
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Packet checker class
//
//===================================================================

typedef eth_packet_c;
class eth_packet_chk_c ;

  //Use a mailbox to receive packets from monitor
  mailbox mbx_in;

  function new(mailbox mbx);
    this.mbx_in = mbx;
  endfunction

  task run;
    $display("packet_chk::run() called");
    get_and_process_pkt;
  endtask

  task get_and_process_pkt();
    eth_packet_c pkt;
    $display("packet_chk::process_pkt called");
    forever begin
      mbx_in.get(pkt);
      $display("time=%0t packet_chk::got packet from dut",$time);
      // input packet checker
      chk_packet(pkt);
    end
  endtask

  function void chk_packet(eth_packet_c pkt);
    pkt.extract_fields();
    $display("time=%0t packet_chk::Packet received: %s",$time, pkt.to_string());
    if (pkt.ipv4_pkt.eth_hdr.leng_type == IPV4_E) begin
      $display("time=%0t packet_chk::IPV4 packet received: %s",$time, pkt.ip_to_string());
    end
    else if (pkt.ipv4_pkt.eth_hdr.leng_type == ARP_E) begin
      $display("time=%0t packet_chk::ARP packet received: %s",$time, pkt.arp_to_string());
    end
  endfunction

endclass
