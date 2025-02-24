//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_bfm_if.sv
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Interface file for ethernet BFM
//
//===================================================================

import eth_bfm_axi_pkg::*; 

interface eth_bfm_init_if (
  input clk,
  input rst,

  // Initiator axis ports. This represents the dut to MAC traffic flow.
  output axis_rin_iout_t dut_axis,
  input axis_rout_iin_t mac_axis_rdy

);

endinterface

interface eth_bfm_resp_if (
  input clk,
  input rst,

  // Responder axis ports. This represents the dut to MAC traffic flow.
  input axis_rin_iout_t dut_axis,
  output axis_rout_iin_t mac_axis_rdy

);

endinterface
