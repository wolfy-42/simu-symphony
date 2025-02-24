////////////////////////////////////////////////////////////////////////
//
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//
//File name   : bfm_ltc26xx_dac_bfm_pkg.vhd
//Project     : VIP_VHDL
//Author      : Arnold Balch   
//Created     : Sept 15, 2011
////////////////////////////////////////////////////////////////////////
//Description : Functions and Procedures for bfm_ltc26xx_dac_bfm
//    - th  an input only device...no readback hence no turnaround
//    - provides regtered SPI transaction compliance
//    - sdo port echos previous recieved frame (or null on first access after reset)
//
// Included Function/procedure Calls:
//    - <none>
// 
// External Constants from "global_regs_pkg" used:
//       - <none>
//
////////////////////////////////////////////////////////////////////////
// $Author: Arnold.Balisch $     $Revion: 1.1 $    $Date: 2014-05-23 18:46:38 $
////////////////////////////////////////////////////////////////////////

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

module bfm_ltc26xx_dac
   #(    parameter BFM_NAME = "bfm_ltc26xx_dac",
         parameter MODE             = 1,  // 
         parameter NUM_PREFIX_BITS  = 0,  // # read/write input command bits
         parameter NUM_CMD_BITS     = 4,  // # read/write input command bits
         parameter NUM_ADDR_BITS    = 4,  // # address bits in header
         parameter NUM_CONV_BITS    = 12  // # data bits (12, 14, 16)
   )
   (
     input wire i_sclk,
     input wire i_cs  ,
     input wire i_sdi ,
     output reg o_sdo , 
      //<> testbench interfaces
      input wire i_rst  ,                             // board-level/power-on reset input (affects return value)
      output reg o_evnt = 1'b0,              // <<RFU>> irq flag indicating transaction completed
      output reg [NUM_CMD_BITS-1 :0] o_cmd   = 'h0, // command portion of header detected
      output reg [NUM_ADDR_BITS-1:0] o_addr  = 'h0,  // address portion of header detected
      output reg [NUM_CONV_BITS-1:0] o_data_A  = 'h0,  // data portion detected
      output reg [NUM_CONV_BITS-1:0] o_data_B  = 'h0,  // data portion detected
      output reg [NUM_CONV_BITS-1:0] o_data_C  = 'h0,  // data portion detected
      output reg [NUM_CONV_BITS-1:0] o_data_D  = 'h0,  // data portion detected
      output reg [NUM_CONV_BITS-1:0] o_data_E  = 'h0,  // data portion detected
      output reg [NUM_CONV_BITS-1:0] o_data_F  = 'h0,  // data portion detected
      output reg [NUM_CONV_BITS-1:0] o_data_G  = 'h0,  // data portion detected
      output reg [NUM_CONV_BITS-1:0] o_data_H  = 'h0   // data portion detected
   );


//<> ------------------------------------------------------------
//<> LOCAL CONSTANTS 
//<> ------------------------------------------------------------
   localparam NUM_DATA_BITS = 16;  // hard number...bits in payload
   parameter  NUM_X_BITS  = NUM_DATA_BITS - NUM_CONV_BITS;  // # leftover 'X' bits at end of dataword
   parameter  CMD_LOC     = NUM_PREFIX_BITS;       // # bits before start of command field
   parameter  ADDR_LOC    = NUM_PREFIX_BITS + NUM_CMD_BITS; // # bits before start of addressing field
   parameter  PAYLOAD_LOC = NUM_PREFIX_BITS + NUM_CMD_BITS + NUM_ADDR_BITS; //  // # bits in the payload (may vary from generic)
   parameter  FRAME_CNT   = NUM_CMD_BITS + NUM_ADDR_BITS + NUM_DATA_BITS; // # bits for full frame

   
//<> ------------------------------------------------------------
//<> INTERNAL SIGNALS
//<> ------------------------------------------------------------
   reg [NUM_CMD_BITS-1:0]  cmd_shft            = 0;  // command portion of header detected
   reg [NUM_ADDR_BITS-1:0] addr_shft           = 0;  // address portion of header detected
   reg [NUM_DATA_BITS-1:0] data_shft           = 0;   // data portion detected
   reg [FRAME_CNT-1:0]     raw_frame_shft_in   = 0;   // current frame being recieved
   reg [FRAME_CNT-1:0]     raw_frame_shft_out  = 0;   // current frame being recieved
   reg [FRAME_CNT-1:0]     raw_frame_reg       = 0;   // buffer for previous frame recieved

   reg int_sdio_in   = 1'b0;
   reg int_sdio_out  = 1'b0;
   reg sdio_dir      = 1'b0;
   
   reg [1:0] sm_state   = 2'b00;
      parameter s_START = 2'b00,
                s_CMD   = 2'b01, 
                s_ADDR  = 2'b10, 
                s_DATA  = 2'b11;

   reg rw_mode     = 1'b0;       // Command mode
      parameter M_WR = 1'b0, 
                M_RD = 1'b1;  // Note: read vs write direction  from perspective of external Master

   
   integer frame_cntr    = 0;

