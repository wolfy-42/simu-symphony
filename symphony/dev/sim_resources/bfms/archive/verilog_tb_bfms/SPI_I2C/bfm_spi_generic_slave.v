//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_spi_slave.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : Jan 17, 2014
//--------------------------------------------------------------------
//Description : generic SPI Slave 
//
//    - i_enable   -- if '0', disable BFM messages (but not error/warning) 
//                            
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2015-03-30 12:21:45 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`ifndef SIM
   `define SIM tb.sim_management_inst
`endif

module bfm_spi_slave
   #( parameter BFM_NAME            = "bfm_spi_slave",   // user definiable instance name
      parameter FRAME_SIZE          = 16,                // size of SPI frame in # of bits
      parameter ECHO_MODE           = 1,                 // 1=echo previous word on sdo, 0=output i_frame_to_master on sdo
      parameter CAPTURE_EDGE        = 0,                 // sdin capture on: 0=sclk falling edge(default), 1=rising sclk edge 
      parameter SELECT_ACTIVE_LEVEL = 0,                 // chipselect active level: 0=cs_n (default), 1=cs
      parameter SDO_DEFAULT_LEVEL   = 0,                 // default logic level for SDO output (reset/idle)
      parameter NO_WARNINGS         = 1,                 // 1 = disable protocol warnings logfile output; 0 = output warnings to logfile
      parameter ts_Dsu              = 4.0ns,             // data setup (ns) to SCLK rising (From datasheet)
      parameter ts_Dhld             = 4.0ns              // data hold (ns) from SCLK rising (From datasheet)
      
   )
   (
      //<> DUT interface
      input wire  i_rstn ,      // async clear
      input wire  i_sclk ,      // serial transfer clock
      input wire  i_sync_csn ,  // serial transfer enable/operation sync
      input wire  i_sdi ,       // serial data in 
      output reg  o_sdo ,       // serial data out 
      //<> testbench interface
      input wire                   i_enable ,            // testbench monitor enable control
      input  reg [FRAME_SIZE-1:0]  i_frame_to_master,    // frame returned to master (o_sdo)
      output reg [FRAME_SIZE-1:0]  o_frame_from_master,  // frame received from master (i_sdi)
      output event                 o_frame_event         // event strobe flagging new frame recieved 
   );
   
//<> ------------------------------------------------------------------------   
//<> Module local parameters
//<> ------------------------------------------------------------------------   
   

//<> ------------------------------------------------------------------------   
//<> TYPE AND SIGNAL DECLARATIONS
//<> ------------------------------------------------------------------------   
   integer fptr ;     // input shift register index pointer
   integer optr;      //  data output vector index pointer
   string msg ;
   reg frame_good;  // flag indicating a valid frame size recieved
   reg transaction_enable;  // flag indicating a valid frame size recieved
   reg [FRAME_SIZE-1:0]  sdin_frame ;    // full serial data chain
   reg [FRAME_SIZE-1:0]  sdin_frame_prev ;    // previous full serial data chain
   reg [FRAME_SIZE-1:0]  frame_to_master_buf ;    // frame returned to master (o_sdo)

   
   //<> SPI flow event strobes
   event Start_Of_Frame;
   event End_Of_Frame;
   event Frame_Check_Done;
   event Datain_Latch_Event;
   event Dataout_Drive_Event;
   
   //<> Timing check flags
   reg hld_flag = 0;
   reg su_flag  = 0;
   
   //<> ------------------------------------------------------------
   //<> Simulation T=0ns initialization of internal nets/vectors
   initial begin
      o_frame_from_master = 0;
      o_sdo               = 1'bz;
      sdin_frame          = 0;    
      sdin_frame_prev     = 0;    
      frame_to_master_buf = 0; 
      fptr                = 0; 
      optr                = 0; 
      transaction_enable  = 0; 
      frame_good          = 0;
   end

//<> ------------------------------------------------------------------------------------------------------------------------
//<> TESTCASE VISIBLE TASKS
//<> ------------------------------------------------------------------------------------------------------------------------
   
   //<> none
   
//<> ------------------------------------------------------------------------------------------------------------------------
//<> CONFIGURABLE SPI TRANSACTION TRIGGER EVENT POINTS
//<> ------------------------------------------------------------------------------------------------------------------------
   
   //<> ------------------------------------------------------------
   //<> alias for i_sdi data capture event based on selected edge of serial clock
   always 
   begin
      #1; // avoid t=0 initial transition edge event
      while (1) begin
         if (CAPTURE_EDGE) 
            @(negedge i_sclk);
         else 
            @(negedge i_sclk);
         //<> fire local data-in capture event strobe
         -> Datain_Latch_Event;    // trigger internal event on start of frame condition
      end
   end

   //<> ------------------------------------------------------------
   //<> watch for Start-of-Frame event and trigger interal Event 
   always 
   begin
      #1; // avoid t=0 initial transition edge event
      while (1) begin
         if (SELECT_ACTIVE_LEVEL) 
            @(posedge i_sync_csn);
         else 
            @(negedge i_sync_csn);
         //<> trigger internal event on start of frame condition
         transaction_enable = 1; // flag chipselect asserted
         -> Start_Of_Frame;    
      end
   end
   
   //<> ------------------------------------------------------------
   //<> watch for End-of-Frame event and trigger interal Event 
   always begin
      #1; // avoid t=0 initial transition edge event
      while (1) begin
         if (SELECT_ACTIVE_LEVEL) 
            @(negedge i_sync_csn);
         else 
            @(posedge i_sync_csn);
         //<> trigger internal event on end of frame condition   
         transaction_enable = 0; // flag chipselect deasserted
         -> End_Of_Frame;    
      end
   end
   
  
//<> ------------------------------------------------------------
//<> SERIAL DATA INPUT CAPTURE:
//<>  - pointer counter controlled by Start_Of_Frame event
//<> ------------------------------------------------------------

   //<> init internal vectors at start of new frame capture
   always @(Start_Of_Frame)
   begin
      sdin_frame = 0;
      fptr = 0;
   end
   
   //<> sdin capture
   always @(Datain_Latch_Event)
   begin
      if (transaction_enable) begin
         sdin_frame = (fptr < FRAME_SIZE) ? {sdin_frame[FRAME_SIZE-2:0], i_sdi}  // Shiftleft in data (MSbit first arrive)
                                          : sdin_frame;                          // prevent oversized CSn capture issue
         #1 fptr = fptr + 1;    // increment pointer for next data (ns delay for simulation waveform association clarity)
      end
   end

//<> ------------------------------------------------------------
//<> SERIAL DATA OUTPUT:
//     - echos previous input frame or testcase input (selected by ECHO_MODE) 
//<> ------------------------------------------------------------

   //<> init internal vectors at start of new frame capture
   always @(Start_Of_Frame)
   begin
      frame_to_master_buf = (ECHO_MODE)  ? sdin_frame_prev       // (ECHO_MODE=1) output previous input frame MSbit first 
                                         : i_frame_to_master;    // (ECHO_MODE=0) output testcase defined frame MSbit first 
      optr = FRAME_SIZE-1;       // set pointer to MSbit of frame to output (MSbit first)
   end
   
   //<> sdout drive on configured serial clock edge
   always @(Dataout_Drive_Event)
   begin
      if (transaction_enable) begin
         o_sdo = (optr >= 0) ? frame_to_master_buf[optr]  // output is shifted out MSbit first
                              : 1'bz;                     // tristate if beyond end of frame count
         //<> shift for next data output (ns delay to improve sequence visibility in waveforms)
         #1 optr = optr - 1;  // counts down
      end
   end
   
   
//<> ------------------------------------------------------------------------------------------------------------------------
//<> PROTOCOL CHECKS
//<> ------------------------------------------------------------------------------------------------------------------------
  
   //<> ------------------------------------------------------------
   //<> parse input frame at chipselect DEAssertion time
   always @(End_Of_Frame) 
   begin
      o_sdo = 1'bz;   // tristate SDO when CSn deasserted
      frame_good = 1; // assume the frame is ok until proven otherwise
      //<> confirm valid transactionlength
      if (fptr != (FRAME_SIZE-1)) begin  //  CSN frame size discrepency detected ?
         if (fptr > (FRAME_SIZE-1)) begin  // --> outside upper frame size bounds
            if (!NO_WARNINGS) `SIM.printWarning(BFM_NAME, "SPI CSn asserted longer than defined FRAME_SIZE");
         end
         else begin  // --> under minimum frame size 
            frame_good = 0;   // indicate bad frame length of some sort
            `SIM.printError(BFM_NAME, "transaction fault detected - CSn/Frame too short");
         end
      end
      // else begin  // --> frame size good
         // frame_good = 1; // indicate the frame has a valid length
      // end
      ->Frame_Check_Done;
   end 
   
   //<> ------------------------------------------------------------
   //<> map received frame to component testcase fields at end of transfer
   //<>  - only performed once frame check is complete as it relies on framecheck results
   //<>    - this help ensure no rogue command/operations from over/under-sized frames
   always @(Frame_Check_Done) 
   begin
      sdin_frame_prev = sdin_frame;    // bufffer current frame for next transfer output
      o_frame_from_master = (frame_good) ? sdin_frame : {(FRAME_SIZE-1){1'bz}};
      if (i_enable) `SIM.printMessage(BFM_NAME, {"SPI xfer recieved ==> ", `V2HEXSTR(o_frame_from_master) });
      -> o_frame_event; 
   end

//<> ------------------------------------------------------------------------------------------------------------------------
//<> TIMING CHECKS
//<> ------------------------------------------------------------------------------------------------------------------------
   
   //<> ------------------------------------------------------------
   //<> SPI BUS INPUT SCLK <-> DATA TIMING CHECKS
   specify
      $setup(        i_sdi , negedge i_sclk, ts_Dsu,  su_flag);
      $hold (negedge i_sclk,         i_sdi , ts_Dhld, hld_flag);
   endspecify
      always @(su_flag)  `SIM.printError(BFM_NAME, "Data setup timing violation detected. " );
      always @(hld_flag) `SIM.printError(BFM_NAME, "Data hold timing violation detected. " );
  
endmodule

//* -----------------------------Instance template--------------------------------
//  --------------------------------*-----------------------------------
   // //<>--------------------------------------------------------------------
   // //<> Generic SPI SLave
   // //<>
   // bfm_spi_slave
      // #( .BFM_NAME            ("bfm_spi_slave"),   // user definiable instance name
         // .FRAME_SIZE          (16),                // size of SPI frame in # of bits
         // .ECHO_MODE           (1),                 // 1=echo previous word on sdo, 0=output i_frame_to_master on sdo
         // .SDO_DEFAULT_LEVEL   (1'b0)               // default logic level for SDO output (reset/idle)
      // ) bfm_spi_slave_inst
      // (
         // //<> DUT interface
         // .i_rstn  (),      // serial transfer clock
         // .i_sclk  (),      // serial transfer clock
         // .i_sync_csn  (),      // serial transfer enable
         // .i_sdi   (),       // serial data in 
         // .o_sdo   (),       // serial data in 
         // //<> testbench interface
         // .i_enable               (),    // testbench monitor enable control
         // .i_frame_to_master      (),    // frame returned to master (o_sdo)
         // .o_frame_from_master    (),    // frame received from master (i_sdi)
         // .o_frame_event          ()     // event strobe flagging new frame recieved
      // );
