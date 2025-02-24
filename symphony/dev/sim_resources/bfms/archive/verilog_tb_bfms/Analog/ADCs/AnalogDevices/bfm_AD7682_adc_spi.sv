//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_AD7682.sv
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : Jan 17, 2014
//--------------------------------------------------------------------
//Description : Multichannel ADC BFM based on specifications for Analog AD7682 device
//    - assumes gated SPI clock input (active only during sync_csn = LOW)
//    - i_enable          --> used to disable BFM messages (but not error/warning) if desired
//
// Note: Internal Tempsensor and Config output current unsupported - <<TBD>>
//
// Note: relies on System-Verilog syntax to enable 2D array ports
// datasheet:
//--------------------------------------------------------------------
//ChangeLog :
//  Oct 15,2015   - fix error with data capture...now output on N+2 spi cycles from request rather than N+1
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.7 $    $Date: 2014-02-04 16:46:58 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`ifndef SIM
   `define SIM tb.sim_management_inst
`endif

  module bfm_AD7682
   #( parameter BFM_NAME                  = "bfm_AD7682",
      //<> NOTE: Parameters below are Device Specific from Datasheet...do not alter (included for port-width clarity)
      parameter NUM_CHANNELS              = 4,     // number of data channels of analog input
      parameter NUM_CONV_BITS             = 16,    // number of total possible databits serial output string (From datasheet)
      parameter NUM_CMD_BITS              = 14
   )
   (
      //<> DUT interface
      input wire  i_rst ,       // async clear
      input wire  i_sclk ,      // serial transfer clock
      input wire  i_sync_csn ,  // serial transfer enable/operation sync
      input wire  i_sdi ,       // serial data in
      output reg  o_sdo ,       // serial data out
      //<> "analog" inputs
      input wire [31:0]  i_data_port [NUM_CHANNELS-1:0],
      //<> testbench interface
      input wire                                       i_enable ,       // testbench monitor enable control
      output reg [NUM_CMD_BITS-1:0]                    o_ctrl_code ,    // buffer for command
      output reg [(NUM_CONV_BITS + NUM_CMD_BITS)-1:0]  o_out_frame      // buffer for full data word
   );

   //<> ------------------------------------------------------------
   //<> local parameter/constants
   localparam NUM_PREFIX_BITS     = 8;                       // <fixed> Only used in 32bit transfer mode
   localparam MIN_OUT_FRAME_SIZE  = NUM_CONV_BITS;
   localparam OUT_FRAME_SIZE      = (NUM_CONV_BITS + NUM_CMD_BITS);
   localparam UPPER_RANGE_LIMIT   = (2**NUM_CONV_BITS)-1;    // uppermost input value supported by digitization bit range

   //<> timing specs  (from datasheet)
   localparam  ts_DOUT   = 22;      // (ns) CLK/CSN active edge to output data valid (From datasheet)
   localparam  ts_Dsu    = 5;       // (ns) data setup to SCLK rising (From datasheet)
   localparam  ts_Dhld   = 5;       // (ns) data hold from SCLK rising (From datasheet)

   //<> ------------------------------------------------------------
   //<> internal BFM variables
   integer fptr = NUM_CMD_BITS;                         // shift register index pointer input SPI
   integer optr = 0;                                    // shift register index pointer output SPI

   reg [NUM_CMD_BITS-1:0]   in_frame       = 0;         // full serial data chain
   reg [OUT_FRAME_SIZE-1:0] next_sdo_frame = 0;         // previous full serial data chain
   reg [31:0]               temp_data      = 0;         // data aquired  cycle N
   reg [31:0]               aquire_data    = 0;         // data aquired  cycle N+1
   reg [31:0]               conv_data      = 0;         // data output   cycle N+2
   reg [NUM_CONV_BITS-1:0]  next_dout      = 0;
   reg [1:0]                chan_sel       = 2'b00 ;

   reg frame_good = 0;           // flag indicating a valid frame size recieved
   reg su_flag, hld_flag;

   //<> structure for the configuration register contents field visibility
   struct packed {   reg       cfg;    // config 0=keep, 1=overwrite
                     reg [2:0] incc;
                     reg       unused; // INX[2] is "don't care"
                     reg [1:0] inx;    // input channel select
                     reg       bw;
                     reg [2:0] refer;
                     reg [1:0] seq;
                     reg       rb;
                  } config_reg;

   //<> SPI flow event strobes
   event Start_Of_Frame;
   event Start_Conv_Cycle;
   event New_Config_Frame;
   event Frame_Process_Start;
   event Frame_Check_Done;

   initial begin:InitPortValueBlk
      o_out_frame = 0;
      o_ctrl_code = 0;
      o_sdo       = 1'b0;
   end

//<> ------------------------------------------------------------------------------------------------------------------------
//<> SPI INterface
//<> ------------------------------------------------------------------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> SPI TRANSACTION START/END EVENTS
   //<> watch for start of Frame event and trigger interal Event
   //<>  - end of frame assumed to be rising edge of i_sync_csn
   //<> ------------------------------------------------------------
   initial begin  // <delay controled freeflow block>
      #10;                                           // pad for simulation TB signal startup initialization
      while (1) begin
         @(negedge i_sync_csn) -> Start_Of_Frame;    // trigger internal event on start of frame condition
      end
   end

   initial begin // <delay controled freeflow block>
      #10;                                             // pad for simulation TB signal startup initialization
      while (1) begin
         @(posedge i_sync_csn) -> Start_Conv_Cycle;    // trigger internal event on end of frame condition
      end
   end


//<> ------------------------------------------------------------
//<> SPI INPUT CAPTURE
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> Perform serial data input capture
   //<>  - pointer counter controlled by i_chipselect for frame size checks
   //<>  - fork used to avoid negedge event lockup between frames that would prevent fptr clearing
   always begin  // <delay controled freeflow block>
      if (i_rst) begin
         in_frame = 0;
         fptr = NUM_CMD_BITS;
         #1;                     // Avoid simulator lockup
      end
      else begin
         @(Start_Of_Frame);
         frame_good = 1'b0;      // clear for new frame
         fptr = NUM_CMD_BITS;    // initialize with +2 to correct for increment and array index offsets
      end
   end

   //<> ------------------------------------------------------------
   //<> frame pointer adjust and input latch to internal frame
   always @(posedge i_sclk)
   begin
      if(i_sync_csn == 1'b0) begin      // avoid free-running clock conflicts
         if (fptr > 0) begin            // prevent pointer underrun (negative) violation on long frames
            fptr = fptr - 1;            // decrement pointer
            in_frame[fptr] = i_sdi;     // latch data (in MSbit first)
         end
      end
   end

   //<> ------------------------------------------------------------
   //<> config frame index mark detection
   always @(negedge i_sclk)
   begin
      if(i_sync_csn == 1'b0) begin  // avoid free-running clock conflicts
         if (fptr == 0)             // last config bit latched ?
            ->New_Config_Frame;     //  signal new config frame ready
      end
   end


//<> ------------------------------------------------------------
//<> SPI OUTPUT DRIVER
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<>  - Perform serial data output of analog data, and previous CFG input frame
   //<>  - NOTE: only applicable for 32bit transfers (24bit transfer ignores SDO)
   always begin  // <delay controled freeflow block>
      if (i_rst) begin
         next_sdo_frame = 0;
         o_out_frame = 0;
         #1;                  // 1ns delay to avoid simulator lockup by freewheeling
      end
      else begin
         @(Start_Of_Frame);  // wait until chipselect negative edge detected
         optr = OUT_FRAME_SIZE;
      end
   end

   //<> ------------------------------------------------------------
   //<> frame pointer adjust and input latch to internal frame
   //<> - also triggered on falling chipselect to ensure first bit always presented
   always @(negedge i_sclk or negedge i_sync_csn)
   begin
      if (i_sync_csn == 1'b0) begin                            // avoids free-running clock conflicts
         o_sdo = #(ts_DOUT) next_sdo_frame[OUT_FRAME_SIZE-1];  // output MSbit after datasheet delay
      end
   end

   //<> ------------------------------------------------------------
   //<> output only while selected
   always @(posedge i_sclk)
   begin
      if(i_sync_csn == 1'b0) begin                                      // avoids free-running clock conflicts. only shift when selected
         next_sdo_frame = {next_sdo_frame[OUT_FRAME_SIZE-2:0], 1'b0};   // left shift by one
      end
   end


   //<> ------------------------------------------------------------
   //<> SPI FRAME CHECK
   //<>  - parse input frame at chipselect DEAssertion time
   //<> ------------------------------------------------------------
   always @(New_Config_Frame)
   begin
      //<> confirm valid cycle event
      if (fptr > 0) begin     // if under minimum frame size ...
         `SIM.printError(BFM_NAME, "serial write fault detected - Frame too short");
      end
      else begin              // if frame size good ...
         frame_good = 1'b1;   // indicate the frame has a valid length
         if (i_enable) `SIM.printMessage(BFM_NAME, {"SPI xfer recieved ==> cmd= ", `V2HEXSTR(o_ctrl_code) });
      end
      ->Frame_Check_Done;
   end

   //<> ------------------------------------------------------------
   //<> CONFIG SPI FRAME DECODE
   //<>  - Parse received Config frame into component function fields at end of transfer
   //<>  - only performed once frame check is complete as it relies on framecheck results
   //<>    to ensure no rogue command/operations from over/under-sized frames
   //<> ------------------------------------------------------------
   always @(New_Config_Frame)
   begin
      //<> map frame to testcase ports (ignores optional prefix)
      config_reg  = in_frame;
      o_ctrl_code = config_reg;     // copy config frame to port for testcase check access
      //<> pick off channel select command from frame (once full frame shifted in)
      chan_sel = config_reg.inx;    // pick off input channel selector for next aquisition cycle
   end

   //<> ------------------------------------------------------------
   //<> SPI BUS INPUT TIMING CHECKS
   specify
      $setup(i_sdi, posedge i_sclk, ts_Dsu, su_flag);
      $hold(posedge i_sclk, i_sdi, ts_Dsu, hld_flag);
   endspecify
      always @(su_flag)  `SIM.printError(BFM_NAME, "SPI Data in setup timing violation detected. " );
      always @(hld_flag) `SIM.printError(BFM_NAME, "SPI Data in hold timing violation detected. " );

