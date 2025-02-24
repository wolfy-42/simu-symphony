//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_bfm.sv
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Ethernet BFM Top Level
//
//===================================================================

module eth_bfm

import eth_bfm_axi_pkg::*; 
import eth_base_pkg::*; 
import packet_bfm_env_pkg::*; 

#(parameter INST_NUM = 0
)
(

// Common clock and reset
input clk,
input rst,

// Responder axis ports. This represents the dut to MAC traffic flow.
input axis_rin_iout_t dut_axis,
output axis_rout_iin_t mac_axis_rdy,

output logic blah
);

// Instantiate bfm virtual interface.
eth_bfm_resp_if eth_bfm_if(.clk(clk),
                           .rst(rst),
                           .dut_axis(dut_axis),
                           .mac_axis_rdy(mac_axis_rdy)
                           );

// Instantiate top level env class
packet_bfm_env_c packet_bfm_env;

initial begin
  // Create and run BFM env object
  packet_bfm_env = new("sample_env", eth_bfm_if);
  $display("Created BFM Packet Env");
  packet_bfm_env.run();
end

endmodule
