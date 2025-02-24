//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project     : SIMU
// Author      : Jacob von Chorus
// Created     : June 26, 2018
// Description : Video source BFM compliant with Xilinx's AXI4-Stream Video IP
//               and System Design Guide (UG934)
//---------------------------------------------------------------------------//

package bfm_axi4s_video_source_pkg;

// PACKAGES
import sim_management_pkg::*;
import video_bfm_pkg::*;

class bfm_axi4s_video_source #(
        COMP_WIDTH = 8,             // Bit width of each component
        PIX_PER_CLK = 4,            // Pixels transmitted each clock cycle: 1, 2, or 4
        OUTPUT_CLK_EDGE = "rise",   // "fall" for falling edge, otherwise assumes rising edge
        TDATA_WIDTH = 96            // Width of axi4-stream tdata signal
);
    // CONSTANTS
    localparam NUM_COMPONENTS = 3;  // RGB and YCC

    // VARIABLES
    simManagementPkg    s;
    string              CLASS_NAME; // Name used in log messages.
    virtual axi4s_if #(.TDATA_WIDTH(TDATA_WIDTH)) io;   // AXI4-Stream interface

    logic [TDATA_WIDTH-1:0] tdata;              // AXI4-Stream, data signal
    logic                   tlast;              // AXI4-Stream, signals end of line
    logic                   tuser;              // AXI4-Stream, signals start of frame
    logic                   tvalid;             // AXI4-Stream, valid signal
    int                     gap_interval_min;   // Min number of clk cycles between random transmission gaps
    int                     gap_interval_max;   // Max number of clk cycles between random transmission gaps
    int                     gap_len_min;        // Random transmission gap minimum length
    int                     gap_len_max;        // Random transmission gap maximum length
    eVideoFormat            video_format;       // Colourspace and subsampling

    bit                     suppress_messages;  // Flag to suppress message output

    // FUNCTIONS and TASKS

    //-----------------------------------------------------------
    // Constructor
    //      io: AXI4-Stream interface
    //      video_format: colourspace and subsampling
    //      name: name used in logs
    //-----------------------------------------------------------
    function new (
        virtual axi4s_if #(.TDATA_WIDTH(TDATA_WIDTH)) io,
        eVideoFormat    video_format,
        string          name = "bfm_axi4s_video_source"
    );
        int i;
        this.CLASS_NAME     = name;
        this.io             = io;
        this.video_format   = video_format;
        // default variable states
        tdata               = 'h0;
        tlast               = 'b0;
        tuser               = 'h0;
        tvalid              = 'b0;
        // default drive of IO
        io.tdata            = 'h0;
        io.tlast            = 'b0;
        io.tuser            = 'h0;
        io.tvalid           = 'b0;

        suppress_messages = 0;

        gap_interval_min    = -1;
        gap_interval_max    = -1;
        gap_len_min         = 1;
        gap_len_max         = 10;
    endfunction : new

    //-----------------------------------------------------------
    // Allow/Disallow log message output (does not include passes/errors)
    //      suppress: 1 to disable, 0 to enable
    //-----------------------------------------------------------
    function void fSuppressTransactionMessages(input bit suppress);
        this.suppress_messages = suppress;
    endfunction : fSuppressTransactionMessages

    //-----------------------------------------------------------
    // Sets the interval between, and length of random gaps inserted in the transmission stream.
    //      min_interval: Min number of clk cycles between random transmission gaps     
    //      max_interval: Max number of clk cycles between random transmission gaps
    //      min_len: Random transmission gap minimum length
    //      max_len: Random transmission gap maximum length
    //
    //      Random gaps (tvalid = 0) can be inserted into the stream.
    //      Setting min_interval to -1 disables gap insertion.
    //-----------------------------------------------------------
    function void fSetGapIntervalandLength(
        input int min_interval,
        input int max_interval,
        input int min_len,
        input int max_len
    );
        if ((min_interval > max_interval) || (min_len > max_len))
        begin
            s.printError(CLASS_NAME, $sformatf(
                "Maximum interval/len (%d/%d) is less than minimum/len (%d/%d)",
                max_interval, max_len, min_interval, min_len));
        end

        if ((min_interval < 0) && !suppress_messages)
            s.printMessage(CLASS_NAME, "Disabling tvalid gap insertion");
        else if (!suppress_messages)
            s.printMessage(CLASS_NAME,$sformatf("Gap interval [%d %d], len [%d %d]", min_interval, max_interval, min_len, max_len));

        this.gap_interval_min = min_interval;
        this.gap_interval_max = max_interval;
        this.gap_len_min = min_len;
        this.gap_len_max = max_len;
    endfunction : fSetGapIntervalandLength

    //-----------------------------------------------------------
    // Creates a test pattern frame and transmits it.
    //      width: frame width
    //      height: frame height
    //      type_colour_bar: 0 for counter frame; 1 for colour bar frame
    //      hblank: results in transmission gap at the end of each line
    //      vblank: results in transmission gap at the end of each frame
    //      timeout: maximum number of clk cycles to wait for tready after tvalid is asserted
    //-----------------------------------------------------------
    task tCreateandSendFrame(
        input int width,
        input int height,
        input int type_colour_bar = 1,
        input int hblank = 0,
        input int vblank = 0,
        input int timeout = -1
    );

        video_frame #(.COMP_WIDTH(COMP_WIDTH)) tmp;
        if (type_colour_bar)
            tmp = tmp.fMakeColourBar(width, height, video_format);
        else
            tmp = tmp.fMakeCounterFrame(width, height, video_format);

        tSendFrame(tmp, hblank, vblank, timeout);
    endtask : tCreateandSendFrame

    //-----------------------------------------------------------
    // Transmits a frame over the AXI4S interface
    //      frame: frame to transmit
    //      hblank: results in transmission gap at the end of each line
    //      vblank: results in transmission gap at the end of each frame
    //      timeout: maximum number of clk cycles to wait for tready after tvalid is asserted
    //
    //      Task begins by waiting for the next clock edge.
    //-----------------------------------------------------------
    task tSendFrame(
        input video_frame#(COMP_WIDTH) frame,
        input int hblank = 0,
        input int vblank = 0,
        input int timeout = -1
    );

        logic [COMP_WIDTH*NUM_COMPONENTS-1:0] pixel_data;

        integer clk      = 0;
        integer col      = 0;
        integer row      = 0;
        integer pix      = 0;
        integer comp     = 0;

        int gap_ctr  = $urandom_range(this.gap_interval_min,this.gap_interval_max);
        tWaitForClk();

        // Copy pixel data into tdata
        for(row = 0; row < frame.height; row = row + 1)
        begin
            for(col = 0; col < frame.width; col = col + PIX_PER_CLK )
            begin
                // Allow multiple pixels in a single tdata
                for(pix = 0; pix<PIX_PER_CLK; pix=pix+1)
                begin
                    pixel_data = frame.pixels[row * frame.width + col + pix];

                    if (video_format == VIDEO_FORMAT_YCC422)
                    begin
                        // 2 components per pixel in YCC422
                        // Even pixels: {Cb0, Y0}, Odd pixels: {Cr0, Y1}
                        if (((pix + col) % 2) == 0)
                            this.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH] = {pixel_data[2*COMP_WIDTH-1 -:COMP_WIDTH], pixel_data[1*COMP_WIDTH-1 -:COMP_WIDTH]};
                        else
                            this.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH] = {pixel_data[3*COMP_WIDTH-1 -:COMP_WIDTH], pixel_data[1*COMP_WIDTH-1 -:COMP_WIDTH]};
                    end
                    else if (video_format == VIDEO_FORMAT_YCC420)
                    begin
                        // 2 components per pixel in YCC420
                        // Even rows:   Even Pixels: {Cb0, Y0}, Odd Pixels: {Cr0, Y1}
                        // Odd rows:    Even Pixels: {0, Y2}, Odd Pixels: {0, Y3}
                        if ((row % 2) == 0) // Even row
                        begin
                            if (((pix + col) % 2) == 0)
                                this.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH] = {pixel_data[2*COMP_WIDTH-1 -:COMP_WIDTH], pixel_data[1*COMP_WIDTH-1 -:COMP_WIDTH]};
                            else
                                this.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH] = {pixel_data[3*COMP_WIDTH-1 -:COMP_WIDTH], pixel_data[1*COMP_WIDTH-1 -:COMP_WIDTH]};
                        end
                        else // Odd row
                        begin // In AXI4-Stream Video compliant 422, odd lines carry no colour data
                            this.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH] = {{COMP_WIDTH{1'b0}}, pixel_data[1*COMP_WIDTH-1 -:COMP_WIDTH]};
                        end
                    end
                    else // No subsampling: YCC444 or RGB
                    begin
                        if (video_format == VIDEO_FORMAT_RGB)
                        begin
                            // RGB uses GBR ordering (lsb to msb) in tdata
                            this.tdata[(pix+1)*NUM_COMPONENTS*COMP_WIDTH-1-:NUM_COMPONENTS*COMP_WIDTH]
                                = {pixel_data[1*COMP_WIDTH-1 -:COMP_WIDTH], pixel_data[3*COMP_WIDTH-1 -:COMP_WIDTH], pixel_data[2*COMP_WIDTH-1 -:COMP_WIDTH]};
                        end
                        else // YCC444
                        begin
                            this.tdata[(pix+1)*NUM_COMPONENTS*COMP_WIDTH-1-:NUM_COMPONENTS*COMP_WIDTH] = pixel_data[NUM_COMPONENTS*COMP_WIDTH-1 : 0];
                        end
                    end
                end
                if (row == 0 && col == 0) // start of frame
                    this.tuser = 1'b1;
                else
                    this.tuser = 1'b0;
                if ((col+PIX_PER_CLK) >= frame.width) // end of line
                    this.tlast = 1'b1;
                else
                    this.tlast = 1'b0;

                this.tvalid = 1'b1;

                io.tdata = this.tdata;
                io.tuser = this.tuser;
                io.tlast = this.tlast;
                io.tvalid = this.tvalid;

                tWaitForReady(timeout); // Waits at least a clock cycle

                io.tvalid = 1'b0;

                // Randomized transmission gaps
                if (gap_ctr == 0 && this.gap_interval_min > 0)
                begin
                    gap_ctr = $urandom_range(this.gap_len_min,this.gap_len_max);
                    for (clk = 0; clk < gap_ctr; clk++)
                    begin
                        tWaitForClk();
                    end
                    // +1 compensates for immediate decrement.
                    gap_ctr = $urandom_range(this.gap_interval_min,this.gap_interval_max) + 1;
                end
                gap_ctr--;
            end
            // Hblanks in AXI4S Video is just a transmissionless period,
            // ie. a pause while an actual video system would be blanking
            for (clk = 0; clk < hblank; clk++)
            begin
                tWaitForClk();
            end
        end
        // Vblanks in AXI4S Video is just a transmissionless period,
        // ie. a pause while an actual video system would be blanking
        for (clk = 0; clk < vblank; clk++)
        begin
            tWaitForClk();
        end

        if (!suppress_messages)
            s.printMessage(CLASS_NAME,$sformatf("Sent Video Frame (%0dx%0d)", frame.width, frame.height));
    endtask : tSendFrame

    //-----------------------------------------------------------
    // Waits for rising clock edge
    //-----------------------------------------------------------
    task tWaitForPosClk();
        forever begin
            @(posedge io.aclk);
            break;
        end
    endtask : tWaitForPosClk

    //-----------------------------------------------------------
    // Waits for falling clock edge
    //-----------------------------------------------------------
    task tWaitForNegClk();
        forever begin
            @(negedge io.aclk);
            break;
        end
    endtask : tWaitForNegClk

    //-----------------------------------------------------------
    // Waits for configured clock edge
    //-----------------------------------------------------------
    task tWaitForClk();
        if (OUTPUT_CLK_EDGE == "fall")
            tWaitForNegClk();
        else
            tWaitForPosClk();
    endtask : tWaitForClk

    //-----------------------------------------------------------
    // Returns at next clock edge where tready is asserted
    //      timeout: maximum number of clock cycles to wait for
    //
    //      Results in an error if the timeout is exceeded. Timeout is
    //      ignored if configured to -1 (default).
    //-----------------------------------------------------------
    task tWaitForReady(input int timeout);

        static int err_cntr = 0;
        int timeout_counter = timeout;

        forever begin
            tWaitForClk();
            if (io.tready)
            begin
                break;
            end
            else if (timeout >= 0) // Ignore timeouts if it is -1
            begin
                timeout_counter--;
                if (timeout_counter == 0)
                begin
                    if (err_cntr < 20)
                    begin
                        err_cntr++;
                        s.printError(CLASS_NAME,$sformatf(
                            "tvalid -> tread timeout, exceed %d clk cycles of latency.", timeout));
                    end

                    break;
                end
            end
        end
    endtask : tWaitForReady
endclass : bfm_axi4s_video_source
endpackage : bfm_axi4s_video_source_pkg

