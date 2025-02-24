//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_AD5624R.sv
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : Nov 18, 2014
//--------------------------------------------------------------------
//Description : BFM and Monitor for AD_5624R DAC
//    i_enable          --> used to disable BFM if desired
//
//  <<  NOTE: currently LDAC mode is not implemented  >>
//
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2014-11-19 12:55:39 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

  module bfm_AD5624R
   #( parameter BFM_NAME                  = "bfm_AD5624R",
      //<> NOTE: Parameters below are Device Specific from Datasheet...
      parameter NUM_VALID_DATA_BITS       = 12,
      parameter NUM_DATA_FIELD_BITS       = 16,    // number of total possible databits serial output string (From datasheet)
      parameter NUM_PREFIX_BITS           = 2,
      parameter NUM_CMD_BITS              = 3,
      parameter NUM_ADDR_BITS             = 3,
      parameter SILENT                    = 0      // if '1', suppress select status logfile message output
      )
   (
      //<> DUT I/O
      input wire                           i_sclk ,               // serial transfer clock
      input wire                           i_sync ,               // serial transfer enable
      input wire                           i_sdin ,               // serial data in
      output reg [NUM_VALID_DATA_BITS-1:0] o_channel [3:0],       // output dac channels
      output event                         o_update [3:0],        // output dac update events
      //<> testbench I/O
      input wire                           i_enable          ,    // testbench monitor enable control
      output reg [NUM_CMD_BITS-1:0]        cmd_code       = 0,    // buffer for command
      output reg [NUM_ADDR_BITS-1:0]       addr_code      = 0,    // buffer for address
      output reg [NUM_DATA_FIELD_BITS-1:0] full_data_word = 0,    // buffer for full data word
      output reg [3:0]                     ldac_reg       = 0,    // internal register for LDAC mode control            <<RFU>>
      output reg                           int_ref        = 0     // internal register for internal reference on(1)/off(0)
   );

//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS
//<> ------------------------------------------------------------
   localparam NUM_X_DATA_BITS = (NUM_DATA_FIELD_BITS - NUM_VALID_DATA_BITS);  // calculate # of trailing unused "don't care" bits in data op
   localparam FDAC_FRAME_SIZE = (  NUM_PREFIX_BITS
                                 + NUM_CMD_BITS
                                 + NUM_ADDR_BITS
                                 + NUM_VALID_DATA_BITS
                                 + NUM_X_DATA_BITS );    // calculate # bits in a full frame

   //<> Input timing specs  (from datasheet)
   localparam  ts_Dsu  = 5;     // data setup to SCLK falling (From datasheet)
   localparam  ts_Dhld = 5;     // data hold from SCLK falling (From datasheet)
   localparam  ts_Shi  = 15;    // Sync HIGH duration from Sync Rising edge (From datasheet)


//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   integer frame_cntr = 0;
   integer fptr;                                   // shift register index pointer
   string msg ;
   reg [FDAC_FRAME_SIZE-1:0]     sdin_frame = 0;   // full serial data chain
   reg [NUM_PREFIX_BITS-1:0]     prefix_bits;      // buffer for prefix
   reg su_flag, hld_flag, conv_flag = 0;
   reg [NUM_VALID_DATA_BITS-1:0] input_reg [3:0];  // mimic internal input registers (one per channel)
   reg [NUM_VALID_DATA_BITS-1:0] crop_data;  // mimic internal input registers (one per channel)
   integer x;  //loop pointer
   event frame_ready_event;
   event frame_valid_event;
   event update_outputs_event;

