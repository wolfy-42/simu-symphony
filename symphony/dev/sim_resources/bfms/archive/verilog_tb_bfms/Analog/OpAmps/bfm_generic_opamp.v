//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_opamp.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : Jan 17, 2014
//--------------------------------------------------------------------
//Description : generic OpAmp BFM
//    - Gain is passed as an integer multiplier.  
//          Vout = Vin * Gain
//
//   NOTE: current implementation non-inverting, & positive-only input/output values
//
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2014-02-28 20:44:58 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`ifndef SIM
`define SIM tb.sim_management_inst
`endif

  module bfm_opamp
   #( parameter BFM_NAME                  = "bfm_opamp",
      parameter ts_PROP                   = 1       // Amplifier In->Out Propagation delay (ns)
   )
   (
      //<> Gain control
      input integer i_gain,              // integer gain value
      //<> "analog" ports
      input  wire [31:0] i_Vin ,         // analog signal in
      output reg  [31:0] o_Vout,         // amplified analog signal out
      //<> testbench interface
      input wire i_enable                // debug message enable
   );
   
//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS 
//<> ------------------------------------------------------------

   
//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   integer multiplier = 1;
   integer int_Vout = 0;
   
//<> ------------------------------------------------------------------------------------------------------------------------
//<> AMPLIFIER 
//<> ------------------------------------------------------------------------------------------------------------------------
   
   //<> ------------------------------------------------------------
   //<> GAIN CONTROL
   //<>  - adjust output based on numeric binary value of gain input
   //<>  - effect of i_gain determined by SCALING_POLARITY setting (1=amplify, 0=attenuate)
   //<>  - SCALING_FACTOR used for defining linear scale of amp scale/i_gain step
   //<>  - converts binary "gain" input to an integer "multiplier"
   always @(i_Vin, i_gain)
   begin
         multiplier = (i_gain == 0)? 1 : i_gain;    // avoid zero-gain as multiplier 
         int_Vout   = (i_Vin * multiplier);         // output increases as i_gain value increases
   end 

   //<> ------------------------------------------------------------
   //<> map output with propagation delay
   assign #(ts_PROP) o_Vout =  int_Vout;  
   
   //<> ------------------------------------------------------------
   //<> (debug option) - output changes in amplifier gain to logfile/transcript
   always @(i_gain)
   begin
      if (i_enable) `SIM.printMessage(BFM_NAME, {"OpAmp Gain change detected:  gain = ", `V2INTSTR(i_gain)});
   end 

endmodule

//* -----------------------------Instance template--------------------------------
//  --------------------------------*-----------------------------------
   // //<>--------------------------------------------------------------------
   // //<> Generic OpAmp model
   // //<>  - Integer gain mulitplier (non-inverting, positive I/O only)
   // bfm_opamp
      // #( .BFM_NAME               ("bfm_opamp"),
      //    .ts_PROP                (1)   // Amplifier In->Out Propagation delay (ns)
      // ) bfm_opamp_inst
      // (
      // //<> Gain control
      // .i_gain  (),          // Integer gain multiplier
      // //<> "analog" ports
      // .i_Vin    (),         // analog signal in (integer)
      // .o_Vout   (),         // amplified analog signal out (integer)
      // //<> testbench interface
      // .i_enable             // debug message enable
      // );