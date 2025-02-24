//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_ADG725_spi_mux.sv
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

`ifndef SIM
`define SIM tb.sim_management_inst
`endif

//<> SPI setup/hold timing check enable/disable (uncomment to disable)
// `define NO_SuHld_TIMING_CHECKS


  module bfm_ADG725_spi_mux
   #( parameter BFM_NAME                  = "bfm_ADG725_spi_mux",
      //<> SPI frame sizing (DO NOT ADJUST...used for port sizing)
      parameter NUM_DATA_PER_PORT         = 16,    // number of "analog" data ports on n:1 mux
      parameter NUM_PORTS                 = 2,     // number of "analog" data ports on n:1 mux
      parameter NUM_CMD_BITS              = 3,     // number of command bits
      parameter NUM_ADDR_BITS             = 5,     // number of address bits
      parameter DATA_VEC_SIZE             = 32     // number of bits used for values on each input data vector
   )
   (
      //<> DUT interface
      input wire  i_rst ,      // async clear
      input wire  i_sclk ,      // serial transfer clock
      input wire  i_sync_csn ,  // serial transfer enable/operation sync
      input wire  i_sdi ,       // serial data in 
      //<> Mux ports
      input  wire [DATA_VEC_SIZE-1:0] i_data_port_A  [NUM_DATA_PER_PORT-1:0],      // "analog" mux inputs [NUM_DATA_PER_PORT-1:0] port A
      input  wire [DATA_VEC_SIZE-1:0] i_data_port_B  [NUM_DATA_PER_PORT-1:0],      // "analog" mux inputs [NUM_DATA_PER_PORT-1:0] port B
      output reg  [DATA_VEC_SIZE-1:0] o_data_port_A = 0,                               // selected analog output port A
      output reg  [DATA_VEC_SIZE-1:0] o_data_port_B = 0,                               // selected analog output port B
      //<> testbench interface
      input wire                            i_enable ,       // testbench monitor enable control
      output reg [NUM_CMD_BITS-1:0]         o_ctrl_code ,      // buffer for command
      output reg [NUM_ADDR_BITS-1:0]        o_addr_code       // buffer for address
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

   //<> SPI frame parsing signals
   integer frame_cntr = 0;
   integer fptr = 0;     // shift register index pointer
   string msg ;
   reg frame_good = 0;  // flag indicating a valid frame size recieved
   reg [MAX_FRAME_SIZE-1:0] sdin_frame;  // buffer input frame for command parsing

   //<> SPI flow event strobes
   event Start_Of_Frame;
   event End_Of_Frame;
   event Frame_Process_Start;
   event Frame_Check_Done;
   event Mux_Pos_Change;
   
   reg su_flag, hld_flag;     // setup/hold timing fault flags
   
   //<> aliases for command code bits
   reg cmd_en_n ; // enable bit
   reg cmd_csa_n;
   reg cmd_csb_n;
   
   //<> selected input for each output port
   reg [3:0] portA_pos = 0;      // Mux selected input for portA
   reg [3:0] portB_pos = 0;      // Mux selected input for portB
   
   int x;
   
   initial begin
      o_ctrl_code = 0;
      o_addr_code = 0;
      sdin_frame  = 0;
      for (x=0;x<NUM_DATA_PER_PORT; x=x+1) o_data_port_A[x] = 32'd0;
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
      //<> --- Aliases for bits within command code (aids code readability)
      cmd_en_n   = o_ctrl_code[2];
      cmd_csa_n  = o_ctrl_code[1];
      cmd_csb_n  = o_ctrl_code[0];
      ->Mux_Pos_Change;  // kick command processing for mux switch transition determination
   end

   //<> ------------------------------------------------------------
   //<> SPI BUS INPUT TIMING CHECKS
   //<> ------------------------------------------------------------      
   `ifndef NO_SuHld_TIMING_CHECKS
      specify
         $setup(i_sdi, negedge i_sclk, ts_Dsu, su_flag);
         $hold(negedge i_sclk, i_sdi, ts_Dhld, hld_flag);
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
      #(ts_Td);   // Mux input->output propagation timing delay
      if (cmd_en_n === 1'b1) begin // ENn= disable switching
         if (i_enable) `SIM.printMessage(BFM_NAME, {"EN bit high - Mux outputs disconnected"});
      end
      else begin
         if (o_addr_code[3:0] < NUM_DATA_PER_PORT) begin  // verify address is not greater than # of ports... 
            case ({cmd_csa_n, cmd_csb_n})                 // << NOTE: Active LOW logic >>  Arranged as per SPI frame for waveform comparison ease
               2'b01 : begin     // port A selected
                     portA_pos = o_addr_code[3:0];    // set new mux position for port A
                     portB_pos = portB_pos;           // retain existing mux position for port B
                     o_data_port_A = i_data_port_A[o_addr_code[3:0]];
                     o_data_port_B = o_data_port_B;
                  end
               2'b10 : begin     // Port B selected
                     portA_pos = portA_pos;           // retain existing mux position for port A
                     portB_pos = o_addr_code[3:0];    // set new mux position for port B
                     o_data_port_A = o_data_port_A;
                     o_data_port_B = i_data_port_B[o_addr_code[3:0]];
                  end
               2'b00 : begin     // Both ports selected
                     portA_pos = o_addr_code[3:0];    // set new mux position for port A
                     portB_pos = o_addr_code[3:0];    // set new mux position for port B
                     o_data_port_A = i_data_port_A[o_addr_code[3:0]];
                     o_data_port_B = i_data_port_B[o_addr_code[3:0]];
                  end
               default: begin    // neither port selected 
                     portA_pos = portA_pos;           // retain existing mux position for port A
                     portB_pos = portB_pos;           // retain existing mux position for port B
                     o_data_port_A = o_data_port_A;
                     o_data_port_B = o_data_port_B;
                  end
            endcase
            if (i_enable) `SIM.printMessage(BFM_NAME, {"Mux port A = input #  ", `V2INTSTR(portA_pos)});
            if (i_enable) `SIM.printMessage(BFM_NAME, {"Mux port B = input #  ", `V2INTSTR(portB_pos)});
         end
         else begin
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
   // bfm_ADG725_spi_mux
      // #( .BFM_NAME                  ("bfm_ADG725_spi_mux "),
         // //<> NOTE: Parameters below are Device Specific from Datasheet...
         // .NUM_DATA_PER_PORT           (32),    // number of total possible databits serial output string (From datasheet)
         // .NUM_CMD_BITS          (3),   
         // .NUM_ADDR_BITS         (5),
      // ) bfm_ADG725_spi_mux_inst
      // (
         // //<> DUT interface
         // .i_rst  (),      // serial transfer clock
         // .i_sclk  (),      // serial transfer clock
         // .i_sync_csn  (),      // serial transfer enable
         // .i_sdi   (),       // serial data in 
         // //<> Mux ports
        // .i_data_port_A  (),      // "analog" mux inputs [NUM_DATA_PER_PORT-1:0]
        // .o_data_port_A  (),      // selected analog output
         // //<> testbench interface
         // .i_enable      (),       // testbench monitor enable control
         // .o_ctrl_code     (),      // buffer for command [NUM_CMD_BITS-1:0]
         // .o_addr_code     (),      // buffer for address [NUM_ADDR_BITS-1:0]
         // .sdin_frame    ()       // buffer for full frame
      // );