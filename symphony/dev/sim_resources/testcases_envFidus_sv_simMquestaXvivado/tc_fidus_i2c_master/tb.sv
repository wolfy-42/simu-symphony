//-------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------
//--------------------------------------------------------------------
// Description   : template for FPGA top level Test Bench
//               Test-bench template for FPGA common BFM instantiation.
//               and stimulus. Includes clock, reset and AXI Lite Master
//               BFMs, and a simple place-holder DUT module.
// Updated       : date / author - comments
//--------------------------------------------------------------------
`timescale 1ns / 1ps

// Module declaration
module tb ();

    // Packages
    // NOTE - sim_management_pkg is included inside the test-case.
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;
    
    // Interfaces
    
    // RIPL Library instantiations
    sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    lib_math        lib_math_inst ();           // Math libraries.
	
    // Test case instantiation
    test_case test_case_inst ();

    // Variables and parameters;    
    clk_bfm_if clk_if();
	 clk_bfm_if clk_i2c_if();	 
    reset_bfm_if reset_if();

    // Assigns


    // BACKEND BFM
    //fidus_clock_gen_bfm clk_bfm;
    //fidus_reset_gen_bfm reset_bfm;

    // FRONTEND BFM

endmodule 

//  -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:

 
