//-------------------------------------------------------------------//
//
// Copyright (C) 2006 Fidus Systems Inc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------
//--------------------------------------------------------------------
// Description   : template for FPGA top level Test Bench
//
// Updated       : 2015-08-12 / Arnold Balisch - fixes
// Updated       : 2018-03-15 / Victor Dumitriu
//               Test-bench template for FPGA common BFM instantiation.
//               and stimulus. Includes clock, reset and AXI Lite Master
//               BFMs, and a simple place-holder DUT module.
// Updated       : date / author - comments
//--------------------------------------------------------------------


// Module declaration
module tb ();

    // Packages
    // NOTE - sim_management_pkg is included inside the test-case.
    
    // RIPL Library instantiations
    sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    

    // Test case instantiation
    test_case test_case_inst ();

    // Variables and parameters;    
    wire  CLK200;
    wire  RESET_n;
    
    wire [7:0]  ov_FPGA_TEST;
    wire        o_LED;
   
    // Assigns

    // Example DUT
    top_simuverilog dut_inst(
    // Inputs                
        .i_CLK_200p          (CLK200),
        .i_CLK_200n          (~CLK200),                       
        .i_RESET_n           (RESET_n),
        
        // Outputs
        .ov_FPGA_TEST        (ov_FPGA_TEST[7:0]),
        .o_LED               (o_LED)                
    );

    // BACKEND BFM

    // FRONTEND BFM

    // Clock generator instantiation  
    fidus_clock_gen_bfm #(
        .BFM_NAME   ("bfm_clk200Mhz_inst "),
        .CLK_NAME   ("CLK200 ")
    ) 
    bfm_clk200Mhz_inst (
        .o_clock    (CLK200)
    ); 
    
    // Reset generator
    fidus_reset_gen_bfm #(
        .BFM_NAME       ("bfm_reset_gen_inst "),
        .RESET_NAME     ("RESET_N ")
    ) 
    bfm_reset_gen_inst (
        .o_bfm_rst_n    (RESET_n)
    );
    
endmodule 

//  -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:

 
