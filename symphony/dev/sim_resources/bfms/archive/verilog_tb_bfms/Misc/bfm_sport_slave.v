//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_sport_slave.vhd
//Project     : Jetson
//Author      : Arnold Balisch   
//Created     : April 29, 2014
//--------------------------------------------------------------------
//Description : module and user callable procedures for the 
//     Framed Serial Port transfer interface on the SharcDSP 21489 
//
// Frame Format:
//  00 [13:0] 0000_0000_0000_0000_0000_0000_0000_0000
//        L__ 14bit input data value
//
// Included Function Calls:
//    - sport_msg()
// 
// <ported from previous VHDL implementation>
//
// datasheet: http://www.analog.com/en/processors-dsp/sharc/adsp-21489/products/product.html
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2014-06-09 14:55:32 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`define NO_FRAME_FAULT

module bfm_sport_slave 
   #( parameter BFM_NAME  = "bfm_sport_slave ",     // instance name for logfile messenging 
      parameter DATA_LENGTH    = 16               // size of each field in frame
   )   
   (  //<> DUT connections
      input wire clk    ,      // input clock
      input wire f_sync ,      // external sync strobe
      input wire ch0da  ,      // Multi_a sdma
      input wire ch0db  ,      // add_a   sdaa 
      //<> testbench signals
      output reg [DATA_LENGTH-1:0] MDA1_data ,
      output reg [DATA_LENGTH-1:0] MDA2_data ,
      output reg [DATA_LENGTH-1:0] ADA1_data ,
      output reg [DATA_LENGTH-1:0] ADA2_data ,
      output event new_frame_evnt         // used to denote SPORT traffic framing to testcases (optional)
   );
   
//<> SPORT interface spcifications
parameter PKT_LENGTH     = (2*DATA_LENGTH);               // size of frame

//<> Timing specifications
localparam ts_IPG          = 3000 ;                      // minimum gap between SPORT messages (ns)

//<> Local variables
integer fptr = 0;    // frame bit pointer
reg [PKT_LENGTH-1:0] v_dat_0A = 'hz;  // temp sport frame buffer
reg [PKT_LENGTH-1:0] v_dat_0B = 'hz;  // temp sport frame buffer

   
   //<> --------------------------------------------------------------------------------------
   // sport bus serial link 
   //  - assumes gated clock controlled by DUT
   //  - MSbit out first
   //<> --------------------------------------------------------------------------------------
   always @(negedge clk) 
   begin
      if (f_sync == 1'b1) begin  // end of a frame detected...
         fptr <= PKT_LENGTH-1;      // init pointers (minus 2 for next incoming cycle
      end
      else begin  //capture first 32bits of data 
         if (fptr >= 0) begin  // pointer underrun detection
            v_dat_0A[fptr] <= ch0da;
            v_dat_0B[fptr] <= ch0db;
         end 
`ifndef NO_FRAME_FAULT
         else begin // pointer underrun detected....
            `SIM.printError(BFM_NAME, "SPORT frame pointer underrun detected...oversized frame");
         end
`endif         
         #1 fptr <= fptr - 1;    // decrement pointer for next cycle (add slight delay for waveform sequence clarity)
      end
   end

   //<> --------------------------------------------------------------------------------------
   //<> latch frame data to testbench outputs at end of frame sync   
   always 
   begin
         @(posedge f_sync);
         #1;
         {MDA1_data, MDA2_data} <= v_dat_0A;
         {ADA1_data, ADA2_data} <= v_dat_0B;
         ->new_frame_evnt;
   end
   
   
endmodule

// bfm_sport_slave 
//    #(.BFM_NAME ("bfm_sport_slave ")
//    )
//    bfm_sport_slave_inst
//    ( //<> DUT connections
//       .clk    (),             // input clock
//       .f_sync (),             // external sync strobe
//       .ch0da  (),             // Multi_a sdma
//       .ch0db  (),             // add_a   sdaa 
//       //<> testbench signals
//       .MDA1_data (),          // output [DATA_LENGTH-1:0]
//       .MDA2_data (),          // output [DATA_LENGTH-1:0]
//       .ADA1_data (),          // output [DATA_LENGTH-1:0]
//       .ADA2_data (),          // output [DATA_LENGTH-1:0]
//       .new_frame_evnt ()      // 'event' used to denote SPORT traffic framing to testcases
//    );