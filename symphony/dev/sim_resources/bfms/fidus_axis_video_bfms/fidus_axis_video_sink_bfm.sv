//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Jacob von Chorus
// Created       : 2018-06-26
//---------------------------------------------------------------------------//
//---------------------------------------------------------------------------//
// Description   : Video sink BFM compliant with Xilinx's AXI4-Stream Video IP
//               and System Design Guide (UG934)
// Updated       : date / author - comment
//---------------------------------------------------------------------------//

package fidus_axis_video_sink_bfm_pkg;

// PACKAGES
import sim_management_pkg::*;
import fidus_axis_video_frame_bfm_pkg::*;

class fidus_axis_video_sink_bfm #(
        COMP_WIDTH = 8,
        PIX_PER_CLK = 4,
        OUTPUT_CLK_EDGE = "rise",    // "fall" for falling edge, otherwise assumes rising edge
        TDATA_WIDTH = 96
);
    // CONSTANTS
    localparam NUM_COMPONENTS = 3;  // RGB and YCC
    localparam SEQ_CNTR_WIDTH = 8;

    // VARIABLES
    sim_management    s;
    string              CLASS_NAME;                     // Name used in log output.
    virtual fidus_axis_video_if #(.TDATA_WIDTH(TDATA_WIDTH)) io;   // AXI4S interface.

    event                       frame_complete; // Event triggered after full frame has been received
    fidus_axis_video_frame_bfm #(COMP_WIDTH)   frame;          // Stores video frame that gets returned from BFM
    bit [TDATA_WIDTH-1:0]       parity;         // Stores the parity of the last frame.
    bit [SEQ_CNTR_WIDTH-1:0]    sequence_counter; // Last sequence counter value.
    int                         min_hblank = 0; // Min hblank that could be seen, causes no-reception periods
    int                         min_vblank = 0; // Min vblank that could be seen, causes no-reception periods
    eVideoFormat                video_format;   // Colourspace and subsampling

    // FUNCTIONS AND TASKS

    //-----------------------------------------------------------
    // Constructor
    //      io: AXI4-Stream interface
    //      video_format: colourspace and subsampling
    //      min_vblank: min hblank that could be seen, causes no-reception periods
    //      min_hblank: min vblank that could be seen, causes no-reception periods
    //      name: name used in logs
    //
    //      Forks a listener that monitors interface and stores received frames.
    //-----------------------------------------------------------
    function new (
        virtual fidus_axis_video_if #(.TDATA_WIDTH(TDATA_WIDTH)) io,
        eVideoFormat    video_format,
        int             min_vblank = 0,
        int             min_hblank = 0,
        string          name = "fidus_axis_video_sink_bfm"
    );
        integer i;
        this.CLASS_NAME     = name;
        this.io             = io;
        this.video_format   = video_format;
        this.min_vblank     = min_vblank;
        this.min_hblank     = min_hblank;

        // default drive of IO
        io.tready           = 'h1;

        fork
           tListen();
        join_none
    endfunction : new

    //-----------------------------------------------------------
    // Wait until reception of a complete frame. This is triggered on the start of
    // frame signal of a subsequent frame.
    //-----------------------------------------------------------
    task tWaitForFrame();
        @frame_complete;
    endtask : tWaitForFrame

    //-----------------------------------------------------------
    // Monitor AXI4S interface for frames. A complete frame is signaled by the start-of-frame
    // of a subsequent frame. The height and width are determined by the number of pixels
    // received between end-of-line and start-of-frame signals.
    //-----------------------------------------------------------
    task tListen();
        int width;
        int height;
        bit legal_frame = 1;
        int row = 0;
        int col = 0;
        int comp = 0;
        int pix;
        int blanking_cntr = 0;
        logic [COMP_WIDTH*NUM_COMPONENTS-1:0] pixel_data [$];
        logic [COMP_WIDTH*NUM_COMPONENTS-1:0] pixel_value;
        logic [COMP_WIDTH*NUM_COMPONENTS-1:0] pixel_value_subsamp [2];
        bit [TDATA_WIDTH-1:0]       parity_value;         // Stores the parity of the last frame.
        bit [SEQ_CNTR_WIDTH-1:0]    sequence_counter_value[2]; // Last sequence counter value. Array is used because 2nd last pixel contains counter.


        while(1)
        begin
            io.tready = 1'b1;
            if(blanking_cntr > 0)
            begin
                io.tready = 1'b0;
                blanking_cntr = blanking_cntr - 1;
            end
            tWaitForClk();
            if( io.tvalid && io.tready )
            begin
                // Detected start of frame, indicates previous frame is complete and ready for parsing
                if (io.tuser)
                begin
                    height = row; // Counted the number of lines of the previous frame, we know it is complete now
                    if (legal_frame && width > 0 && height > 0)
                    begin
                        frame = new(width, height, video_format);
                        for (row = 0; row < height; row++)
                        begin
                            for(col = 0; col < width; col++)
                            begin
                                pixel_value = pixel_data.pop_front();

                                if (video_format == VIDEO_FORMAT_RGB)
                                begin
                                    frame.pixels[row*width + col][1*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[3*COMP_WIDTH-1 -:COMP_WIDTH];
                                    frame.pixels[row*width + col][2*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[1*COMP_WIDTH-1 -:COMP_WIDTH];
                                    frame.pixels[row*width + col][3*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[2*COMP_WIDTH-1 -:COMP_WIDTH];
                                end
                                else
                                begin
                                    frame.pixels[row*width + col] = pixel_value[COMP_WIDTH*NUM_COMPONENTS-1 : 0];
                                end
                            end
                        end
                        frame.fSubsampleFrame();
                        this.parity = parity_value;
                        this.sequence_counter = sequence_counter_value[1];
                        -> frame_complete;
                    end
                    else
                    begin
                        // If a bad frame was transferred (dimension error) raise the received flag
                        // so testbenches do not hang. The frame is zeroed first.
                        if (!legal_frame && width > 0 && height > 0) begin
                            frame = new(width, height, video_format);
                            for (row = 0; row < height; row++)
                            begin
                                for(col = 0; col < width; col++)
                                begin
                                    frame.pixels[row*width + col] = 0; // Zero all
                                end
                            end
                            this.parity = 32'hDEADBEEF; // Invalid frame so output a recognizable parity.
                            this.sequence_counter = 0-1;
                            -> frame_complete;
                        end

                        while (pixel_data.size() > 0 ) // Drain any stored pixel data
                        begin
                            void'(pixel_data.pop_front());
                        end
                    end

                    legal_frame = 1;
                    row = 0;
                    col = 0;
                    blanking_cntr = min_vblank;
                    parity_value = 0;
                end

                // Continue parity calculation, and store/shift sequence counter.
                parity_value = parity_value ^ io.tdata;
                sequence_counter_value[1] = sequence_counter_value[0];
                sequence_counter_value[0] = io.tdata[SEQ_CNTR_WIDTH-1:0];

                for(pix = 0; pix<PIX_PER_CLK; pix++)
                begin
                    // Even pixels contain Cb, odd contain Cr. Therefore two pixels
                    // are needed to determine their chroma
                    if (video_format == VIDEO_FORMAT_YCC422)
                    begin
                        pixel_value[2*COMP_WIDTH-1 : 0] = io.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH];
                        if (((col + pix) % 2) == 0) // Even pixels, wait for Cr, store Cb; Odd pixels, get Cr and store 2 pixels
                        begin
                            pixel_value_subsamp[0][(1)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(1)*COMP_WIDTH-1 -:COMP_WIDTH]; // Y0
                            pixel_value_subsamp[0][(2)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cb0
                            pixel_value_subsamp[1][(2)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cb1 = Cb0
                        end
                        else
                        begin // Odd
                            pixel_value_subsamp[1][(1)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(1)*COMP_WIDTH-1 -:COMP_WIDTH]; // Y1
                            pixel_value_subsamp[0][(3)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cr0
                            pixel_value_subsamp[1][(3)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cr1 = Cr0
                            pixel_data.push_back(pixel_value_subsamp[0]);
                            pixel_data.push_back(pixel_value_subsamp[1]);
                        end
                    end
                    else if (video_format == VIDEO_FORMAT_YCC420)
                    begin
                        // Identical to 422 on even rows, two consecutive pixels are needed to determine chroma
                        if ((row % 2) == 0)
                        begin
                            pixel_value[2*COMP_WIDTH-1 : 0] = io.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH];
                            if (((col + pix) % 2) == 0) // Even pixels, wait for Cr, store Cb; Odd pixels, get Cr and store 2 pixels
                            begin
                                pixel_value_subsamp[0][(1)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(1)*COMP_WIDTH-1 -:COMP_WIDTH]; // Y0
                                pixel_value_subsamp[0][(2)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cb0
                                pixel_value_subsamp[1][(2)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cb1 = Cb0
                            end
                            else
                            begin // Odd
                                pixel_value_subsamp[1][(1)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(1)*COMP_WIDTH-1 -:COMP_WIDTH]; // Y1
                                pixel_value_subsamp[0][(3)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cr0
                                pixel_value_subsamp[1][(3)*COMP_WIDTH-1 -:COMP_WIDTH] = pixel_value[(2)*COMP_WIDTH-1 -:COMP_WIDTH]; // Cr1 = Cr0
                                pixel_data.push_back(pixel_value_subsamp[0]);
                                pixel_data.push_back(pixel_value_subsamp[1]);
                            end
                        end
                        else
                        begin // Odd rows have no chroma, the fSubsampleFrame call will copy chroma from the even rows
                            pixel_value[2*COMP_WIDTH-1 : 0] = io.tdata[(pix+1)*2*COMP_WIDTH-1 -:2*COMP_WIDTH];
                            pixel_value_subsamp[0] = {{COMP_WIDTH{1'b0}}, {COMP_WIDTH{1'b0}}, pixel_value[COMP_WIDTH-1 : 0]};
                            pixel_data.push_back(pixel_value_subsamp[0]);
                        end
                    end
                    else // YCC444 and RGB, RGB (GBR) gets reordered later
                    begin
                        pixel_data.push_back(io.tdata[(pix+1)*NUM_COMPONENTS*COMP_WIDTH-1-:NUM_COMPONENTS*COMP_WIDTH]);
                    end
                end

                col = col + PIX_PER_CLK;

                if (io.tlast)
                begin
                    if (width != 0 && width != col)
                    begin
                        s.printWarning(CLASS_NAME,  $sformatf(
                            "Line %0d, length of %0d pixels does not match previous (%0d pixels)",
                            row, col, width));
                        legal_frame = 0;
                    end
                    width = col;
                    row += 1;
                    col = 0;
                    blanking_cntr = min_hblank;
                end
            end
        end
    endtask : tListen

    //-----------------------------------------------------------
    // Returns the last full frame. May want to call tWaitForFrame first.
    // Returns: Last received video frame.
    //-----------------------------------------------------------
    function fidus_axis_video_frame_bfm#(COMP_WIDTH) fGetLastFrame ();
        return frame;
    endfunction : fGetLastFrame

    //-----------------------------------------------------------
    // Returns the last full frame, its parity (should be 0 if F_Video_BIST is used to embed codes),
    // and the embedded sequence counter. May want to call tWaitForFrame first.
    // Outputs:
    //      parity: parity of the frame, 0 means parity passed
    //      sequence_counter: sequence counter value of frame
    // Returns: Last received video frame.
    //-----------------------------------------------------------
    function fidus_axis_video_frame_bfm#(COMP_WIDTH) fGetLastFrame_parity (ref bit [TDATA_WIDTH-1:0] _parity, ref bit [SEQ_CNTR_WIDTH-1:0] _sequence_counter);
        _parity = this.parity;
        _sequence_counter = this.sequence_counter;
        return frame;
    endfunction : fGetLastFrame_parity

    //-----------------------------------------------------------
    // Waits for the next rising clock edge.
    //-----------------------------------------------------------
    task tWaitForPosClk();
        forever begin
            @(posedge io.aclk);
            break;
        end
    endtask : tWaitForPosClk

    //-----------------------------------------------------------
    // Waits for the next falling clock edge.
    //-----------------------------------------------------------
    task tWaitForNegClk();
        forever begin
            @(negedge io.aclk);
            break;
        end
    endtask : tWaitForNegClk

    //-----------------------------------------------------------
    // Waits for the next configured clock edge.
    //-----------------------------------------------------------
    task tWaitForClk();
        if (OUTPUT_CLK_EDGE == "fall")
            tWaitForNegClk();
        else
            tWaitForPosClk();
    endtask : tWaitForClk

endclass : fidus_axis_video_sink_bfm
endpackage : fidus_axis_video_sink_bfm_pkg
