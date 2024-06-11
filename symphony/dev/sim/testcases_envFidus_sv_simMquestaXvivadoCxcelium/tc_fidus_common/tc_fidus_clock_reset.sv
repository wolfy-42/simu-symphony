//*-------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : template for a test case
// Updated       : date / author - comments
//--------------------------------------------------------------------//

//* Module declaration
`define STRINGIFY(x) `"x`"
`define TCFILENAME tcnamefromtcl

module test_case();

    // System Verilog Simulation management package
    import sim_management_pkg::*;
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;

    // BFM local instances becuse Active-HDL can't refere to the TB level (it's a tool bug)
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;    

    //* Variables and parameters ;
    sim_management s;
    parameter   TC_NAME = `STRINGIFY(`TCFILENAME); //name assigned from TCL scripts
    int        seed;
    real       rrr = 3.14;
    reg [31:0] hhh = 32'habcd1234;
    int        j   = 14;
    string     msg = "";

    //* ***************************** Test case body **********************************************
    initial
    begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        s.printMessage (TC_NAME,msg);
        s.printMessage (TC_NAME, "Global Reset asserted");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5.5ns");
        clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        reset_bfm = new("rst_bfm", tb.reset_if);

        reset_bfm.fAssertReset();

        //* Initialize the random data generator
        #1;
        seed = tb.lib_math_inst.seed;
        s.set_seed(seed);
        `ifndef XILINX_SIMULATOR
            $urandom(seed);
        `endif

        //* release the reset randomly
        #2000;
        #($urandom & 16'h00ff );
        reset_bfm.fDeassertReset();

        //* check reset level
        #2000;
        if (tb.o_LED == 1'b1) s.printPass  (TC_NAME, "RESET output released OK after initial global reset");
        else                  s.printError (TC_NAME, "RESET output released Bad after initial global reset ");

        //* print  examples
        $display ("%g ns Compare task Data Base centroid %d with expected : h = %h  r = %f", $time,j,hhh,rrr);
        s.printError (TC_NAME, "%g ns Compare task Data Base centroid %d with expected : h = %h  r = %f", $time,j,hhh,rrr);

        //* Simulation End
        #1000;

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
