//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_LTC1407_adc_spi.v
//Project     : VIP
//Author      : Arnold Balisch
//Created     : April 21st, 2012
//--------------------------------------------------------------------
//Description : BFM and Monitor for LTC1407 ADC
//  - as per specification in Datasheet, SPI transactions output PREVIOUS 
//    sampled Channel inputs.
// NOTES:
//    i_enable          --> used to disable BFM if desired
//    i_a2d_value_ch0/1 --> inputs latched on rising edge of i_conv input, and 
//                          should be stable for one i_sclk period before and after.
//
// datasheet: http://www.linear.com/product/LTC1407
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2015-09-15 09:55:33 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

module bfm_LTC1407_adc_spi
   #( parameter BFM_NAME             = "bfm_LTC1407_adc_spi ",      // instance name for logfile message prefexing
      parameter NUM_VALID_DATA_BITS  = 12,                          // number of sample resolution (either 12 or 14)
      parameter NUM_PREFIX_BITS      = 2,                           // fixed do not change
      parameter NUM_SUFFIX_BITS      = 2,                           // fixed do not change
      parameter NO_WARN              = 0                            // suppress warning messages
   )
   (
      //<> Device SPI port
      input wire  i_sclk ,                                          // transfer clock
      input wire  i_conv ,                                          // conversion enable
      output reg  o_sdo  ,                                          // serial out shifter (POR default low)
      //<> testbench inputs
      input wire  i_enable ,                                        // testbench monitor enable control
      input wire [NUM_VALID_DATA_BITS-1:0]  i_a2d_value_ch0,        // CH0 value to output on SDO (2's complement)
      input wire [NUM_VALID_DATA_BITS-1:0]  i_a2d_value_ch1         // CH1 value to output on SDO (2's complement)
   );
   
   //<> ------------------------------------------------------------
   //<> Module local parameter/constants
   localparam CONV_ACT_LVL    = 1;                 // active level of conversion start strobe
   localparam NUM_CONV_BITS   = 14;                // number of databits in LTC1407 A/D conversion (From datasheet)
   localparam NUM_X_DATA_BITS = (NUM_CONV_BITS - NUM_VALID_DATA_BITS);
   localparam FADC_FRAME_SIZE = NUM_PREFIX_BITS 
                              + NUM_CONV_BITS  
                              + NUM_PREFIX_BITS 
                              + NUM_CONV_BITS  
                              + NUM_SUFFIX_BITS;    // calculate # bits in a full frame
   
   //<> timing specs 
   localparam ts_CLK2OUT = 8;    // delay (ns) from SCLK rising edge to SDO data out valid (From datasheet, timing spec "T8")

   //<> ------------------------------------------------------------
   //<> internal BFM variables
   integer frame_cntr = 0;
   integer i;     // shift register index pointer
   string msg ;
   reg [NUM_VALID_DATA_BITS-1:0] ch0_word; 
   reg [NUM_VALID_DATA_BITS-1:0] ch1_word; 
   reg [NUM_VALID_DATA_BITS-1:0] ch0_word_prev; 
   reg [NUM_VALID_DATA_BITS-1:0] ch1_word_prev; 
   reg [FADC_FRAME_SIZE-1:0] sdo_frame;
   reg [FADC_FRAME_SIZE-1:0] sdo_buffer;
   
   //<> ------------------------------------------------------------
   //<> OUTPUT GENERATOR
   initial begin
      o_sdo  = 1'b0;
      ch0_word_prev = 0;
      ch1_word_prev = 0;
   end   
                     
   //<> ------------------------------------------------------------
   //<> build output frame (with datasheet sample delay)
   always @(posedge i_conv) 
   begin
      ch0_word  = ch0_word_prev;           // latch previous input values for output on *current* SPI transaction
      ch1_word  = ch1_word_prev;
      ch0_word_prev  = i_a2d_value_ch0;    // latch current input values for output on *next* SPI transaction
      ch1_word_prev  = i_a2d_value_ch1;
      //<> build up Frame structure based on scaling parameters and inputs
      sdo_frame = { {NUM_PREFIX_BITS      {1'bZ}},
                     ch0_word,                        // {NUM_VALID_DATA_BITS {1'b0}},
                     {NUM_X_DATA_BITS     {1'bX}},
                     {NUM_PREFIX_BITS     {1'bZ}},
                     ch1_word,                        // {NUM_VALID_DATA_BITS {1'b0}},
                     {NUM_X_DATA_BITS     {1'bX}},
                     {NUM_SUFFIX_BITS     {1'bZ}} 
                   };
      if (i_enable)
         `SIM.printMessage(BFM_NAME, {"Current Analog Inputs ==> ch0 value: ", `V2HEXSTR(ch0_word)," ch1 value: ", `V2HEXSTR(ch1_word)});
   end 

   //<> ------------------------------------------------------------
   //<> Perform data output on request
   always 
   begin
      wait (i_conv);
      for (i=FADC_FRAME_SIZE; i > 0; i=i-1)  begin  // vector index for output counts from MSbit -> LSbit  (count based from '1' for stop on zero)
         @(posedge i_sclk) 
            o_sdo = #ts_CLK2OUT sdo_frame[i-1];     // assert data onto port with propagation delay (index adjusted to vector range)
      end
   end
   
   
   //<> ------------------------------------------------------------
   //<> FRAME INPUT SIZE CHECKER

   //<>-------------------------------------------- 
   //<> Frame length determination
   always begin
      if (CONV_ACT_LVL == 1)
         @(posedge i_conv);
      else
         @(negedge i_conv);
      forever begin
         if (i_enable == 'b0) begin                 // Enable control
            frame_cntr = 0;                         // reset and hold counter at zero 
            #10;                                    // delay to avoid simulator lockup
         end
         else begin
            if (i_conv == CONV_ACT_LVL) begin       // reset SM if no spi_slave_A chipselect is active
               #1;                                  // delay clear to allow previous count value to be checked below
               frame_cntr = 0;
            end
            else begin
               frame_cntr = frame_cntr + 1; 
            end
            @(posedge i_sclk);                      // posedge capture
         end
      end
   end
   
   //<>-------------------------------------------- 
   //<> verify frame length verification by spacing of i_conv arrivial
   always begin
      @(frame_cntr > 0);                  // hold off checking until after the initial franesync and measurements are started
      forever begin
         if (i_enable == 'b0) begin       // Enable control
            #10;                          // simulator lockup prevention
         end
         else begin
            if (CONV_ACT_LVL == 1)        // wait for conversion event
               @(posedge i_conv);
            else
               @(negedge i_conv);
            if (frame_cntr < FADC_FRAME_SIZE-1) begin
               msg = {"undersized frame: recieved too few sclk pulses: ", `V2INTSTR(frame_cntr+1), ", expected: ", `V2INTSTR(FADC_FRAME_SIZE)};
               `SIM.printError(BFM_NAME, msg);
            end
            if (frame_cntr > FADC_FRAME_SIZE-1) begin
               msg = {"oversized frame: recieved ", `V2INTSTR(frame_cntr+1), " sclk pulses, expected  ",  `V2INTSTR(FADC_FRAME_SIZE)};
               if (!NO_WARN) `SIM.printWarning(BFM_NAME, msg);   //warning vs error as oversized is not a fault, and excess ignored.
            end
         end
      end
   end

endmodule

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:
 
 // bfm_LTC1407_adc_spi
   // #( .BFM_NAME             ("bfm_LTC1407_adc_spi "),
      // .NUM_VALID_DATA_BITS  (12),
      // .NUM_PREFIX_BITS      (2),
      // .NUM_SUFFIX_BITS      (2)
   // ) bfm_LTC1407_adc_spi_inst
   // (
      // .i_sclk  (),     // transfer clock
      // .i_conv  (),    // conversion enable
      // .o_sdo   (),    // serial out shifter
      // //testbench inputs
      // .i_enable   (),    // testbench monitor enable control
      // .i_a2d_value_ch0  (),     // [NUM_VALID_DATA_BITS-1:0]   CH0 value to output on SDO (2's complement)
      // .i_a2d_value_ch1  ()      // [NUM_VALID_DATA_BITS-1:0]   CH1 value to output on SDO (2's complement)
   // ); 