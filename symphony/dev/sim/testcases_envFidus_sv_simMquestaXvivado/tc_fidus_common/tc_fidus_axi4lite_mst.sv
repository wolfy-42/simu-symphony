//--------------------------------------------------------------------//
//
// Copyright (C) 2018 Fidus Systems Inc.
//
// Project       : VIP Simu SystemVerilog
// Author        : Victor Dumitriu
// Created       : 2018-03-15
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Test-case example for Fidus AXI-Lite Master BFM.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Module declaration
module test_case();

    // System Verilog Simulation management package
    import sim_management_pkg::*;
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;
    import fidus_axi4lite_mst_bfm_pkg::*;

    // Variables and parameters ;
    sim_management s;
    parameter TC_NAME = "tc_fidus_axi4lite_mst";
    int seed;
    real      rrr = 3.14;
    reg [31:0] hhh = 32'habcd1234;
    int j= 14;
    string msg = "";

    // AXI Lite Master BFM instantiation.
    fidus_axi4lite_mst_bfm #(.AWIDTH(8), .DWIDTH(16), .OUTPUT_DRV_EDGE("rise"), .OUTPUT_DRV_DLY(0)) m1;
    // BFM local instances becuse Active-HDL can't refere to the TB level (it's a tool bug)
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;  

    // AXI interface wires and registers.

    // Slave signals (driven in test-case).
    reg             awready;
    reg             wready;
    reg     [1:0]   bresp;
    reg             bvalid;
    reg             arready;
    reg     [15:0]  rdata;
    reg             rvalid;
    reg     [1:0]   rresp;

    // Master signals (driven by AXI Lite Master BFM in test-case).
    wire    [7:0]   awaddr;
    wire            awvalid;
    wire    [15:0]  wdata;
    wire    [1:0]   wstrb;
    wire            wvalid;
    wire            bready;
    wire    [7:0]   araddr;
    wire            arvalid;
    wire            rready;

    // Read data response.
    reg     [15:0]  rdat_resp;

// ***************************** Test case body **********************************************

    // Global signals.
    assign tb.axi_bfm_channel.aclk = tb.clk_if.c;
    assign tb.axi_bfm_channel.aresetn = tb.reset_if.rn;

    // Master driven signals.
    assign awaddr = tb.axi_bfm_channel.awaddr;
    assign awvalid = tb.axi_bfm_channel.awvalid;
    assign wdata = tb.axi_bfm_channel.wdata;
    assign wstrb = tb.axi_bfm_channel.wstrb;
    assign wvalid = tb.axi_bfm_channel.wvalid;
    assign bready = tb.axi_bfm_channel.bready;
    assign araddr = tb.axi_bfm_channel.araddr;
    assign arvalid = tb.axi_bfm_channel.arvalid;
    assign rready = tb.axi_bfm_channel.rready;

    // Slave driven signals.
    assign tb.axi_bfm_channel.awready = awready;
    assign tb.axi_bfm_channel.wready = wready;
    assign tb.axi_bfm_channel.bresp = bresp;
    assign tb.axi_bfm_channel.bvalid = bvalid;
    assign tb.axi_bfm_channel.arready = arready;
    assign tb.axi_bfm_channel.rdata = rdata;
    assign tb.axi_bfm_channel.rvalid = rvalid;
    assign tb.axi_bfm_channel.rresp = rresp;

    initial
    begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        reset_bfm = new("rst_bfm", tb.reset_if);
        reset_bfm.fAssertReset();

        // BFM class construction.
        m1 = new("fidus_axi4lite_mst_bfm", tb.axi_bfm_channel);

        // Assign initial AXI signals low.
        awready = 1'b1;
        wready = 1'b1;
        bresp = 2'b00;
        bvalid = 1'b0;
        arready = 1'b1;
        rdata = 'h0;
        rvalid = 1'b0;
        rresp = 2'b00;

        #20;

        // Initialize AXI BFM setings.
        m1.fSetTransactionMessagingOnOff(1);             // Enable transaction messaging.
        m1.fSetDebugMessagingOnOff(0);                   // Disable debug messaging.
        m1.fSetWrErrorChkOnOff(0);                       // Disable write response checking (not recommended).
        m1.fSetRdErrorChkOnOff(0);                       // Disable read response checking (not recommended).
        m1.fSetWrRespReadyLatency(0);                    // Set Write Response Ready latency to 0 c.c.
        m1.fSetRdRespReadyLatency(0);                    // Set Read Response Ready latency to 0 c.c.
        m1.fSetTransactionTimeoutValues(-1, -1);         // Set read and write timeout values. Negative values mean no time-outs.

        // Initialize the random data generator
        #1;
        seed = tb.lib_math_inst.seed;
        `ifndef XILINX_SIMULATOR
            $urandom(seed);
        `endif

        // Release the reset after a random period of time.
        #2000;
        #($urandom & 16'h00ff );
        reset_bfm.fDeassertReset();

        // Check reset level
        #2000;
        if (tb.o_LED == 1'b1)
            s.printPass (TC_NAME, "RESET output released OK after initial global reset");
        else
            s.printError   (TC_NAME, "RESET output released Bad after initial global reset ");

        // Print example examples
        $display ("%g ns Compare task Data Base centroid %d with expected : h = %h  r = %f", $time,j,hhh,rrr);
        s.printWarning (TC_NAME, "%g ns Compare task Data Base centroid %d with expected : h = %h  r = %f", $time,j,hhh,rrr);

        #2000;

        // Issue AXI Lite write test transactions. Must fork if we wish to generate a response concurrent
        // with the function in the same block.
        fork

            tr_issue: begin
                m1.tWriteAXI4Lite(8'h0f, 16'habab);      // Write transaction: address, data, strobe.
            end

            response_gen : begin

                @( posedge tb.axi_bfm_channel.bready)
                begin
                    #40;
                    bvalid = 1'b1;
                end

                #10;
                bvalid = 1'b0;
            end

        join

        // Issue AXI Lite read test transactions. Must fork if we wish to generate a response concurrent
        // with the function in the same block.
        fork

            tr_issue2: begin
                m1.tReadAXI4Lite(8'haa, rdat_resp);      // Write transaction: address, data, strobe.
            end

            response_gen2: begin

                @( posedge tb.axi_bfm_channel.rready)
                begin
                    #40;
                    rvalid = 1'b1;
                    rdata = 16'h1234;
                end

                #10;
                rvalid = 1'b0;
            end

        join

        // Simulation End
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
