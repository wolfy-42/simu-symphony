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
//              Test-bench template for FPGA common BFM instantiation.
//              and stimulus. Includes clock, reset and AXI Lite Master
//              BFMs, and a simple place-holder DUT module.
// Updated       : date / author - comments
//--------------------------------------------------------------------

// Module declaration
module tb ();

    // Packages
    // NOTE - sim_management_pkg is included inside the test-case.
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;
    
    // Interfaces
    
    // AXI Lite interface, used by BFM and test-case to communicate.
    axi4lite_intf #(
        .AWIDTH(8), 
        .DWIDTH(16)
    ) 
    axi_bfm_channel ();
    
    // RIPL Library instantiations
    sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    lib_math                lib_math_inst ();           // Math libraries.
    

    // Test case instantiation
    test_case test_case_inst ();

    // Variables and parameters;    
    clk_bfm_if clk_if();
    reset_bfm_if reset_if();
    
    wire [7:0]  ov_FPGA_TEST;
    wire        o_LED;
   
    // Assigns

    // Example DUT
    top_simuverilog dut_inst(
    // Inputs                
        .i_CLK_200p          (clk_if.c),
        .i_CLK_200n          (~clk_if.c),                       
        .i_RESET_n           (reset_if.rn),
        
        // Outputs
        .ov_FPGA_TEST        (ov_FPGA_TEST[7:0]),
        .o_LED               (o_LED)                
    );

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

 
