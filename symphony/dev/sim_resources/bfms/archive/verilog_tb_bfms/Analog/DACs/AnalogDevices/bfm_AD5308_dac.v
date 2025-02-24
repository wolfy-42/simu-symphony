//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_AD5308.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : April 26, 2012
//--------------------------------------------------------------------
//Description : BFM and Monitor for AD_5308 Octal DAC
//    i_enable          --> used to disable BFM if desired
//
// datasheet: http://www.analog.com/en/digital-to-analog-converters/da-converters/ad5308/products/product.html
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.10 $    $Date: 2012-06-13 09:55:33 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

  module bfm_AD5308
   #( parameter BFM_NAME                  = "bfm_AD5308 ",
      //<> NOTE: Parameters below are Device Specific from Datasheet...
      parameter NUM_VALID_DATA_BITS       = 8,
      parameter NUM_CONV_BITS             = 12,             // number of total possible databits serial output string (From datasheet)
      parameter NUM_MODE_BITS             = 1,
      parameter NUM_CTRL_BITS             = 2,
      parameter NUM_INST_BITS             = 13,
      parameter NUM_ADDR_BITS             = 3
   )
   (
      //<> DUT connections
      input wire  i_sclk ,      // serial transfer clock
      input wire  i_sync_n ,    // serial transfer enable
      input wire  i_sdin ,      // serial data in
      input wire  i_ldac_n,     // DAC Load control
      //<> testbench inputs
      input wire  i_enable ,                                 // testbench monitor enable control
      output reg [NUM_CTRL_BITS-1:0]        ctrl_code ,      // buffer for command
      output reg [NUM_ADDR_BITS-1:0]        addr_code ,      // buffer for address
      output reg [NUM_CONV_BITS-1:0]        full_data_word , // buffer for full data word
      output reg [NUM_INST_BITS-1:0]        full_inst_word   // buffer for full instruction word
   );

//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS
//<> ------------------------------------------------------------
   localparam FDAC_FRAME_SIZE = (  NUM_MODE_BITS
                                 + NUM_ADDR_BITS
                                 + NUM_CONV_BITS );    // calculate # bits in a full data frame
   localparam NUM_X_DATA_BITS = (NUM_CONV_BITS - NUM_VALID_DATA_BITS);  // calculate # of trailing unused "don't care" bits in data op

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   integer frame_cntr = 0;
   integer fptr = 0;                            // shift register index pointer
   reg [FDAC_FRAME_SIZE-1:0] sdin_frame = 0;    // full serial data chain
   reg [NUM_MODE_BITS-1:0]   mode;              // buffer for prefix
   string  msg;

//<> ------------------------------------------------------------
//<> INPUT PARSER
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> Perform serial data input capture
   //<>  - pointer counter controlled by i_sync for frame size checks
   always
   begin
      wait (i_sync_n == 1'b0);  // Delay until sync negative edge detected
      for (fptr=FDAC_FRAME_SIZE; i_sync_n == 1'b0; fptr=fptr-1)  begin  // vector index for output counts from MSbit -> LSbit  (count based from '1' for stop on zero)
         @(negedge i_sclk)
            sdin_frame[fptr-1] <= i_sdin;  // capture data from port (index adjusted to match vector range)
      end
   end

   //<> ------------------------------------------------------------
   //<> map received frame to component fields
   always @(posedge i_sync_n)
   begin
      mode = sdin_frame[FDAC_FRAME_SIZE-1];
      {addr_code, full_data_word} = (sdin_frame[FDAC_FRAME_SIZE-1] == 1'b0) ? sdin_frame[FDAC_FRAME_SIZE-2:0] : {(NUM_ADDR_BITS + NUM_CONV_BITS){1'bx}};
      {ctrl_code, full_inst_word} = (sdin_frame[FDAC_FRAME_SIZE-1] == 1'b1) ? sdin_frame[FDAC_FRAME_SIZE-2:0] : {(NUM_CTRL_BITS + NUM_INST_BITS){1'bx}};
   end


   //<> ------------------------------------------------------------
   //<> parse input frame at sync DEAssertion time
   always @(posedge i_sync_n)
   begin
      #1;    // delay to avoid sync|clk race
      //<> confirm valid cycle event
      if (fptr != 0) begin
         if (fptr > 0) begin
            `SIM.printError(BFM_NAME, "serial write fault detected - Frame too short");
         end
         else begin  // --> negative fptr value
            `SIM.printError(BFM_NAME, "serial write fault detected - Frame too long");
         end
      end
      else begin
         if (i_enable)
            `SIM.printMessage(BFM_NAME, {"SPI xfer recieved ==> cmd= ", `V2HEXSTR(ctrl_code),", addr= ", `V2HEXSTR(addr_code), ", data= ", `V2HEXSTR(full_data_word) });
      end
   end

//<> ------------------------------------------------------------
//<> INPUT TIMING CHECKS
//<> ------------------------------------------------------------

   //<> timing specs  (from datasheet)
   localparam  ts_Dsu    = 5 ;        // data setup to SCLK falling (From datasheet)
   localparam  ts_Dhld   = 4.5;       // data hold from SCLK falling (From datasheet)
   reg su_flag, hld_flag = 0;

   specify
      $setup(i_sdin, negedge i_sclk, ts_Dsu, su_flag);
      $hold(negedge i_sclk, i_sdin, ts_Dsu, hld_flag);
   endspecify

   always @(su_flag)  `SIM.printError(BFM_NAME, "Data setup timing violation detected. " );
   always @(hld_flag) `SIM.printError(BFM_NAME, "Data hold timing violation detected. " );

endmodule

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:

 // bfm_AD5308
   // #( .BFM_NAME                  ("bfm_AD5308 "),
      // //<> NOTE: Parameters below are Device Specific from Datasheet...
      // .NUM_VALID_DATA_BITS       (8),
      // .NUM_CONV_BITS             (12),    // number of total possible databits serial output string (From datasheet)
      // .NUM_MODE_BITS             (1),
      // .NUM_CTRL_BITS             (2),
      // .NUM_INST_BITS             (13),
      // .NUM_ADDR_BITS             (3)
   // ) bfm_AD5308_inst
   // (  .i_sclk           (),    // serial transfer clock
      // .i_sync_n         (),    // serial transfer enable
      // .i_sdin           (),    // serial data in
      // .i_ldac_n         (),    // DAC Load control          << RFU ? - TBD >>
      // //<> testbench inputs
      // .i_enable         (),    // testbench monitor enable control
      // .ctrl_code        (),       // [NUM_CTRL_BITS-1:0]   buffer for command
      // .addr_code        (),       // [NUM_ADDR_BITS-1:0]   buffer for address
      // .full_data_word   (), // [NUM_CONV_BITS-1:0]   buffer for full data word
      // .full_inst_word   (), // [NUM_INST_BITS-1:0]   buffer for full instruction word
   // );