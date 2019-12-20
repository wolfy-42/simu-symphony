//--------------------------------------------------------------------//
//
// Copyright (C) 2018 Fidus Systems Inc.
//
// Project       : simu
// Author        : Jacob von Chorus
// Created       : 2018-05-22
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Test-case for Vivado IPI Questa export.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Module declaration
module test_case();

    // System Verilog Simulation management package
    import sim_management_pkg::*;
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;

    // Variables and parameters ;
    sim_management s;
    parameter TC_NAME = "tc_xilinx_vivado";
    string msg = "";


// ***************************** Test case body **********************************************
    // IPI tb
    system_tb system_tb_i();


    initial
    begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        s.printMessage (TC_NAME, "Create sample image");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5ns");
        tb.clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        tb.reset_bfm = new("rst_bfm", tb.reset_if);

        tb.reset_bfm.fAssertReset();
        #10;
        tb.reset_bfm.fDeassertReset();



        // Simulation End
        wait (tb.test_case_inst.system_tb_i.uart_rcvr_wrapper_0.sim_done);
        s.testComplete;
     end

endmodule // test_case

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:
