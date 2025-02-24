//-----------------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//-----------------------------------------------------------------------------
//File name   : bfm_ad7942.vhd
//Project     : VIP
//Author      : Arnold Balisch 
//Created     : June 25, 2012
//-----------------------------------------------------------------------------
//Description : Functional simulation model for ad7942 A2D converter
//    - VIO=3.3v
//    - CS Mode, 3-Wire, without Busy Indicator
//
// Included Function Calls:
//       - <none>
// 
// External Constants from "global_signals_pkg" used:
//       - <none>
// NOTES:
//    i_enable          //> used to disable BFM if desired
//
// datasheet : http://www.analog.com/static/imported-files/data_sheets/AD7942.pdf
//-----------------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2014-05-23 18:47:21 $
//-----------------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

module bfm_ad7942
   #( parameter BFM_NAME       = "bfm_ad7942",      // instance name for logfile message prefexing
      parameter SCK_PERIOD     = 29,                  // external SCK period (ns)
      parameter INSERT_UNCERTAINTY     = 1,                  // 1=sets SDO='z' for uncertain window within sck/datavalid setup&hold relationships; 0=keep sdo valid during uncertainty window
      parameter NUM_CONV_BITS  = 14                  // number of bits of sample resolution (datasheet defined)
   )
   (
      //<> Device SPI port
      input wire i_sck ,                     // transfer clock
      input wire i_cnv ,                     // conversion enable
      input wire i_sdi  ,    
      output reg o_sdo = 1'bz  ,                     // serial out shifter (POR default low)
      //<> testbench inputs
      input wire i_enable    ,                                      // testbench monitor enable control
      input wire [NUM_CONV_BITS-1:0] i_a2d_value   // value to output on SDO (2's complement)
   );

 
   //<> Module local parameter/constants
   localparam CONV_ACT_LVL    = 1'b0;               // active level of conversion strobe start of data output  (from datasheet)
   parameter FADC_FRAME_SIZE = NUM_CONV_BITS ;    // calculate # bits in a full frame

   //<> Timing contraints for ADC bfm_ad7942 (Vdd=4.0V, Vio=3.3v) - CS Mode 3-Wire without Busy Indicator
   parameter ts_CYC      = 5_000; 
   parameter ts_SSDICNV  = 30;    
   parameter ts_HSDICNV  = 0;
   parameter ts_CONV_MIN = 700;   
   parameter ts_CONV_MAX = 3_200; 
   parameter ts_EN       = 18;
   parameter ts_HSDO     = 5;
   parameter ts_DSDO     = 24;    //24 ns max   (was using 15ns)
   parameter ts_SCK_MIN  = 25;    //25 ns min
   parameter ts_SCKH     = 12;     // 12 ns min
   parameter ts_SCKL     = 12;     // 12 ns min
   parameter ts_DIS      = 25;

   
   //<> ////////////////////////////////////////////////////////////
   //<> internal BFM variables
   integer frame_cntr = 0;
   integer i ;     // shift register index pointer
   reg [NUM_CONV_BITS-1 : 0]   ch0_word   ; 
   reg [FADC_FRAME_SIZE-1 : 0] sdo_frame  ;
   reg [FADC_FRAME_SIZE-1 : 0] sdo_buffer ;
   
   event start_conv_cycle;
   event end_conv_cycle;
   
   //<> ////////////////////////////////////////////////////////////
   //<> OUTPUT GENERATOR
                     
   //<>--------------------------------------------------------
   //<> build output frame (with datasheet sample delay)
   always @(negedge i_cnv) 
   begin
      sdo_frame   = ch0_word ;         // copy *previous* conversion cycle analog input value to working register
      ch0_word    = i_a2d_value;       // latch new input values for output on *next* SPI transaction
      if (i_enable == 1'b1) begin
         `SIM.printMessage(BFM_NAME, {"Current Analog Input ==> ", `V2HEXSTR(ch0_word)});
      end
      ->start_conv_cycle;  // kick start of conversion processing after Testcase inputs captured
   end

   always @(posedge i_cnv)
   begin
      ->end_conv_cycle;
   end
   
   //<>--------------------------------------------------------
   //<> Perform SDO data output drive/timing
   always 
   begin
      @start_conv_cycle;
      #(ts_EN) o_sdo = sdo_frame[FADC_FRAME_SIZE-1];  // put first bit on bus
      for (i=FADC_FRAME_SIZE-1; i>0; i=i-1) begin  // vector index for output counts from MSbit -> LSbit  (count based from 1'b1 for stop on zero)
         if (i_cnv == 1'b0) begin     // check to ensure CSn has not deasserted early
            @(negedge i_sck);
            #(ts_HSDO);
            if(INSERT_UNCERTAINTY == 1) o_sdo = 1'bz;                     // render data value indeterminate after hold delay
            #(ts_DSDO-ts_HSDO) o_sdo = sdo_frame[i-1];     // assert new data after propagation delay (offset index for count by zero)
         end
         else 
            i = 0;  // force quit out of FOR loop
      end 
      if (i_cnv == 1'b1) #(SCK_PERIOD);                // ensure data steady for clock cycle (unless overriden by i_cnv below)
      #(ts_DSDO) o_sdo = 1'bz;  // tristate at end of frame output
   end
   
   always @(end_conv_cycle)
   begin
      #(ts_DIS) o_sdo = 1'bz; // ensure SDO is tristated after CSn deasserted (high) disable delay elapsed
   end
   
   //<> ////////////////////////////////////////////////////////////
   //<> FRAME CHECKERS

   //<>--------------------------------------------------------
   //<> verify mode of operation is "CSn moode 3-wire, no Busy"
   always
   begin
      @start_conv_cycle;
      @(posedge i_sck);
      if (i_sdi == 1'b0) begin
         //<> assert false report "ERROR: bfm_ad7942: Detect SDI not asserted when CNV is asserted." severity failure;
         `SIM.printError(BFM_NAME, "ERROR: bfm_ad7942: Detected SDI low on first SCLK posedge - wrong interface mode in use" );
      end   
   end

   //<>--------------------------------------------------------
   //<> Frame length determination
   always @(start_conv_cycle) 
   begin
      frame_cntr = 0;                         // reset counter to zero at start of new cycle
   end
   
   always 
   begin 
      @(posedge i_sck);                      // wait for posedge capture
      if (i_enable != 1'b0) begin                 // if not disabled....
            #1;                                  // delay clear to allow previous count value to be checked below
            frame_cntr = frame_cntr + 1;      // increment count value
      end
   end

   
   //<>--------------------------------------------------------
   //<> verify frame length verification by spacing of i_cnv arrivial
   always
   begin
      @end_conv_cycle;
      if (i_enable != 1'b0) begin         // if checker not disabled....
         if (frame_cntr < FADC_FRAME_SIZE) begin
            // `SIM.printError(BFM_NAME, {"Under-sized SPI frame: recieved too few sclk pulses: " , `V2INTSTR(frame_cntr)});
            `SIM.printWarning(BFM_NAME, {"Under-sized SPI frame: recieved too few sclk pulses: " , `V2INTSTR(frame_cntr)});
         end
         if (frame_cntr > FADC_FRAME_SIZE) begin
            // `SIM.printError(BFM_NAME, {"Over-sized SPI frame: recieved too many sclk pulses: " , `V2INTSTR(frame_cntr)});
            `SIM.printWarning(BFM_NAME, {"Over-sized SPI frame: recieved too many sclk pulses: " , `V2INTSTR(frame_cntr)});
         end
      end
   end


endmodule

//* ////////////////////////////-Outline////////////////////////////////
//  ////////////////////////////////*//////////////////////////////////-
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:
 // bfm_ad7942
   // #( .BFM_NAME       ("bfm_ad7942"),      // instance name for logfile message prefexing
      // .NUM_CONV_BITS  (14)                  // number of bits of sample resolution (datasheet defined)
   // )
   // (
      // //<> Device SPI port
      // .i_sck(),                     // transfer clock
      // .i_cnv(),                     // conversion enable
      // .i_sdi (),    
      // .o_sdo (),                     // serial out shifter (POR default low)
      // //<> testbench inputs
      // .i_enable    (),                                      // testbench monitor enable control
      // .i_a2d_value ()  // [NUM_CONV_BITS-1:0] value to output on SDO (2's complement)
   // );