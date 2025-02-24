//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : tc_fidus_eth_pkts.sv
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Ethernet BFM testbench
//
//===================================================================

`timescale 1 ns / 1 ps

module test_case();

// System Verilog Simulation management package
import sim_management_pkg::*;
import eth_bfm_axi_pkg::*; 
import packet_tb_env_pkg::*; 

sim_management s;
parameter  TC_NAME = "tc_fidus_eth_pkts";
int        seed;
string     msg = "";
int        rc;

parameter src_clk_period = 3.33; // 300 MHz

///////////////////////
// Generate Clocks
///////////////////////

logic src_clk;
initial src_clk = 1;

always begin
  #(src_clk_period / 2) src_clk = ~src_clk;
end

logic reset;

////////////////////////////////////////////
// Ethernet Receiver BFM Instantiation
////////////////////////////////////////////
logic core_clk;
logic core_rst;

// Responder axis ports. This represents the dut to MAC traffic flow.
axis_rin_iout_t dut_axis;
axis_rout_iin_t mac_axis_rdy;

assign core_clk = src_clk;
assign core_rst = reset;

// Packet receiver BFM.
eth_bfm eth_bfm(.clk(core_clk),
                .rst(core_rst),
                .dut_axis(dut_axis),
                .mac_axis_rdy(mac_axis_rdy),
                .blah()
                );

eth_bfm_init_if eth_bfm_if(.clk(src_clk),
                           .rst(reset),
                           .dut_axis(dut_axis),
                           .mac_axis_rdy(mac_axis_rdy)
                           );

// Instantiate top level env class
packet_tb_env_c packet_tb_env;

/*************************************
////////////////////////////////
// Generate a data file
////////////////////////////////
integer fdcd;  

logic [7:0] ip_octet;

initial begin  
  fdcd = $fopen("tmp_packet.txt", "w");  

  ip_octet = 1;

  for (int i=0; i<512; i++) begin

    $fdisplay(fdcd, "%0h", ip_octet);  

    ++ip_octet;
  end

//  $fclose(fdcd);  
end
*************************************/

////////////////
// Testbench
////////////////

// Done by simu??
// initial begin
//   $wlfdumpvars;
// end

// Number of generated packets. This value is passed to the generator class.
int num_pkts = 10;

// Packet from file option. These values are passed to the generator class.
string packet_from_file;
// assign packet_from_file = "true";
assign packet_from_file = "false";
string packet_fnme;
// Relative to run directory.
assign packet_fnme = "../testcases_envFidus_sv_simMquestaXvivado/tc_fidus_eth_bfm/ip_packet.txt";

initial begin
  $timeformat(-9,3,"ns",20);

  s.initSim(TC_NAME);
  s.printMessage (TC_NAME,msg);

  s.printMessage (TC_NAME, "////////////////////////////////");
  s.printMessage (TC_NAME, "Start Testing.");
  s.printMessage (TC_NAME, "////////////////////////////////");

  seed = tb.seed;
  rc = $urandom(seed);

  reset = 1;

  repeat(45) @(posedge src_clk);
  reset = 0;

  // Create packet generator BFM
  packet_tb_env = new("eth_bfm_env", eth_bfm_if, num_pkts, packet_from_file, packet_fnme);
  s.printMessage (TC_NAME, "Created Packet TB Env");

  repeat(45) @(posedge src_clk);

  fork
    begin
      packet_tb_env.run();
    end
    begin
      #20000ns;
    end
  join_any

  s.printMessage (TC_NAME, "////////////////////////////////");
  s.printMessage (TC_NAME, "Done Testing.");
  s.printMessage (TC_NAME, "////////////////////////////////");

  s.printPass  (TC_NAME, "All packets sent and received.");
//  s.printError (TC_NAME, "Blahblah");

  #1000;

  s.testComplete;
end

endmodule