//<> ------------------------------------------------------------------------------------------------------------------------
//<> <<Custom IO port operations go here>>
//<> ------------------------------------------------------------------------------------------------------------------------


   //<> ------------------------------------------------------------
   //<> CONVERSION Capture/output frame prep
   //<>  - Parse received Config frame into component function fields at end of transfer
   //<>  - Input integer value("voltage") is range limited to maximum value binary number with NUM_CONV_BITS
   always @(Start_Conv_Cycle)
   begin
      //<> data conversion emulation
      //******************* NEED TO EXPAND THIS SECTION TO ACCOMADATE TEMP SENSOR AND CONFIG OUTPUT SELECTION  *******************
      //<> temp sensor mode
         // <<TBD>>
      //<> config data output mode
         // <<TBD>>
      //<>  NOTE: this is implemented to warn when currently unsupported modes are attempted
      // if () `SIM.printWarning(BFM_NAME,{"<<UNSUPPORTED MODE>> DUT requested unsupported chan_sel=",`V2BINSTR(chan_sel)});
      //******************************************************************************************************************
      conv_data = aquire_data;                       // emulate conversion of previously N-1 latched data channel
      aquire_data = i_data_port[chan_sel];           // latch selected channel for SPI N transaction
      if (conv_data > UPPER_RANGE_LIMIT)             // check for out-of-range conversion
         next_dout = UPPER_RANGE_LIMIT;              // Input integer value("voltage") is over the upper range for the number of bits of digitization defined
      else
         next_dout = conv_data[NUM_CONV_BITS-1:0];   // capture "analog" integer data and typecast as binary of correct sample bit resolution
      //<> prep next N+1 SDO output frame
      next_sdo_frame = {next_dout, in_frame};        // frame for N+1 transaction shifting
      o_out_frame = {next_dout, in_frame};           // frame copy for N+1 transaction testcase status port
   end

