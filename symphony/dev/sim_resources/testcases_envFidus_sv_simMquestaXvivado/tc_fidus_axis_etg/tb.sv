/*-----------------------------------------------------------------------------
// Title                       : Ethernet packet generator
// Project                     : Ethernet packet generator BFM
//-----------------------------------------------------------------------------
// File                        : tc_fidus_axis_etg.sv
// Author                      : Bassem Sleiman
// Created                     : 22/04/2020
//-----------------------------------------------------------------------------
this is the top level test bench
//-----------------------------------------------------------------------------*/

// Module declaration
module tb ();

    // Packages
    // NOTE - sim_management_pkg is included inside the test-case.
import fidus_clock_gen_bfm_pkg ::*;
import fidus_reset_gen_bfm_pkg ::*;


    // Interfaces



    // RIPL Library instantiations
    sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    lib_math                lib_math_inst ();           // Math libraries.


    // Test case instantiation
    test_case test_case_inst ();

    // Variables and parameters;
    clk_bfm_if clk_if();
    reset_bfm_if reset_if();


endmodule



