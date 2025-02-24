//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename    : tc_xilinx_axilite_if.sv
// Project     : RIPL/SIMU
// Author      : Paul Roukema
// Created     : May 26, 2021
// Description : Testcase for AXILITE VIP demo
//
//---------------------------------------------------------------------------//

module test_case ();

    // Xilinx VIP
    import axi_vip_pkg::*;

    // SIMU Management.
    import sim_management_pkg::*;
    import xilinx_axilite_vip_util_pkg::*;

    // Variables, objects, parameters.
    typedef sim_management s;

    parameter TC_NAME = "tc_xilinx_axilite_if";

    axilite_mst_agent agent;

    // AXI Stimulus
    initial
        begin
            // Initialize the simulation
            s::initSim(TC_NAME);
            tb.axi_if.set_intf_master();

            s::printMessage (TC_NAME, "Global Reset asserted");
            s::printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5ns");
            tb.clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
            tb.reset_bfm = new("rst_bfm", tb.reset_if);
            tb.reset_bfm.fAssertReset();

            // Instantiate master.
            agent = new("agent", tb.axi_if);
            agent.start_master();                      // agent start to run

            #400;
            tb.reset_bfm.fDeassertReset();
            #200;

            // Check register defaults
            axilite_read_check(agent, 0, 32'h12345678);
            axilite_read_check(agent, 4, 32'h0);

            // Write and check scratch register
            axilite_write_read_check(agent, 0, 32'hfedcba9);

            // Set Flag
            axilite_write(agent, 4, 32'h1);
            axilite_read_check(agent, 4, 32'h1);

            // Clear flag
            axilite_write(agent, 4, 32'h2);
            axilite_read_check(agent, 4, 32'h0);


            #200;
            s::testComplete;
        end

endmodule

