//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_ADG731_spi_mux.sv
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : Jan 17, 2014
//--------------------------------------------------------------------
//Description : SPI Mux
//    - assumes gated SPI clock input (active only during sync_csn = LOW
//
//    - i_enable          --> used to disable BFM messages (but not error/warning) if desired
//                            
//
// Note: relies on System-Verilog syntax to enable 2D array ports
// datasheet: 
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2014-03-05 21:21:22 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

//<> SPI setup/hold timing check enable/disable (uncomment to disable)
// `define NO_SuHld_TIMING_CHECKS

`ifndef SIM
`define SIM tb.sim_management_inst
`endif

  module bfm_ADG731_spi_mux
   #( parameter BFM_NAME         = "bfm_ADG731_spi_mux",
      //<> SPI frame sizing (DO NOT ADJUST...used for port sizing)
      parameter NUM_DATA_PORTS   = 32,    // number of "analog" data ports on n:1 mux
      parameter NUM_CMD_BITS     = 3,
      parameter NUM_ADDR_BITS    = 5
   )
   (
      //<> DUT interface
      input wire  i_rst ,                                        // async clear
      input wire  i_sclk ,                                       // serial transfer clock
      input wire  i_sync_csn ,                                   // serial transfer enable/operation sync
      input wire  i_sdi ,                                        // serial data in 
      //<> Mux ports
      input  wire [31:0] i_data_port  [NUM_DATA_PORTS-1:0],      // "analog" mux inputs [NUM_DATA_PORTS-1:0]
      output reg  [31:0] o_data_port,                            // selected analog output
      //<> testbench interface
      input  wire                      i_enable ,                // testbench monitor enable control
      output reg  [NUM_CMD_BITS-1:0]   o_ctrl_code ,             // buffer for command
      output reg  [NUM_ADDR_BITS-1:0]  o_addr_code               // buffer for address
   );
   
//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS 
//<> ------------------------------------------------------------
   localparam MAX_FRAME_SIZE  = (NUM_CMD_BITS + NUM_ADDR_BITS);
   //<> timing specs  (from datasheet)
   localparam  ts_Dsu    = 5 ;        // (ns) data setup to SCLK rising (From datasheet)
   localparam  ts_Dhld   = 4.5;       // (ns) data hold from SCLK rising (From datasheet)
   localparam  ts_Td     = 15;        // (ns) break-before-make delay

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   integer frame_cntr = 0;
   integer fptr = 0;     // shift register index pointer
   string msg ;
   reg frame_good = 0;  // flag indicating a valid frame size recieved
   reg [MAX_FRAME_SIZE-1:0] sdin_frame;  // buffer input frame for command parsing
   reg su_flag, hld_flag;
   //<> SPI flow event strobes
   event Start_Of_Frame;
   event End_Of_Frame;
   event Frame_Process_Start;
   event Frame_Check_Done;
   event Mux_Pos_Change;
   int x;

      
   initial begin
      o_ctrl_code = 0;
      o_addr_code = 0;
      sdin_frame  = 0;
      for (x=0;x<NUM_DATA_PORTS; x=x+1) o_data_port[x] = 32'd0;
   end   
   
//<> ------------------------------------------------------------------------------------------------------------------------
//<> SPI INTERFACE
//<> ------------------------------------------------------------------------------------------------------------------------
   
   //<> ------------------------------------------------------------
   //<> watch for start of Frame event and trigger interal Event 
   //<>  - end of frame assumed to be rising edge of i_sync_csn
   always begin
      #10; // pad for simulation TB signal startup initialization
      while (1) begin
         @(negedge i_sync_csn) -> Start_Of_Frame;    // trigger internal event on start of frame condition
      end
   end
   always begin
      #10; // pad for simulation TB signal startup initialization
      while (1) begin
         @(posedge i_sync_csn) -> End_Of_Frame;    // trigger internal event on end of frame condition
      end
   end
   
   
   //<> ------------------------------------------------------------
   //<> SERIAL DATA INPUT CAPTURE
   //<> ------------------------------------------------------------
   
   //<> ------------------------------------------------------------
   //<>  Input frame index pointer init by start-of-frame
   always 
   begin
      if (i_rst) begin
         sdin_frame = 0;
         fptr = MAX_FRAME_SIZE;
         #1; // Avoid simulator lockup
      end 
      else begin
         @(Start_Of_Frame);
         frame_good = 1'b0;      // clear for new frame
         fptr = MAX_FRAME_SIZE;   // initialize with +2 to correct for increment and array index offsets
      end 
   end 

   //<> ------------------------------------------------------------
   //<> frame pointer adjust and input latch to internal frame 
   always @(posedge i_sclk) 
   begin
      if(i_sync_csn == 1'b0) begin   // avoid free-running clock conflicts
         fptr = fptr - 1;            // decrement pointer
         if (fptr >= 0)               // prevent pointer underrun (negative) violation on long frames
            sdin_frame[fptr] = i_sdi;   // latch data (in MSbit first)  
      end
   end
   
   
   //<> ------------------------------------------------------------
   //<> INPUT FRAME PROCESSING
   //<> ------------------------------------------------------------
   
   //<> ------------------------------------------------------------
   //<> - parse input frame at chipselect DEAssertion time
   always @(End_Of_Frame) 
   begin
      //<> confirm valid cycle event
      if ( fptr != 0) begin  // bad frame size detected
         frame_good = 0;   // indicate bad frame length of some sort
         if (fptr < 0) begin  // oversized frame detected
            `SIM.printError(BFM_NAME, "serial write fault detected - Frame too long");
         end
         else begin  // undersized frame detected
            `SIM.printError(BFM_NAME, "serial write fault detected - Frame too short");
         end
      end
      else begin  // frame size good
         frame_good = 1; // indicate the frame has a valid length
         if (i_enable) `SIM.printMessage(BFM_NAME, {"SPI xfer recieved ==> cmd= ", `V2HEXSTR(o_ctrl_code),", addr= ", `V2HEXSTR(o_addr_code) });
      end
      ->Frame_Check_Done;
   end 
   
   //<> ------------------------------------------------------------
   //<> map received frame to component testcase fields at end of transfer
   //<>  - only performed once frame check is complete as it relies on framecheck results
   //<>    - this help ensure no rogue command/operations from invalid-sized frames
   always @(Frame_Check_Done) 
   begin
      //<> map frame to testcase ports (ignores optional prefix)
      {o_ctrl_code, o_addr_code} = (frame_good) ? sdin_frame[MAX_FRAME_SIZE-1:0] : {MAX_FRAME_SIZE{1'bx}};
      ->Mux_Pos_Change;  // kick command processing for mux switch transition determination
   end

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
//<> MUX Operation
//<> ------------------------------------------------------------------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> command processing for mux switch transition determination
   always @(Mux_Pos_Change) 
   begin
      if (o_ctrl_code[1] === 1'b1) begin
         o_data_port = o_data_port;  // CSn=HIGH - retain previous state
         if (i_enable) `SIM.printMessage(BFM_NAME, {"CSn bit high - Mux outputs unchanged"});
      end
      else begin
         if (o_ctrl_code[2] === 1'b1) begin // ENn= disable switching
            o_data_port = 0;  // null all output            
            if (i_enable) `SIM.printMessage(BFM_NAME, {"EN bit high - Mux outputs disconnected"});
         end
         else begin           // process Address range and set mux if valid
            if(o_addr_code < NUM_DATA_PORTS) begin  // more binary combinations than ports, so perform range check
               #(ts_Td);
               o_data_port = i_data_port[o_addr_code];
               if (i_enable) `SIM.printMessage(BFM_NAME, {"Mux set to input port# = ", `V2INTSTR(o_addr_code)});
            end
            else              // o_addr_code outside valid index range
               `SIM.printError(BFM_NAME, {"SPI Address field out-of-bounds. o_addr_code=", `V2INTSTR(o_addr_code)});
         end
      end
   end

