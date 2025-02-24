//--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Jacob von Chorus
// Created       : 2018-05-22
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Test-case for the video source/sink BFM.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Module declaration
module test_case();

    // System Verilog Simulation management package
    import sim_management_pkg::*;
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;
    import fidus_axis_video_frame_bfm_pkg::*;
    import fidus_axis_video_source_bfm_pkg::*;
    import fidus_axis_video_sink_bfm_pkg::*;

    // Variables and parameters ;
    sim_management s;
    parameter TC_NAME = "tc_fidus_axis_video";
    parameter COMP_WIDTH = 12;  // Configure this
    parameter PIX_PER_CLK = 2;  // Configure this
    parameter TDATA_WIDTH = 72; // 3 (or 2 if subsampled) components * N bit/comp * M pix/clk
    parameter VIDEO_FORMAT = VIDEO_FORMAT_RGB; // Configure this
    parameter IMAGE_DIR = "../testcases_envFidus_sv_simMquestaXvivado/tc_fidus_axis_video/result_rtl/";
    string msg = "";

    // BFM local instances becuse Active-HDL can't refere to the TB level (it's a tool bug)
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;  

    // Source and Sink BFMs
    fidus_axis_video_source_bfm #(
        .COMP_WIDTH(COMP_WIDTH),
        .PIX_PER_CLK(PIX_PER_CLK),
        .TDATA_WIDTH(TDATA_WIDTH)) axi4s_video_source;

    fidus_axis_video_sink_bfm #(
        .COMP_WIDTH(COMP_WIDTH),
        .PIX_PER_CLK(PIX_PER_CLK),
        .TDATA_WIDTH(TDATA_WIDTH)) axi4s_video_sink;

    // Interfaces
    fidus_axis_video_if #(
        .TDATA_WIDTH(TDATA_WIDTH))
        axi4s_source_if (
        .aclk(tb.clk_if.c),
        .aresetn(tb.reset_if.rn));

    fidus_axis_video_if #(
        .TDATA_WIDTH(TDATA_WIDTH))
        axi4s_sink_if (
        .aclk(tb.clk_if.c),
        .aresetn(tb.reset_if.rn));


// ***************************** Test case body **********************************************

    // Global signals, connect the master and slave interfaces.
    wire [TDATA_WIDTH-1:0] tdata;
    wire tready;
    wire tvalid;
    wire [0:0] tuser;
    wire tlast;

    // Master driven signals.
    assign tdata = axi4s_source_if.tdata;
    assign tvalid = axi4s_source_if.tvalid;
    assign tuser = axi4s_source_if.tuser;
    assign tlast = axi4s_source_if.tlast;
    assign axi4s_source_if.tready = tready;

    // Slave driven signals.
    assign axi4s_sink_if.tdata = tdata;
    assign axi4s_sink_if.tvalid = tvalid;
    assign axi4s_sink_if.tuser = tuser;
    assign axi4s_sink_if.tlast = tlast;
    assign tready = axi4s_sink_if.tready;

    // Frames
    fidus_axis_video_frame_bfm #(.COMP_WIDTH(COMP_WIDTH)) frame_master1, frame_master2, frame_slave1, frame_slave2, frame_master3, frame_slave3;

    //---------------------------------------------------------------------------------------------
    //  -Two frames are created:
    //      frame_master1: counter test pattern
    //      frame_master2: colour bar test pattern
    //  -Both are written to file: "sent1.raw", "sent2.raw"
    //  -frame_master3 is created by reading "sent2.raw", it will be identical to frame_master2
    //  -All three frames are sent, along with a 4th, required so that the sink BFM knows it received all of the third.
    //  -Three frames are received in frame_slave1/2/3.
    //  -They are compared back to their masters and written out to: "received1/2/3.raw"
    //  -The written files are for visual inspection, self checking of the frames uses the video_frames class
    //      instantiations in memory.
    //---------------------------------------------------------------------------------------------
    initial
    begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        s.printMessage (TC_NAME, "Create sample image");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5ns");
        clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        reset_bfm = new("rst_bfm", tb.reset_if);

        reset_bfm.fAssertReset();
        #10;
        reset_bfm.fDeassertReset();

        // Initialize source and sink BFMs
        axi4s_video_source = new(axi4s_source_if, VIDEO_FORMAT, "fidus_axis_video_source_bfm");
        axi4s_video_sink = new(axi4s_sink_if, VIDEO_FORMAT, 100, 100, "fidus_axis_video_sink_bfm");
        axi4s_video_source.fSetGapIntervalandLength(30, 140, 5, 10); // Frames before transmitting gap

        // Create test patterns and save for viewing
        frame_master1 = frame_master1.fMakeCounterFrame(640, 480, VIDEO_FORMAT);
        frame_master2 = frame_master2.fMakeColourBar(640, 480, VIDEO_FORMAT);

        frame_master1.fWriteRawFrame({IMAGE_DIR, "sent1.raw"});
        frame_master2.fWriteRawFrame({IMAGE_DIR, "sent2.raw"});

        // Create a third frame by reading the second frame's in-file representation
        `ifdef XILINX_SIMULATOR // XSim can not handle $fread inside a class, so just create a new colour bar identical to frame_master2
            frame_master3 = frame_master3.fMakeColourBar(640, 480, VIDEO_FORMAT);
        `else
            frame_master3 = new(640, 480, VIDEO_FORMAT);
            frame_master3.fReadRawFrame({IMAGE_DIR, "sent2.raw"});
        `endif

        fork
            send: begin
                // Send frame
                axi4s_video_source.tSendFrame(frame_master1, .hblank(100), .vblank(100));
                axi4s_video_source.tSendFrame(frame_master2);
                axi4s_video_source.tSendFrame(frame_master3);
                axi4s_video_source.tSendFrame(frame_master1); // Required to trigger tuser so sink outputs the previous frame.
            end
            receive: begin
                // Receive
                axi4s_video_sink.tWaitForFrame();
                frame_slave1 = axi4s_video_sink.fGetLastFrame();
                frame_slave1.fWriteRawFrame({IMAGE_DIR, "received1.raw"});
                void'(frame_slave1.fCheckFrame(frame_master1));     // Self check

                axi4s_video_sink.tWaitForFrame();
                frame_slave2 = axi4s_video_sink.fGetLastFrame();
                frame_slave2.fWriteRawFrame({IMAGE_DIR, "received2.raw"});
                void'(frame_slave2.fCheckFrame(frame_master2));

                axi4s_video_sink.tWaitForFrame();
                frame_slave3 = axi4s_video_sink.fGetLastFrame();
                frame_slave3.fWriteRawFrame({IMAGE_DIR, "received3.raw"});
                void'(frame_slave3.fCheckFrame(frame_master2)); // Check against frame that was originally written before readRaw
            end
        join


        // Simulation End
        #100;
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
