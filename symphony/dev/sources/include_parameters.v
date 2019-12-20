//*--------------------------------------------------------------------//
//
// Copyright (C) 2006 Fidus Systems Inc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : include parameters
// Updated       : date / author - comments
//--------------------------------------------------------------------//

`define FPGA_REV1 16'h0001

//register addresses in the global address space
`define FPGA_REV_ADD1             16'h0000
`define FPGA_REV_ADD2             16'h0001


// simulation speed-up
`ifdef SIM
 //the timer period
 `define CLK_TIMEOUT 32'h0000_00FF //for simulation, 1us period
`else // !`ifdef SIM
 //the timer period
 `define CLK_TIMEOUT 32'h1234_5678 //for synthesis, 10s period
`endif

   
//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:






  