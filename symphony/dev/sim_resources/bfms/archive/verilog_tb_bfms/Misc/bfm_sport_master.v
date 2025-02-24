//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_sport_master.vhd
//Project     : Jetson
//Author      : Arnold Balisch   
//Created     : May 3, 2012
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
// $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2014-05-15 18:07:11 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

//==========================================PACKAGE BODY==========================================
module bfm_sport_master 
   #(parameter BFM_NAME  = "bfm_SPORT_master "     // instance name for logfile messenging 
   )   
   (
      input  wire clk ,       // input clock
      output reg f_sync ,     // external sync strobe
      output reg ch0da ,       // Multi_a  3A
      output reg ch0db ,       // add_a    3B
      output reg ch1da ,       // Multi_b  4A
      output reg ch1db ,       // Add_b    4B
      output reg flag         // used to denote SPORT traffic framing to testcases (optional)
   );
   
//<> SPORT interface spcifications
parameter DATA_LENGTH    = 16;                          // Clock edge to assert bus changes on (0= falling, 1= rising)
parameter PKT_LENGTH     = 32;                          // Clock edge to assert bus changes on (0= falling, 1= rising)
parameter F_SYNC_POL     = 1'b0;                        // polarity of write bit in SPI transaction
parameter CLK_WR_LVL     = 1'b1;                        // Clock edge to assert bus changes on (0= falling, 1= rising)
localparam NULL_SPACE    = (PKT_LENGTH - DATA_LENGTH);  // vector size difference between data and unused portion of frame word

//<> Timing specifications
parameter ts_PHASE_OFFSET = 11.3 ;                      // Board level offset between clock and data (ns)
parameter ts_IPG          = 3000 ;                      // minimum gap between SPORT messages (ns)

   initial begin
      f_sync = ~F_SYNC_POL;
      ch0da = 0;
      ch0db = 0;
      ch1da = 0;
      ch1db = 0;
      flag = 0;
   end
  
   //--------------------------------------------------------------------------------------
   // sport bus serial link (timing based on LTC1407 DAC timing specifications)
   //  - assumes gated clock controlled by testbench global net sourced by procedure output "flag"
   //  - MSbit out first
   //--------------------------------------------------------------------------------------
   task sport_msg ( 
      input [DATA_LENGTH-1 : 0] MDA1_data ,
      input [DATA_LENGTH-1 : 0] MDA2_data ,
      input [DATA_LENGTH-1 : 0] ADA1_data ,
      input [DATA_LENGTH-1 : 0] ADA2_data ,
      input [DATA_LENGTH-1 : 0] MDB1_data ,
      input [DATA_LENGTH-1 : 0] MDB2_data ,
      input [DATA_LENGTH-1 : 0] ADB1_data ,
      input [DATA_LENGTH-1 : 0] ADB2_data 
   ); 
      integer x ;                      // loop index
      reg [PKT_LENGTH-1:0] v_dat_3A ;  // loop index
      reg [PKT_LENGTH-1:0] v_dat_3B ;  // loop index
      reg [PKT_LENGTH-1:0] v_dat_4A ;  // loop index
      reg [PKT_LENGTH-1:0] v_dat_4B ;  // loop index
   begin
      if (PKT_LENGTH < DATA_LENGTH) 
         `SIM.printError(BFM_NAME, "CRITICAL: invalid frame vs data size constants defined");
      //<> initialize variables and bus outputs
      v_dat_3A = {MDA1_data, MDA2_data};         // data left justified
      v_dat_3B = {ADA1_data, ADA2_data};         // data left justified
      v_dat_4A = {MDB1_data, MDB2_data};         // data left justified
      v_dat_4B = {ADB1_data, ADB2_data};         // data left justified
      `SIM.printMessage ("sport_msg()", {"INFO: sending data burst DA_3=" , `V2HEXSTR(v_dat_3A) });
      `SIM.printMessage ("sport_msg()", {"INFO: sending data burst DB_3=" , `V2HEXSTR(v_dat_3B) });
      `SIM.printMessage ("sport_msg()", {"INFO: sending data burst DA_4=" , `V2HEXSTR(v_dat_4A) });
      `SIM.printMessage ("sport_msg()", {"INFO: sending data burst DB_4=" , `V2HEXSTR(v_dat_4B) });
      flag = 1'b1;                               // indicate spi transaction underway (start clock)
      ch0da = 1'b0;                               //  \
      ch0db = 1'b0;                               //    > ensure outputs all default low
      ch1da = 1'b0;                               //   /
      ch1db = 1'b0;                               //  /
      f_sync = ~F_SYNC_POL;                      // ensure not selected
      //<> commence SPORT transaction
      for (x=(PKT_LENGTH-1); x>=0; x=x-1) begin  // output data MSbit first
                                                 // wait until (clk == ~CLK_WR_LVL);  
         if (CLK_WR_LVL) begin
            @(negedge clk);
         end
         else begin
            @(posedge clk);
         end                                     // wait for active clk edge to assert changes
         #(ts_PHASE_OFFSET);                     // delay for round trip Board-level phase offset between CKL and DATA
         f_sync = F_SYNC_POL;                    // assert frame sync
         ch0da  = v_dat_3A[x];                    // drive new data value onto data line
         ch0db  = v_dat_3B[x];                    // drive new data value onto data line
         ch1da  = v_dat_4A[x];                    // drive new data value onto data line
         ch1db  = v_dat_4B[x];                    // drive new data value onto data line
      end 
      if (CLK_WR_LVL) begin
         @(negedge clk);
      end
      else begin
         @(posedge clk);
      end                                        // wait for active clk edge to assert changes
      #(ts_PHASE_OFFSET);                        // delay for round trip Board-level phase offset between CKL and DATA
      f_sync = ~F_SYNC_POL;                      // not selected
      ch0db = 1'b0;                               // release data lines
      ch0da = 1'b0;    
      ch1db = 1'b0;                               // release data lines
      ch1da = 1'b0;    
      flag = 1'b0;                               // indicate spi transaction completed  (stop clk)
      #(ts_IPG);                                 // ensure minimum inter burst gap
   end
   endtask 
   
endmodule

// bfm_sport_master 
   // #(.BFM_NAME ("bfm_SPORT_master ")
   // )
   // bfm_sport_master_inst
   // (
      // .clk     (),
      // .f_sync  (),
      // .ch0da    (),
      // .ch0db    (),
      // .ch1da    (),
      // .ch1db    (),
      // .flag    ()   // used to denote SPORT traffic framing to testcases (optional)
   // );