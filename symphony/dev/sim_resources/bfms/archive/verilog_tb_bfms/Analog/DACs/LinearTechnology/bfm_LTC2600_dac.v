//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_LTC2600.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : April 26, 2012
//--------------------------------------------------------------------
//Description : BFM and Monitor for LTC2600 series Octal DAC
//   - i_enable          --> used to disable BFM if desired
//   - o_sdo output only applicable for 32bit transfers (24bit transfer ignores o_sdo)
//                            
// datasheet: http://www.linear.com/product/LTC2620
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2012-08-03 15:06:14 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

  module bfm_LTC2600
   #( parameter BFM_NAME                  = "bfm_LTC2600 ",
      //<> NOTE: Parameters below are Device Specific from Datasheet...
      parameter MODE_32BIT                = 1,     // 1=32bit transfer mode (SDO), 0=24bit transfer mode (no SDO)
      parameter NUM_CONV_BITS             = 16,    // number of total possible databits serial output string (From datasheet)
      parameter NUM_VALID_DATA_BITS       = 12,    // LTC2600=16, LTC2610=14, LTC2620=12, 
      parameter NUM_CMD_BITS              = 4,
      parameter NUM_ADDR_BITS             = 4
   )
   (
      //<> DUT interface
      input wire  i_clr_n ,     // DAC async clear
      input wire  i_sclk ,      // serial transfer clock
      input wire  i_cs_n ,      // serial transfer enable
      input wire  i_sdi ,       // serial data in 
      output reg  o_sdo ,       // serial data in 
      //<> testbench interface
      input wire                            i_enable ,               // testbench monitor enable control
      output reg [NUM_CMD_BITS-1:0]         ctrl_code ,              // buffer for command
      output reg [NUM_ADDR_BITS-1:0]        addr_code ,              // buffer for address
      output reg [NUM_CONV_BITS-1:0]        full_data_word ,         // buffer for full data word
      output reg [(NUM_CMD_BITS+NUM_ADDR_BITS)-1:0] full_inst_word   // buffer for full instruction word
   );
   
//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS 
//<> ------------------------------------------------------------
   localparam NUM_PREFIX_BITS = 8;                       // <fixed> Only used in 32bit transfer mode
   localparam NUM_INST_BITS   = (NUM_CMD_BITS + NUM_ADDR_BITS);  
   localparam FDAC_FRAME_SIZE = 32;                      // fixed frame size
                                 // (  NUM_INST_BITS
                                 // + NUM_CONV_BITS );      // calculate # bits in a full data frame
   localparam NUM_X_DATA_BITS = (NUM_CONV_BITS - NUM_VALID_DATA_BITS);  // calculate # of trailing unused "don't care" bits in data op
   localparam MIN_FRAME_SIZE  = 24;
   localparam MAX_FRAME_SIZE  = FDAC_FRAME_SIZE;

   //<> timing specs  (from datasheet)
   localparam  ts_Dsu    = 4 ;        // data setup to SCLK rising (From datasheet)
   localparam  ts_Dhld   = 4;       // data hold from SCLK rising (From datasheet)

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   integer frame_cntr = 0;
   integer fptr = 0;     // shift register index pointer
   string  msg ;
   reg frame_good = 0;  // flag indicating a valid frame size recieved
   reg [FDAC_FRAME_SIZE-1:0] sdin_frame      = 0;    // full serial data chain
   reg [FDAC_FRAME_SIZE-1:0] sdin_frame_prev = 0;    // previous full serial data chain
   reg su_flag  = 0;
   reg hld_flag = 0;

   event Start_Of_Frame;
   event End_Of_Frame;
   event Frame_Process_Start;
   event Frame_Check_Done;
   
