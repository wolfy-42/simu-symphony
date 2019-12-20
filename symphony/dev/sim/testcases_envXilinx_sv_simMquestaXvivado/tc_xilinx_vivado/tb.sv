//-------------------------------------------------------------------//
//
// Copyright (C) 2006 Fidus Systems Inc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : template for FPGA top level Test Bench
// Updated       : 2015-08-15 / Arnold Balisch - fixes
// Updated       : 2018-06-22 / Jacob von Chorus
//               Test bench for video source/sink video generator.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Module declaration
module tb ();

    // Packages
    // NOTE - sim_management_pkg is included inside the test-case.
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;
    
    // Interfaces
    
    // RIPL Library instantiations
    sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    lib_math                lib_math_inst ();           // Math libraries.
    

    // Test case instantiation
    test_case test_case_inst ();

    // Variables and parameters;    
    clk_bfm_if clk_if();
    reset_bfm_if reset_if();
    
    // Assigns

    // BACKEND BFM
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;

    // FRONTEND BFM

    // Clock generator instantiation  
    
endmodule 

//  -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:

 
