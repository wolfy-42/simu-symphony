//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_ADG714_spi_sw.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : Jan 17, 2014
//--------------------------------------------------------------------
//Description : base SPI Slave template
//    - assumes gated SPI clock input (active only during sync_csn = LOW
//    - data_ports are "analog" so 32bit vector used to emulate integer values
//    - i_enable          --> used to disable BFM messages (but not error/warning) if desired
//                            
//
// Note: relies on System-Verilog syntax to enable 2D array ports
// datasheet: 
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2014-03-05 21:21:22 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`ifndef SIM
`define SIM tb.sim_management_inst
`endif

//<> SPI setup/hold timing check enable/disable (uncomment to disable)
// `define NO_SuHld_TIMING_CHECKS


  module bfm_ADG714_spi_sw
   #( parameter BFM_NAME                  = "bfm_ADG714_spi_sw",
      //<> NOTE: Parameters below are Device Specific from Datasheet...
      parameter NUM_DATA_PORTS            = 8,    // number of "analog" data ports on n:1 mux
      parameter NUM_CMD_BITS              = 8
   )
   (
      //<> DUT interface
      input wire  i_rst ,      // async clear
      input wire  i_sclk ,      // serial transfer clock
      input wire  i_sync_csn ,  // serial transfer enable/operation sync
      input wire  i_sdi ,       // serial data in 
      output reg  o_sdo ,       // serial data out 
      //<> Switch ports
      input  wire [31:0] i_data_port [NUM_DATA_PORTS-1:0],
      output reg  [31:0] o_data_port [NUM_DATA_PORTS-1:0],
      //<> testbench interface
      input wire                            i_enable ,       // testbench monitor enable control
      output wire [NUM_CMD_BITS-1:0]        o_frame       // buffer for command
   );
   
   //<> ------------------------------------------------------------
   //<> local parameter/constants 
   localparam MAX_FRAME_SIZE  = NUM_CMD_BITS;
   localparam GND = 31'd0;     // if port not selected, ground output to logic LOW
   
   //<> timing specs  (from datasheet)
   localparam  ts_Dsu    = 5;         // (ns) data setup to SCLK rising (From datasheet)
   localparam  ts_Dhld   = 4.5;       // (ns) data hold from SCLK rising (From datasheet)
   localparam  ts_Td     = 8;         // (ns) make-before-break delay
   localparam  ts_Tdout  = 20;         // (ns) make-before-break delay

   //<> ------------------------------------------------------------
   //<> internal BFM variables
   integer frame_cntr = 0;
   integer pidx;        // for loop pointer
   int x;   
   string msg ;
   reg frame_good = 0;  // flag indicating a valid frame size recieved
   reg [MAX_FRAME_SIZE-1:0] sdin_frame = 0;    // full serial data chain
   reg su_flag, hld_flag;
   reg [NUM_CMD_BITS-1:0]   spi_frame = 0;
   
   //<> SPI flow event strobes
   event Start_Of_Frame;
   event End_Of_Frame;
   event Frame_Process_Start;
   event Frame_Check_Done;
   event Sw_Pos_Change;
   
   initial begin
      o_sdo = 1'b0;
      for (x=0;x<NUM_DATA_PORTS; x=x+1) 
         o_data_port[x] = 32'd0;    // initialize each output port
   end
//<> ------------------------------------------------------------------------------------------------------------------------
//<> SPI INTERFACE
//<> ------------------------------------------------------------------------------------------------------------------------
   
   
   //<> ------------------------------------------------------------
   //<> watch for start of transaction and trigger interal Event strobe
   always begin
      #10; // pad for simulation TB signal startup initialization
      while (1) begin
         @(negedge i_sync_csn) -> Start_Of_Frame;    // trigger internal event on start of frame condition
      end
   end

   //<> ------------------------------------------------------------
   //<> watch for end of the transaction and trigger event strobe
   always begin
      #10; // pad for simulation TB signal startup initialization
      while (1) begin
         @(posedge i_sync_csn) -> End_Of_Frame;    // trigger internal event on end of frame condition
      end
   end
   
   