//<> ------------------------------------------------------------
//<> INPUT PARSER
//<> ------------------------------------------------------------
   
   
   
   //<> ------------------------------------------------------------
   //<> watch for start of Frame event and trigger interal Event 
   //<>  - end of frame assumed to be rising edge of i_cs_n
   always @(negedge i_cs_n) -> Start_Of_Frame;    // trigger internal event on end of frame condition
   
   
   //<> ------------------------------------------------------------
   //<> Perform serial data input capture
   //<>  - pointer counter controlled by i_chipselect for frame size checks 
   always 
   begin
      if (i_clr_n == 1'b0) begin
         sdin_frame = 0;
         #1;                                                           // Avoid simulator lockup
      end 
      else begin
         @(Start_Of_Frame);
         for (fptr=0; i_cs_n == 1'b0; fptr=fptr+1)  begin              // vector index for output counts from MSbit -> LSbit  (count based from '1' for stop on zero)
            @(posedge i_sclk) 
               sdin_frame = {sdin_frame[FDAC_FRAME_SIZE-2:0], i_sdi};  // Shiftleft (data in MSbit first)
         end
         ->End_Of_Frame;                                               // i_cs_n now gone high, so signal end_of_frame reached
      end
   end

   //<> ------------------------------------------------------------
   //<> Perform serial data output of previous input frame 
   //><  -NOTE: only applicable for 32bit transfers (24bit transfer ignores SDO)
   always 
   begin
      if (i_clr_n == 1'b0) begin
         sdin_frame_prev = 0;
         #1;                                                                  // Avoid simulator lockup
      end 
      else begin
         wait (i_cs_n == 1'b0);                                               // Delay until chipselect negative edge detected
         @(negedge i_sclk) 
            o_sdo = sdin_frame_prev[FDAC_FRAME_SIZE-1];                       // output data MSbit first
         @(posedge i_sclk) 
            sdin_frame_prev = {sdin_frame_prev[FDAC_FRAME_SIZE-2:0], i_sdi};  // Shiftleft (destructive)
      end
   end

   
   
   //<> ------------------------------------------------------------
   //<> parse input frame at chipselect DEAssertion time
   always @(End_Of_Frame) 
   begin
      //<> confirm valid cycle event
      if ((fptr != (MIN_FRAME_SIZE-1)) | (fptr != (MAX_FRAME_SIZE-1))) begin  // bad frame size detected
         frame_good = 0;                                                      // indicate bad frame length of some sort
         if (fptr > (MAX_FRAME_SIZE-1)) begin                                 // --> outside upper frame size bounds
            `SIM.printError(BFM_NAME, "serial write fault detected - Frame too long");
         end
         else begin                                                           // inbetween or undersized
            if (fptr > (MIN_FRAME_SIZE-1)) begin                              // --> under minimum frame size 
               `SIM.printError(BFM_NAME, "serial write fault detected - Frame too short");
            end
            else begin                                                        // in-between limits
               `SIM.printError(BFM_NAME, "serial write fault detected - Frame between valid upper/lower size limits");
            end
         end
      end
      else begin                                                              // frame size good
         frame_good = 1;                                                      // indicate the frame has a valid length
         if (i_enable) begin
            `SIM.printMessage(BFM_NAME, {"SPI xfer recieved ==> cmd= ", `V2HEXSTR(ctrl_code),", addr= ", `V2HEXSTR(addr_code), ", data= ", `V2HEXSTR(full_data_word) });
         end
      end
      ->Frame_Check_Done;
   end 
   
   //<> ------------------------------------------------------------
   //<> map received frame to component testcase fields at end of transfer
   //<>  - only performed once frame check is complete as it relies on framecheck results
   always @(Frame_Check_Done) 
   begin
      sdin_frame_prev = sdin_frame;    // bufffer current frame for next transfer output
      //<> map frame to testcase ports (ignores optional prefix)
      {ctrl_code, addr_code, full_data_word} = (frame_good) ? sdin_frame[MIN_FRAME_SIZE-1:0] : {MIN_FRAME_SIZE{1'bx}};
   end

//<> ------------------------------------------------------------
//<> INPUT TIMING CHECKS
//<> ------------------------------------------------------------   
   specify
      $setup(i_sdi, posedge i_sclk, ts_Dsu, su_flag);
      $hold(posedge i_sclk, i_sdi, ts_Dsu, hld_flag);
   endspecify
   
   always @(su_flag)  `SIM.printError(BFM_NAME, "Data setup timing violation detected. " );
   always @(hld_flag) `SIM.printError(BFM_NAME, "Data hold timing violation detected. " );
   
endmodule

//* -----------------------------Instance template--------------------------------
//  --------------------------------*-----------------------------------
   // //<>--------------------------------------------------------------------
   // //<> LTC2620 BFM 
   // //<>
   // bfm_LTC2600
      // #( .BFM_NAME                  ("bfm_LTC2600 "),
         // //<> NOTE: Parameters below are Device Specific from Datasheet...
         // .MODE_32BIT                (1),    // 1=32bit transfer mode (SDO), 0=24bit transfer mode (no SDO)
         // .NUM_CONV_BITS             (16),    // number of total possible databits serial output string (From datasheet)
         // .NUM_VALID_DATA_BITS       (12),    // LTC2600=16, LTC2610=14, LTC2620=12, 
         // .NUM_CMD_BITS              (4),
         // .NUM_ADDR_BITS             (4)
      // ) bfm_LTC2600_inst
      // (
         // //<> DUT interface
         // .i_clr_n  (),      // serial transfer clock
         // .i_sclk  (),      // serial transfer clock
         // .i_cs_n  (),      // serial transfer enable
         // .i_sdi   (),       // serial data in 
         // .o_sdo   (),       // serial data in 
         // //<> testbench interface
         // .i_enable      (),       // testbench monitor enable control
         // .ctrl_code     (),      // buffer for command [NUM_CMD_BITS-1:0]
         // .addr_code     (),      // buffer for address [NUM_ADDR_BITS-1:0]
         // .full_data_word(), // buffer for full data word [NUM_CONV_BITS-1:0]
         // .full_inst_word(),   // buffer for full instruction word [(NUM_CMD_BITS+NUM_ADDR_BITS)-1:0]
      // );