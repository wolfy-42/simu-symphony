//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : packet_bfm_env_pkg.sv
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Package for the Ethernet BFM env class
//
//===================================================================

package packet_bfm_env_pkg;

import eth_base_pkg::*; 

// Include env components
`include "eth_packet.svh"
`include "eth_packet_mon.svh"
`include "eth_packet_chk.svh"

// Top level bfm env class
class packet_bfm_env_c;

  //A name for the env
  string env_name;

  // Packet Monitor
  eth_packet_mon_c packet_mon;

  // Packet checker object
  eth_packet_chk_c packet_checker;
  
  // Monitor to checker connectivity mailbox.
  mailbox mbx_mon_chk;

  // Virtual interfaces
  virtual interface eth_bfm_resp_if bfm_intf;

  // Constructor
  function new(string name, virtual interface eth_bfm_resp_if intf);
    this.env_name = name;
    this.bfm_intf = intf;
    // Create a mailbox instance used by monitor and checker to communicate
    mbx_mon_chk = new();
    // Create an AXI streaming packet monitor instance.
    packet_mon = new(mbx_mon_chk,intf);
    // Create a packet checker instance.
    packet_checker = new(mbx_mon_chk);
  endfunction

  // Main evaluation method - run()
  task run();
    //Fork all component run();
    $display("packet_tb_env::run() called");
    fork 
      packet_mon.run();
      packet_checker.run();
    join
  endtask

endclass : packet_bfm_env_c

endpackage: packet_bfm_env_pkg
