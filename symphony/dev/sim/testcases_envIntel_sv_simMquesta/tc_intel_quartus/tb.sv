//--------------------------------------------------------------------//
//
// Copyright (C) 2018 Fidus Systems Inc.
//
// Project       : simu
// Author        : Victor Dumitriu
// Created       : 2018-08-10
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Example top-level test-bench file for Intel test-bench
//               example system. File based on test-bench top-level file
//               found in 
//               intel_avalon_example_system/testbench/intel_avalon_example_system_tb/simulation
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Module declaration

//module;
module tb ();

    // Packages

    // Interfaces
   
    // Test case instantiation
   test_case test_case_inst ();   
    
    // Local wires.
    wire        intel_avalon_example_system_inst_clk_bfm_clk_clk;                  // intel_avalon_example_system_inst_clk_bfm:clk -> [intel_avalon_example_system_inst:clk_clk, intel_avalon_example_system_inst_reset_bfm:clk]
    reg   [7:0] intel_avalon_example_system_inst_pio_0_external_connection_export; // [] -> [intel_avalon_example_system_inst:pio_0_external_connection_export, intel_avalon_example_system_inst_pio_0_external_connection_bfm:sig_export]
    wire        intel_avalon_example_system_inst_reset_bfm_reset_reset;            // intel_avalon_example_system_inst_reset_bfm:reset -> intel_avalon_example_system_inst:reset_reset_n
    
    // Test-bench system.
    intel_avalon_example_system intel_avalon_example_system_inst (
        .clk_clk                          (intel_avalon_example_system_inst_clk_bfm_clk_clk),                  //                       clk.clk
        .pio_0_external_connection_export (intel_avalon_example_system_inst_pio_0_external_connection_export), // pio_0_external_connection.export
        .reset_reset_n                    (intel_avalon_example_system_inst_reset_bfm_reset_reset)             //                     reset.reset_n
    );
    
    // Intel clock source.
    altera_avalon_clock_source #(
        .CLOCK_RATE (100000000),
        .CLOCK_UNIT (1)
    ) intel_avalon_example_system_inst_clk_bfm (
        .clk (intel_avalon_example_system_inst_clk_bfm_clk_clk)  // clk.clk
    );
    
    // Intel reset source.
    altera_avalon_reset_source #(
        .ASSERT_HIGH_RESET    (0),
        .INITIAL_RESET_CYCLES (50)
    ) intel_avalon_example_system_inst_reset_bfm (
        .reset (intel_avalon_example_system_inst_reset_bfm_reset_reset), // reset.reset_n
        .clk   (intel_avalon_example_system_inst_clk_bfm_clk_clk)        //   clk.clk
    );
    
endmodule 
