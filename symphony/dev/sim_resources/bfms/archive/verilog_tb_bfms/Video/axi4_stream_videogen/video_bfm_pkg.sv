//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project     : SIMU
// Author      : Jacob von Chorus
// Created     : June 26, 2018
// Description : Video frame class and utility functions to generate frames, read
//               and write to file, and compare frames.
//---------------------------------------------------------------------------//


package video_bfm_pkg;

// PACKAGES
import sim_management_pkg::*;

// TYPE DEFINITIONS
// Colour space and subsampling
typedef enum {VIDEO_FORMAT_YCC422 = 0, VIDEO_FORMAT_YCC444 = 1, VIDEO_FORMAT_RGB = 2, VIDEO_FORMAT_YCC420 = 3} eVideoFormat;

//----------------------------------------------
// Video frame container class and utilities.
//----------------------------------------------
class video_frame #(
    COMP_WIDTH = 8     // Up to 16 inclusive.
);
    // CONSTANTS
    localparam NUM_COMPONENTS   = 3;                            // RGB and YCC
    localparam PIX_WIDTH        = COMP_WIDTH*NUM_COMPONENTS;    // Bits in entire pixel


    // VARIABLES
    simManagementPkg s;
    logic [PIX_WIDTH-1:0]   pixels [];      // Organized LSB to MSB: RGB, YCbCr
    int                     width;          // Width of frame
    int                     height;         // Height of frame
    eVideoFormat            video_format;   // Colourspace and subsampling
    string                  CLASS_NAME;     // Name used for log messages


    // FUNCTIONS AND TASKS
    
    //-----------------------------------------------------------
    // Constructor
    //      width: frame width
    //      height: frame height
    //      video_format: colourspace and subsampling
    //      name: name used in logs
    //-----------------------------------------------------------
    function new(
        int width,
        int height,
        eVideoFormat video_format,
        string name = ""
    );
        static int frame_count = 0;

        this.width = width;
        this.height = height;
        this.pixels = new[width*height];
        this.video_format = video_format;

        if (name == "")
            this.CLASS_NAME = $sformatf("video_frame#%0d",frame_count);
        else
            this.CLASS_NAME = name;
        frame_count = frame_count + 1;
    endfunction : new

    //-----------------------------------------------------------
    // Check frame against another
    //      expected: frame to compare to
    //
    //      returns: 0 for no match, 1 for match
    //-----------------------------------------------------------
    function bit fCheckFrame(video_frame #(COMP_WIDTH) expected);
        int row, col, index, max_index;
        int err_cntr = 0;
        int max_errors = 20;

        if (this.height != expected.height || this.width != expected.width)
        begin
            s.printError(CLASS_NAME, $sformatf("Expected dimensions: %dx%d; Received: %dx%d",
                expected.width, expected.height, this.width, this.height));
            return 0;
        end

        max_index = this.width * this.height;
        for (index = 0; index < max_index; index++)
        begin
            if (expected.pixels[index] !== this.pixels[index])
            begin
                row = index / this.width;
                col = index % this.width;
                err_cntr++;
                s.printError(CLASS_NAME, $sformatf("Pixel col %d, row %d; Expected: 0x%h; Received: 0x%h",
                    col, row, expected.pixels[index], this.pixels[index]));
            end
            if (err_cntr > max_errors)
                return 0;
        end

        if (err_cntr > 0)
        begin
            return 0;
        end
        else
        begin
            s.printPass(CLASS_NAME, "Received frame matches expected frame.");
            return 1;
        end
    endfunction : fCheckFrame

    //-----------------------------------------------------------
    // Write raw pixel data to file
    //      filename: filename to write
    //
    //      Pixels are written consecutively from top-left to bottom-right.
    //      Components are written RGB or YCC with 16 bits per component.
    //      Little-endian byte ordering is used.
    //      Convert to .tif with:
    //      RGB:
    //           raw2tiff  -w <width> -l <height> -p rgb -b 3 -d short <input.raw> <output.tif>
    //      YCC (compile ycc2rgb.c):
    //           ycc2rgb <ycc_in.raw> <rgb_out.raw>
    //           raw2tiff  -w <width> -l <height> -p rgb -b 3 -d short <input.raw> <output.tif>
    //-----------------------------------------------------------
    function void fWriteRawFrame(string filename);
        integer f, row, col, i;
        logic [15:0] out_component;


        f = $fopen(filename, "wb");
        assert (f!=0) else $fatal($sformatf("Unable to open output image file %s", filename));

        for(row = 0; row < this.height; row++)
        begin
            for(col = 0; col < this.width; col ++)
            begin
                logic [PIX_WIDTH-1:0] pixels_out = this.pixels[row*this.width+col];

                out_component = fPadTo16Bit(pixels_out[(1*COMP_WIDTH)-1 -:COMP_WIDTH]);
                $fwrite(f, "%c", out_component[7:0]); // Little-Endian
                $fwrite(f, "%c", out_component[15:8]);
                out_component = fPadTo16Bit(pixels_out[(2*COMP_WIDTH)-1 -:COMP_WIDTH]);
                $fwrite(f, "%c", out_component[7:0]);
                $fwrite(f, "%c", out_component[15:8]);
                out_component = fPadTo16Bit(pixels_out[(3*COMP_WIDTH)-1 -:COMP_WIDTH]);
                $fwrite(f, "%c", out_component[7:0]);
                $fwrite(f, "%c", out_component[15:8]);
            end
        end
        $fclose(f);
    endfunction : fWriteRawFrame

    //-----------------------------------------------------------
    // Returns component value padded to 16-bits. The component is placed in the MSBs.
    //      component: component value in frame's component bit depth
    //
    //      returns: component with padding added to LSBs to reach 16-bits
    //-----------------------------------------------------------
    function logic [15:0] fPadTo16Bit(logic [COMP_WIDTH-1:0] component);
        logic [15:0] tmp;

        tmp[15 -:COMP_WIDTH] = component;

        return tmp;
    endfunction : fPadTo16Bit

    //-----------------------------------------------------------
    // Read raw pixel data from file
    //      filename: filename to read
    //
    //      Pixels are read consecutively from top-left to bottom-right.
    //      Components are read RGB or YCC with 16 bits per component.
    //      Little-endian byte ordering is used.
    //      The size of the raw data is assumed to match the frame's configured dimensions.
    //-----------------------------------------------------------
    function void fReadRawFrame(string filename);
        integer f, row, col;

        logic [15:0] pixel;
        logic [7:0] pixel_r[2];

        f = $fopen(filename, "rb");
        assert (f!=0) else $fatal(0, $sformatf("Unable to open image file %s", filename));


        for(row = 0; row < height; row++)
        begin
            for(col = 0; col < width; col++)
            begin
                void'($fread(pixel_r, f));
                pixel[7:0] = pixel_r[0];
                pixel[15:8] = pixel_r[1];
                pixels[row*width+col][(1*COMP_WIDTH)-1 -:COMP_WIDTH]  = pixel[15 -:COMP_WIDTH];

                void'($fread(pixel_r, f));
                pixel[7:0] = pixel_r[0];
                pixel[15:8] = pixel_r[1];
                pixels[row*width+col][(2*COMP_WIDTH)-1 -:COMP_WIDTH]  = pixel[15 -:COMP_WIDTH];

                void'($fread(pixel_r, f));
                pixel[7:0] = pixel_r[0];
                pixel[15:8] = pixel_r[1];
                pixels[row*width+col][(3*COMP_WIDTH)-1 -:COMP_WIDTH]  = pixel[15 -:COMP_WIDTH];
            end
        end
        $fclose(f);

        this.fSubsampleFrame(); // Subsamples chroma if necessary
    endfunction : fReadRawFrame

    //-----------------------------------------------------------
    // Instantiates new video_frame with pixel components that are incremented consecutively
    //      width: test frame width
    //      height: test frame height
    //      video_format: colourspace and subsampling
    //
    //      returns: new video frame
    //
    //      Each pixel's components are incremented by a constant with respect to the previous pixel's
    //      corresponding components. The constant is the components index starting with 1.
    //      (r,g,b): (0,0,0), (1,2,3), (2,4,6), (3,6,9), etc
    //-----------------------------------------------------------
    static function video_frame#(COMP_WIDTH) fMakeCounterFrame (
        int width,
        int height,
        eVideoFormat video_format
    );
        logic [COMP_WIDTH-1:0] comp_cntr [NUM_COMPONENTS];
        automatic video_frame#(COMP_WIDTH) tmp = new(width, height, video_format);
        int row, col, comp;

        comp_cntr[0] = '0;
        comp_cntr[1] = '0;
        comp_cntr[2] = '0;

        for (row = 0; row < height; row++)
        begin
            for(col = 0; col < width; col++ )
            begin
                for (comp = 1; comp <= NUM_COMPONENTS; comp++)
                begin
                    tmp.pixels[row*width + col][comp*COMP_WIDTH-1 -: COMP_WIDTH] = comp_cntr[comp-1];
                    comp_cntr[comp-1] += comp;
                end
            end
        end

        tmp.fSubsampleFrame(); // Apply any necessary chroma subsampling
        return tmp;
    endfunction : fMakeCounterFrame

    //-----------------------------------------------------------
    // Instantiates new video_frame with colour bar pattern
    //      width: test frame width
    //      height: test frame height
    //      video_format: colourspace and subsampling
    //
    //      returns: new video frame
    //
    //      Similar to an SMPTE colour bar pattern.
    //-----------------------------------------------------------
    static function video_frame#(COMP_WIDTH) fMakeColourBar (
        int width,
        int height, 
        eVideoFormat video_format
    );
        logic [15:0] colour_bar_pattern [7][3];
        automatic video_frame#(COMP_WIDTH) tmp = new(width, height, video_format);
        int row,col,comp;
        int bar_index;
        int bar_width = width / 7;

        if (video_format == VIDEO_FORMAT_RGB)
        begin
            colour_bar_pattern[0] = {16'd49151, 16'd49151, 16'd49151}; 
            colour_bar_pattern[1] = {16'd49151, 16'd49151, 16'd0}; 
            colour_bar_pattern[2] = {16'd0, 16'd49151, 16'd49151}; 
            colour_bar_pattern[3] = {16'd0, 16'd49151, 16'd0}; 
            colour_bar_pattern[4] = {16'd49151, 16'd0, 16'd49151}; 
            colour_bar_pattern[5] = {16'd49151, 16'd0, 16'd0}; 
            colour_bar_pattern[6] = {16'd0, 16'd0, 16'd49151}; 
        end
        else // All other video formats are YCC variants
        begin
            colour_bar_pattern[0] = {16'hB4B4, 16'h8080, 16'h8080}; 
            colour_bar_pattern[1] = {16'hA200, 16'h2C00, 16'h8E00}; 
            colour_bar_pattern[2] = {16'h8300, 16'h9C00, 16'h2C00}; 
            colour_bar_pattern[3] = {16'h7000, 16'h4800, 16'h3A00}; 
            colour_bar_pattern[4] = {16'h5400, 16'h8C00, 16'hC600}; 
            colour_bar_pattern[5] = {16'h4100, 16'h6400, 16'hD400}; 
            colour_bar_pattern[6] = {16'h2300, 16'hD400, 16'h7200}; 
        end

        for (row = 0; row < height; row++)
        begin
            for (col = 0; col < width; col++)
            begin
                for (comp = 0; comp < NUM_COMPONENTS; comp++)
                begin
                    // 7 different bars so divide width evenly
                    bar_index = ((col / bar_width) >= 7) ? 6 : col / bar_width;

                    if ((row / (height / 3)) >= 1)  // Divide height into thirds and shift bars by 1
                        bar_index = (bar_index) == 6 ? 0 : bar_index+1;
                    if ((row / (height / 3)) >= 2)
                        bar_index = (bar_index) == 6 ? 0 : bar_index+1;
                        
                    tmp.pixels[row*width + col][(comp+1)*COMP_WIDTH-1 -: COMP_WIDTH] =
                        colour_bar_pattern[bar_index][comp][15 -: COMP_WIDTH];
                end
            end
        end

        tmp.fSubsampleFrame(); // Apply any necessary chroma subsampling
        return tmp;
    endfunction : fMakeColourBar

    //-----------------------------------------------------------
    // Reduces effective chroma resolution by copying redundant colour information from
    // previous row and/or column.
    //
    //  eg. 422
    //  {123, 456} -> {123, 423}
    //  {789, abc} -> {789, a89}
    //-----------------------------------------------------------
    function void fSubsampleFrame();
        int row, col;

        if (video_format == VIDEO_FORMAT_YCC422 || video_format == VIDEO_FORMAT_YCC420)
        begin
            for (row = 0; row < height; row++)
            begin
                for (col = 0; col < width; col++)
                begin
                    if ((col % 2) != 0)
                    begin
                        // Copy chroma from previous column
                        pixels[row*width + col][PIX_WIDTH-1 -:2*COMP_WIDTH] = pixels[row*width + col - 1][PIX_WIDTH-1 -:2*COMP_WIDTH];
                    end
                end
            end
        end
        if (video_format == VIDEO_FORMAT_YCC420)
        begin
            for (col = 0; col < width; col++)
            begin
                for (row = 0; row < height; row++)
                begin
                    if ((row % 2) != 0)
                    begin
                        // Copy chroma from previous row
                        pixels[row*width + col][PIX_WIDTH-1 -:2*COMP_WIDTH] = pixels[(row-1)*width + col][PIX_WIDTH-1 -:2*COMP_WIDTH];
                    end
                end
            end
        end
    endfunction : fSubsampleFrame
endclass : video_frame

endpackage : video_bfm_pkg
