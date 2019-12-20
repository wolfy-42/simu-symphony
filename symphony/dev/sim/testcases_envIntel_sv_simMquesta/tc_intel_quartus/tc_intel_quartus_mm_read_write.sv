//--------------------------------------------------------------------//
//
// Copyright (C) 2017 Fidus Systems Inc.
//
// Project       : simu
// Author        : Victor Dumitriu
// Created       : 2018-08-10
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Example test-case for Intel test-bench example system.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Module declaration

module test_case();

    // Import Altera general sim packages.
    import verbosity_pkg::*;
    import avalon_mm_pkg::*;

    // Fidus simulation package.
    import sim_management_pkg::*;

    // Variables and parameters.
    sim_management s;
    parameter TC_NAME = "tc_intel_quartus_mm_read_write";
    string msg = "";
    parameter pNUM_TESTS = 4;

    //Random write data.
    int rnd_dat = 0;

    // BFM Avalon access data.
    bit [31:0] read_data;


    // ------------------------------------ Test case body --------------------------------------
    initial
    begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        tb.intel_avalon_example_system_inst.mm_master_bfm_0.init();

        s.printMessage (TC_NAME, "Beginning Testcase Simulation.");
        s.printMessage (TC_NAME, "Sim clock: 100 MHz.");
        s.printMessage (TC_NAME, "Initial reset asserted 50 c.c.");

        // Wait for reset de-assert.
        #1000;

        for (int i = 0; i < pNUM_TESTS; i++) begin
            // Set IOs as inputs.
            tBfmWrite(32'h00000001, 32'h00000000);
            #100;

            // Generate and drive random input data.
            rnd_dat = $urandom_range(8'h00, 8'hFF);
            tb.intel_avalon_example_system_inst_pio_0_external_connection_export = rnd_dat;

            // Check correct inputs.
            #100;
            tBfmRead(32'h00000000, read_data);
            s.checkSig(TC_NAME, 2,"Input data check", read_data, rnd_dat);
        end

        #200;
        s.testComplete;
    end


    // ------------------------------------------------------------------------------------------
    // Simulation tasks.
    // ------------------------------------------------------------------------------------------

    // Write operation task.
    task tBfmWrite (
                        bit [31:0] addr,
                        bit [31:0] data);

        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_address(addr);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_data(data, 0);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_byte_enable(4'b1111, 0);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_request(REQ_WRITE);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_burst_count(8'h01);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_burst_size(8'h01);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_init_latency(2);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_idle(2, 0);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.push_command();

        @(tb.intel_avalon_example_system_inst.mm_master_bfm_0.signal_response_complete)

        tb.intel_avalon_example_system_inst.mm_master_bfm_0.pop_response();

    endtask

    // Issue read operation function.
    function void fBfmIssueRead (
                        bit [31:0] addr);

        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_address(addr);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_request(REQ_READ);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_burst_count(8'h01);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_burst_size(8'h01);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_init_latency(2);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.set_command_idle(2, 0);
        tb.intel_avalon_example_system_inst.mm_master_bfm_0.push_command();
    endfunction

    // Complete Read task.
    task tBfmRead (
                input bit [31:0] addr,
                output bit [31:0] data);

        fBfmIssueRead(addr);

        @(tb.intel_avalon_example_system_inst.mm_master_bfm_0.signal_response_complete)

        tb.intel_avalon_example_system_inst.mm_master_bfm_0.pop_response();
        data = tb.intel_avalon_example_system_inst.mm_master_bfm_0.get_response_data(0);

    endtask

endmodule // test_case
