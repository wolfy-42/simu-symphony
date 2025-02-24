//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Anna Raikin
// Created       : 2018-06-26
//---------------------------------------------------------------------------//
//---------------------------------------------------------------------------//
// Description   : SystemVerilog Interface for I2C Master
// Updated       : date / author - comment
//---------------------------------------------------------------------------//

interface fidus_i2c_master_if 
(
     input logic         clk,
     input logic         reset
);
   logic              	scl_in;		// SCL input
   logic              	scl_out;		// SCL output
   logic 					scl_t;		// SCL tri-state enable
   logic               	sda_in;		// SDA input
   logic               	sda_out;		// SDA output
   logic 					sda_t;		// SDA tri-state enable

endinterface: fidus_i2c_master_if