//<> ------------------------------------------------------------
//<> Bus read
//<> ------------------------------------------------------------
   always @(negedge i_cs )
   begin
      frame_cntr      <= 0;   // offset one in counting to accomadate FF setup/propagation
      rw_mode         <= M_WR;
      // if (NUM_PREFIX_BITS > 0) 
         // sm_state       <= s_START; // prep for "don't care" prefix
      // else
         // sm_state       <= s_CMD; // short burst mode
      sm_state       <= s_CMD; // short burst mode
   end

   always @(posedge i_sclk)
   begin
      if (i_cs == 1'b0) begin      // only process if select is active_low
         frame_cntr <= frame_cntr + 1;
         case (sm_state) 
             s_START : begin 
                  if (frame_cntr >= CMD_LOC)   // greatter-than used to help avoid start fault alignment sues
                     sm_state <= s_ADDR;
               end
             s_CMD : begin
                  if (frame_cntr == ADDR_LOC-1) 
                     sm_state <= s_ADDR;
               end
             s_ADDR : begin
                  if (frame_cntr == PAYLOAD_LOC-1) 
                     sm_state <= s_DATA;
               end
             s_DATA : begin
                  if (frame_cntr > FRAME_CNT) 
                     `SIM.printError(BFM_NAME, "recieved Chipselect duration too long..too many sclk pulses");
               end
             default : 
               sm_state <= s_START;    // fault recovery
         endcase
      end
   end

   //<> ------------------------------------------------------------
   //<> capture CMD frame
   always @(posedge i_sclk)
   begin
      if (sm_state == s_CMD) begin
            cmd_shft <= {cmd_shft[NUM_CMD_BITS-2:0] , i_sdi};    // left shift in values (MSbit rx'ed first)
      end
   end
 
   always @(posedge i_cs )
   begin
         o_cmd <= cmd_shft;
   end
 
   //<> ------------------------------------------------------------
   //<> capture addr frame
   always @(posedge i_sclk)
   begin
      if (sm_state == s_ADDR) begin
            addr_shft <= {addr_shft[NUM_ADDR_BITS-2:0], i_sdi};    // left shift in values (MSbit rx'ed first)
      end
   end

   always @(posedge i_cs)
   begin
      o_addr <= addr_shft;
   end

   //<> ------------------------------------------------------------
   //<> capture data frame
   always @(posedge i_sclk)
   begin
      if (sm_state == s_DATA) begin
         data_shft <= {data_shft[NUM_DATA_BITS-2:0], i_sdi};    // left shift in values (MSbit rx'ed first)
      end
   end 

   always @(posedge i_cs)
   begin
      case (addr_shft) 
        0: o_data_A <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
        1: o_data_B <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
        2: o_data_C <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
        3: o_data_D <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
        4: o_data_E <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
        5: o_data_F <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
        6: o_data_G <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
        7: o_data_H <= data_shft[NUM_DATA_BITS-1 : (NUM_DATA_BITS-NUM_CONV_BITS)];
      endcase
   end

   assign o_sdo = 1'b0;  // tie off as unused.
   
endmodule



// bfm_ltc26xx_dac_bfm 
   // #(.BFM_NAME ("bfm_ltc26xx_dac_bfm"),
     // .MODE             ( 1),  // 
     // .NUM_X_BITS     ( 0),  // # read/write input command bits
     // .NUM_CMD_BITS     ( 4),  // # read/write input command bits
     // .NUM_ADDR_BITS    ( 4),  // # address bits in header
     // .NUM_DATA_BITS    (16) // # data bits
   // ) bfm_ltc26xx_dac_bfm
   // (
      // .i_sclk (),
      // .i_cs   (),
      // .i_sdi  (),
      // .o_sdo  (), 
      // //<> testbench interfaces
      // .i_rst  (),                             // board-level/power-on reset input (affects return value)
      // .o_evnt (),              // <<RFU>> irq flag indicating transaction completed
      // .o_cmd  (), // [NUM_CMD_BITS-1 :0] command portion of header detected
      // .o_addr (), //[NUM_ADDR_BITS-1:0]  address portion of header detected
      // .o_data ()  // [NUM_DATA_BITS-1:0] data portion detected
   // );