endmodule

//* -----------------------------Instance template--------------------------------
//  --------------------------------*-----------------------------------
   // //<>--------------------------------------------------------------------
   // //<> ADC725 SPI MUX BFM 
   // //<>
   // bfm_ADG731_spi_mux
      // #( .BFM_NAME                  ("bfm_ADG731_spi_mux "),
         // //<> NOTE: Parameters below are Device Specific from Datasheet...
         // .NUM_DATA_PORTS           (32),    // number of total possible databits serial output string (From datasheet)
         // .NUM_CMD_BITS          (3),   
         // .NUM_ADDR_BITS         (5),
      // ) bfm_ADG731_spi_mux_inst
      // (
         // //<> DUT interface
         // .i_rst  (),      // serial transfer clock
         // .i_sclk  (),      // serial transfer clock
         // .i_sync_csn  (),      // serial transfer enable
         // .i_sdi   (),       // serial data in 
         // //<> Mux ports
        // .i_data_port  (),      // "analog" mux inputs [NUM_DATA_PORTS-1:0]
        // .o_data_port  (),      // selected analog output
         // //<> testbench interface
         // .i_enable      (),       // testbench monitor enable control
         // .o_ctrl_code     (),      // buffer for command [NUM_CMD_BITS-1:0]
         // .o_addr_code     (),      // buffer for address [NUM_ADDR_BITS-1:0]
         // .sdin_frame    ()       // buffer for full frame
      // );