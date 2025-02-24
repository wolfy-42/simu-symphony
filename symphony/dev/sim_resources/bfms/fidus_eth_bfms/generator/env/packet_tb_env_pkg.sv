//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : packet_tb_env_pkg.sv
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Package for Testbench generator env class
//
//===================================================================

package packet_tb_env_pkg;

import eth_base_pkg::*; 

//Include env components
`include "../../receiver/env/eth_packet.svh"
`include "eth_packet_gen.svh"
`include "eth_packet_drv.svh"

// Top level env class
class packet_tb_env_c;

  //A name for the env
  string env_name;

  // Packet generator object
  eth_packet_gen_c packet_gen;

  // Packet driver
  eth_packet_drv_c packet_driver;

  // Gen to driver connectivity mailbox.
  mailbox mbx_gen_drv;

  // Virtual interfaces
  virtual interface eth_bfm_init_if bfm_intf;

  // Options passed from testbench.
  int num_pkts;
  string packet_from_file;
  string packet_fnme;

  // Constructor
  function new(string name, virtual interface eth_bfm_init_if intf, int pkts, 
               string from_file, string fnme);
    this.env_name = name;
    this.bfm_intf = intf;
    this.num_pkts = pkts;
    this.packet_from_file = from_file;
    this.packet_fnme = fnme;
    // Create a mailbox instance used by driver and generator to communicate
    mbx_gen_drv = new();
    // Create a packet generator instance which can randomize packets or
    // read from a packet file.
    packet_gen = new(mbx_gen_drv, pkts, from_file, fnme);
    // Create an AXI streaming packet driver instance.
    packet_driver = new(mbx_gen_drv,intf);
  endfunction

  // Main evaluation method - run()
  task run();
    // Fork all component run();
    $display("packet_tb_env::run() called");
    fork 
      packet_gen.run();
      packet_driver.run();
    join
  endtask

endclass : packet_tb_env_c

endpackage: packet_tb_env_pkg