//<> ------------------------------------------------------------
//<> INPUT PARSER
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<>  Perform serial data input capture
   //<>  - frame limited to allow oversized sync pulse
   //<>  - abort capture on short-frame (premature rising i_sync)
   always
   begin
      @(negedge i_sync);                                                      // Delay until sync negative edge detected
      //<> vector index for output counts from MSbit -> LSbit  (count based from '1' for stop on zero)
      fork: frame_capture
         begin: normal_op
            for (fptr=FDAC_FRAME_SIZE; i_sync == 1'b0; fptr=fptr-1)  begin    // finishes when i_sync goes high
               @(negedge i_sclk);
               if (fptr > 0) sdin_frame[fptr-1] <= i_sdin;                    // capture data from port (index adjusted to match vector range and limited for oversync)
            end
            disable frame_capture;
         end
         begin: unexpected_abort
            @(posedge i_sync);
            disable frame_capture;                                            // breaks out of capture if sync goes high before negedge i_sclk - abort condition
         end
      join
      //<> --at this point in the narrative, i_sync has gone high
      if (fptr > 0) begin                                                     // Abort condition detected....
         sdin_frame = 0;                                                      // clear frame buffer of partial contents..prevents output processing
         `SIM.printWarning(BFM_NAME, "Transfer aborted by premature SYNC rising edge");
      end
      ->frame_ready_event;                                                    // indicate new frame ready for parsing
   end

   //<> ------------------------------------------------------------
   //<> map received frame to component fields
   always @(frame_ready_event)
   begin
      {  prefix_bits,
         cmd_code,
         addr_code,
         full_data_word } = sdin_frame;
      ->frame_valid_event;   // indicate frame parsed and fields ready for processing
   end

   //<> ------------------------------------------------------------
   //<> parse input frame at sync DEAssertion time
   always @(frame_valid_event)
   begin
      //<> confirm valid cycle event
      if (fptr != 0) begin
         if (fptr > 0) begin
            `SIM.printWarning(BFM_NAME, "serial write abort detected - Frame too short");
         end
         else begin // fprt is a negative number...sync longer than required, but not illegal
            `SIM.printWarning(BFM_NAME, "SYNC held active_low longer than required for data transfer");
            ->update_outputs_event;
         end
      end
      else begin  // fptr=0 means valid frame duration
         ->update_outputs_event;
         if (!SILENT)
            `SIM.printMessage(BFM_NAME, {"SPI xfer recieved ==> cmd= ", `V2HEXSTR(cmd_code),", addr= ", `V2HEXSTR(addr_code), ", data= ", `V2HEXSTR(full_data_word) });
      end
   end


//<> ------------------------------------------------------------
//<> OUTPUT DRIVER
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> assign valuse to output channels at end of cycle
   //<> - ONLY performed if a full frame recieved (not aborted)
   always @(update_outputs_event)
   begin
      crop_data = full_data_word >> (NUM_DATA_FIELD_BITS-NUM_VALID_DATA_BITS);   // valid data bits always left(MS) justified
      //<> confirm valid cycle event
      case (cmd_code)
         0 :begin                                                 // write input reg(s) but do not update outputs
               if (addr_code === 3'b111) begin
                  for (x=0; x<4; x++)
                     input_reg[x] = crop_data;                    // map value to all input registers
               end
               else
                  input_reg[addr_code] = crop_data;               // map to selected input register
            end
         1 :begin                                                 // assert single output channel based on existing input reg
               if (addr_code === 3'b111) begin
                  for (x=0; x<4; x++) begin
                     o_channel[x] = input_reg[x];                 // update all output channels (as per command=2)
                     -> o_update[x];                               // indicate channel output updated
                  end
               end
               else begin
                  o_channel[addr_code] = input_reg[addr_code];    // output current value of input reg
                  -> o_update[addr_code];                          // indicate channel output updated
               end
            end
         2 :begin                                                 // update input reg and assert ALL output channels based on input regs
               input_reg[addr_code] = crop_data;                  // map to input register, but do not update outputs
               for (x=0; x<4; x++) begin
                  o_channel[x] = input_reg[x];                    // output current value of input reg
                  -> o_update[x];                                  // indicate channel output updated
               end
            end
         3 :begin                                                 // update input reg and assert only same output channel with new value
               input_reg[addr_code] = crop_data;                  // map to input register, but do not update outputs
               o_channel[addr_code] = crop_data;                  // output current value of input reg
               -> o_update[addr_code];                                  // indicate channel output updated
            end
         6 :begin                                                 // update LDAC function register
               ldac_reg = full_data_word[3:0];
            end
         7 :begin                                                 // update internal voltage reference on/off register
               int_ref = full_data_word[0];
            end
         default :begin
            end
      endcase
   end



//<> ------------------------------------------------------------
//<> INPUT TIMING CHECKS
//<> ------------------------------------------------------------

   specify
      $setup(i_sdin, negedge i_sclk, ts_Dsu, su_flag);   // leverage Verilog constructs for setup/hold
      $hold(negedge i_sclk, i_sdin, ts_Dsu, hld_flag);
      // $hold(posedge i_sync, i_sync, ts_Shi, conv_flag);
   endspecify

   //<> above flags used to trigger RIPL fault counters/msg libraries
   always @(su_flag)   `SIM.printError(BFM_NAME, "Data setup timing violation detected. " );
   always @(hld_flag)  `SIM.printError(BFM_NAME, "Data hold timing violation detected. " );
   // always @(conv_flag) `SIM.printError(BFM_NAME, "SYNC High duration violation detected. " );


endmodule

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:

 // bfm_AD5624R
   // #( .BFM_NAME                  ("bfm_AD5624R"),
      // //<> NOTE: Parameters below are Device Specific from Datasheet...
      // .NUM_VALID_DATA_BITS       (12),
      // .NUM_DATA_FIELD_BITS             (16),             // number of total possible databits serial output string (From datasheet)
      // .NUM_PREFIX_BITS           (2),
      // .NUM_CMD_BITS              (3),
      // .NUM_ADDR_BITS             (3)
      // ) bfm_AD5624_inst
   // (
      // .i_sclk           (),    // serial transfer clock
      // .i_sync           (),    // serial transfer enable
      // .i_sdin           (),    // serial data in
      // .o_channel        (),    // four output channels: [NUM_VALID_DATA_BITS-1:0] bits each
      // .o_update         (),    // output dac update events
      // //<> testbench inputs
      // .i_enable         (),    // testbench monitor enable control
      // .cmd_code (),        // [NUM_CMD_BITS-1:0]   buffer for command
      // .addr_code   (),     // [NUM_ADDR_BITS-1:0]  buffer for address
      // .full_data_word (),  // [NUM_DATA_FIELD_BITS-1:0]  buffer for full data word
      // .ldac_reg     (),
      // .int_ref      ()




   // );