//<> ------------------------------------------------------------
//<> INPUT FRAME PROCESSING
//<> ------------------------------------------------------------
   
   //<> left shift in new SPI data
   always @(negedge i_sclk) 
   begin
      if(i_sync_csn == 1'b0) begin   // avoid free-running clock conflicts
            sdin_frame = {sdin_frame[MAX_FRAME_SIZE-2:0],i_sdi};   // Leftshift in data (in MSbit first)  
      end
   end

//<> ------------------------------------------------------------
//<> OUTPUT FRAME PROCESSING
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> output MS bit on rising edge (before register shifted by new data arrives on falling edge)
   always @(posedge i_sclk) 
   begin
      if(i_sync_csn == 1'b0) begin   // avoid free-running clock conflicts
            o_sdo = sdin_frame[MAX_FRAME_SIZE-1];   // output MSbit of frame 
      end
   end
   
   //<> ------------------------------------------------------------
   //<> parse input frame at chipselect DEAssertion time
   always @(End_Of_Frame) 
   begin
         frame_good = 1; // indicate the frame has a valid length
         if (i_enable) `SIM.printMessage(BFM_NAME, {"SPI xfer recieved ==> ", `V2HEXSTR(sdin_frame)});
         ->Frame_Check_Done;
   end 
    
   //<> ------------------------------------------------------------
   //<> map received frame to component testcase fields at end of transfer
   //<>  - only performed once frame check is complete as it relies on framecheck results
   //<>    - this help ensure no rogue command/operations from over/under-sized frames
   always @(Frame_Check_Done) 
   begin
      spi_frame = sdin_frame;   // map new frame to ports for testcase crosscheck
      ->Sw_Pos_Change;        // kick command processing for mux switch transition determination
   end
   
   assign o_frame = spi_frame;
   
//<> ------------------------------------------------------------
//<> SPI BUS INPUT TIMING CHECKS
//<> ------------------------------------------------------------
`ifndef NO_SuHld_TIMING_CHECKS   
   specify
      $setup(i_sdi, negedge i_sclk, ts_Dsu, su_flag);
      $hold(negedge i_sclk, i_sdi, ts_Dsu, hld_flag);
   endspecify
      always @(su_flag)  `SIM.printError(BFM_NAME, "Data setup timing violation detected. " );
      always @(hld_flag) `SIM.printError(BFM_NAME, "Data hold timing violation detected. " );
`endif

//<> ------------------------------------------------------------------------------------------------------------------------
//<> <<Custom IO port operations go here>>
//<> ------------------------------------------------------------------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> command processing for mux switch transition determination
   always @(Sw_Pos_Change) 
   begin
      #(ts_Td);   // propagation delay for output port update from SPI frame arrivial
      for (pidx = 0; pidx < NUM_DATA_PORTS; pidx = pidx + 1) begin        // for all ports, determine new switch output state per port
         o_data_port[pidx] = (sdin_frame[pidx] == 1'b0) ? i_data_port[pidx] : GND;      // select => ground, otherwise passthru
      end
      if (i_enable) `SIM.printMessage(BFM_NAME, {"Switch set to input ports = ", `V2INTSTR(sdin_frame)});
   end
   
endmodule

//* -----------------------------Instance template--------------------------------
//  --------------------------------*-----------------------------------
   // //<>--------------------------------------------------------------------
   // //<> ADG714 spi switch BFM 
   // //<>
   // bfm_ADG714_spi_sw
      // #( .BFM_NAME                  ("bfm_ADG714_spi_sw "),
         // //<> NOTE: Parameters below are Device Specific from Datasheet...
         // .NUM_DATA_PORTS       (8),    // number of total possible databits serial output string (From datasheet)
         // .NUM_CMD_BITS         (8),    // LTC2600=16, LTC2610=14, LTC2620=12, 
         // .DAISY_CHAIN_MODE     (1),
      // ) bfm_ADG714_spi_sw_inst
      // (
         // //<> DUT interface
         // .i_rst  (),      // serial transfer clock
         // .i_sclk  (),      // serial transfer clock
         // .i_sync_csn  (),      // serial transfer enable
         // .i_sdi   (),       // serial data in 
         // .o_sdo   (),       // serial data out 
         // //<> Switch ports
         // .i_data_port (),     // switch input ports [NUM_DATA_PORTS-1:0]
         // .o_data_port (),     // switch output ports [NUM_DATA_PORTS-1:0]
         // //<> testbench interface
         // .i_enable      (),       // testbench monitor enable control
         // .addr_code     ()      // buffer for address [NUM_ADDR_BITS-1:0]
      // );