endmodule

//* -----------------------------Instance template--------------------------------
//  --------------------------------*-----------------------------------
   // //<>--------------------------------------------------------------------
   // //<> LTC2620 BFM
   // //<>
   // bfm_AD7682
      // #( .BFM_NAME                  ("bfm_AD7682 "),
         // //<> NOTE: Parameters below are Device Specific from Datasheet...
         // .NUM_CHANNELS              (4),    // number of total possible databits serial output string (From datasheet)
         // .NUM_CONV_BITS             (16),
         // .NUM_CMD_BITS              (14)
      // ) bfm_AD7682_inst
      // (
         // //<> DUT interface
         // .i_rst        (),      // serial transfer clock
         // .i_sclk        (),      // serial transfer clock
         // .i_sync_csn    (),      // serial transfer enable
         // .i_sdi         (),       // serial data in
         // .o_sdo         (),       // serial data in
         // //<> "analog" inputs
         // .i_data_port   (),     // [NUM_CHANNELS-1:0]
         // //<> testbench interface
         // .i_enable      (),       // testbench monitor enable control
         // .o_ctrl_code     (),      // buffer for command          [NUM_CMD_BITS-1:0]
         // .o_out_frame     ()       // buffer for full data word   [(NUM_CONV_BITS + NUM_CMD_BITS)-1:0]
      // );