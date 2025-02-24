//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_Nto1_mux.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : May 24st, 2012
//--------------------------------------------------------------------
//Description : BFM for emulation of an N:1 mux
//    NOTE: 2D array used on input port to permit scaleability
//    NOTE: i_ctrl directly indexes input array to select output
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.3 $    $Date: 2012-06-13 09:55:33 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines


module bfm_Nto1_mux
   #( parameter BFM_NAME             = "bfm_Nto1_mux ",
      parameter NUM_VALID_DATA_BITS  = 14,
      parameter NUM_PORTS            = 16,
      parameter NUM_CTRL_BITS        = 4,       // typically use "tb.lib_math_inst.clogb2(NUM_PORTS)" to complete this 
      parameter ts_prop = 1                     // delay (ns) from input/ctrl change to output valid
   )
   (
      input  wire [NUM_VALID_DATA_BITS-1:0]  i_inport [NUM_PORTS-1:0],     // NOTE: 2D array of input ports
      input  wire [NUM_CTRL_BITS-1:0]        i_ctrl,                       // Mux select
      output reg  [NUM_VALID_DATA_BITS-1:0]  o_outport                     // selected output
   );
   
   //<> ------------------------------------------------------------
   //<> Perform data output on any input changes (with propagation delay)
   always @(*)
   begin
      #(ts_prop) o_outport = i_inport[i_ctrl];  
   end
   
endmodule



//<>--------------------------------------------------------------------
//<> MUX BFM instance
// bfm_Nto1_mux
   // #( .BFM_NAME             ("bfm_Nto1_mux "),
      // .NUM_VALID_DATA_BITS  (14),      // number of valid databits per port
      // .NUM_PORTS            (16),       // number of input ports to Mux
      // .NUM_CTRL_BITS        (4),       // alternate method => use "(tb.lib_math_inst.clogb2(NUM_PORTS))" to calculate value from #ports
      // .ts_prop              (1)        // propagation delay from input/ctrl change to output valid (ns)
   // ) Mux_inst
   // (
      // .i_inport (),        // NOTE: 2D array of input ports
      // .i_ctrl  (),         // Mux select
      // .o_outport ()        // selected output
   // );