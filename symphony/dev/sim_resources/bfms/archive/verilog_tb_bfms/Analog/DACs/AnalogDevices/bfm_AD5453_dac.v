// ----------------------------------------------------------------------
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
// File name   : bfm_AD5453_dac.vhd
// Project     : RIPL
// Author      : Arnold Balisch
// Created     : April 24,2012
// ----------------------------------------------------------------------
// Description : Functions and Procedures for bfm_AD5453 DAC
//     - this is an input only device...no readback hence no turnaround
//     - provides registered SPI transaction compliance
//     - sdo port echos previous recieved frame (or null on first access after reset)
// 
//  Included Function/procedure Calls:
//     - <none>
//  
//  <> April 23, 2012 - AGB - Ported to verilog from original VHDL 
//
// datasheet: http://www.analog.com/en/digital-to-analog-converters/da-converters/ad5453/products/product.html
// ----------------------------------------------------------------------
//  $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2014-06-09 14:56:48 $
// ----------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines


module bfm_AD5453_dac 
    #(parameter  INST_NAME_STRING    = "bfm_AD5453_dac",
      parameter  CS_ACT_LVL          = 1'b0,     // Active polarity of chipselect input
      parameter  NUM_CMD_BITS        = 2,        // # Command bits
      parameter  NUM_DATA_BITS       = 14,       // # data bits
      parameter  CS_DELAY            = 0,        // delay (ns) relative to i_sclk for board/primative compensation
      parameter  SDI_DELAY           = 0         // delay (ns) relative to i_sclk for board/primative compensation
      )
    (
      //<> DUT I/O
      input wire i_sclk ,
      input wire i_cs   ,
      input wire i_sdi  ,
      //<> testbench interfaces
      input wire i_rst  ,                         // board-level/power-on reset input (affects return value)
      output wire o_evnt  ,                       // irq flag indicating transaction detected
      output wire [NUM_CMD_BITS-1:0]  o_cmd ,     // data portion detected
      output wire [NUM_DATA_BITS-1:0] o_data      // data portion detected
   );

//<> ------------------------------------------------------------
//<> LOCAL CONSTANTS
//<> ------------------------------------------------------------
   localparam FRAME_CNT = NUM_CMD_BITS + NUM_DATA_BITS; // # bits for full frame
   //<> timing specs  (from datasheet)
   localparam  ts_Dsu  = 5.0;       // data setup to SCLK falling (From datasheet)
   localparam  ts_Dhld = 4.5;     // data hold from SCLK falling (From datasheet)
   
//<> ------------------------------------------------------------
//<> INTERNAL SIGNALS
//<> ------------------------------------------------------------
   reg [FRAME_CNT-1 : 0]   raw_frame_shft_in = 0 ;    // current frame being recieved
   reg [FRAME_CNT-1 : 0]   raw_frame_reg     = 0;     // buffer for previous frame recieved
   integer frame_cntr    = 0;
   reg su_flag, hld_flag = 0;
   reg i_cs_dly, i_sdi_dly;
   
//<> ------------------------------------------------------------
//<> MAIN INPUT PARSING
//<> ------------------------------------------------------------

   //<> Map input ports to internal signals with delay to compensate for DUT ODDR2 primative use
   always @(i_cs) 
   begin
      #(CS_DELAY) i_cs_dly  <= i_cs;
   end
   always @(i_sdi) 
   begin
      #(SDI_DELAY) i_sdi_dly <= i_sdi;
   end
   
   //<> -----------------------------------------------------
   //<> RAW capture for replay
   always @ (posedge i_sclk, i_cs_dly)
   begin
      if (i_cs_dly != CS_ACT_LVL)        // reset SM if no spi_slave_A chipselect is active
         raw_frame_shft_in <= 0;
      else begin
         raw_frame_shft_in <= {raw_frame_shft_in[FRAME_CNT-2 : 0], i_sdi_dly};    // left shift in values (MSbit rx'ed first)
      end
   end 

   //<> -----------------------------------------------------
   //<>  Latch Previous frame raw capture 
   //<>   NOTE: reset by i_rst input, Active High
   //<>         CLOCKED by chipselect *DE*assertion
   always @ (posedge i_cs_dly, posedge i_rst)
   begin
      if (i_rst) begin       // reset SM if no spi_slave_A chipselect is active
         raw_frame_reg <= 0;
      end
      else begin
         raw_frame_reg <= raw_frame_shft_in;  // latch shifted data before cleared in shift always @
      end
   end 

   //<> map internal shift value to output ports
   assign { o_cmd,
            o_data } = raw_frame_reg;   
   
   //<> -----------------------------------------------------
   //<>  Frame length counter
   always
   begin
      
      if (i_cs_dly != CS_ACT_LVL) begin       // reset SM if no spi_slave_A chipselect is active
         #1 frame_cntr = 0;            // delay clear until after length check in other always block
      end
      else begin
         @(posedge i_sclk) frame_cntr = frame_cntr + 1; 
      end
   end 
   
   //<>-----------------------------------------------------
   //<> verify frame length 
   always @ (i_cs_dly)
   begin
      if (i_cs_dly != CS_ACT_LVL) begin                               // Chipselect deasserted?
         if ((frame_cntr > 0) && (frame_cntr < FRAME_CNT)) begin  // check for undersized (but ignore initial reset state)
            `SIM.printError(INST_NAME_STRING, {"undersized frame: too few sclk, rcvd=", `V2INTSTR(frame_cntr)});
         end
         if (frame_cntr > FRAME_CNT) begin
            `SIM.printError(INST_NAME_STRING, {"oversized frame: too many sclk, rcvd=", `V2INTSTR(frame_cntr)});
         end
      end
   end 
   
   //<> kick external flag at rollover point
   assign o_evnt = (frame_cntr == FRAME_CNT) ? 1'b1 : 1'b0;  

//<> ------------------------------------------------------------
//<> INPUT TIMING CHECKS
//<> ------------------------------------------------------------
   specify
      $setup(i_sdi, negedge i_sclk, ts_Dsu, su_flag);
      $hold(negedge i_sclk, i_sdi, ts_Dsu, hld_flag);
   endspecify
   
      always @(su_flag)  `SIM.printError(INST_NAME_STRING, "Data setup timing violation detected. " );
      always @(hld_flag) `SIM.printError(INST_NAME_STRING, "Data hold timing violation detected. " );
   
endmodule


// bfm_AD5453_dac
   // #( .INST_NAME_STRING    ("bfm_AD5453_dac"),
      // .CS_ACT_LVL          (1'b0),  // Active polarity of chipselect input
      // .NUM_CMD_BITS        (2),      // # Command bits
      // .NUM_DATA_BITS       (14)     // # data bits
   // ) 
   // bfm_AD5453_inst
   // ( 
      // .i_sclk  (),
      // .i_cs    (),
      // .i_sdi   (),
      // // testbench interfaces
      // .i_rst   (),                 // board-level/power-on reset input (affects return value)
      // .o_evnt  (),                 // irq flag indicating transaction detected
      // .o_cmd   (),     // [NUM_CMD_BITS-1:0]  data portion detected
      // .o_data  ()   // [NUM_DATA_BITS-1:0] data portion detected
   // );
   