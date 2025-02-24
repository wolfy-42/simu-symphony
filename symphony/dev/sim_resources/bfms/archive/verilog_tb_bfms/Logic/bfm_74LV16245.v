//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_74LV16245_buf.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : July 10st, 2012
//--------------------------------------------------------------------
//Description : model of the 7400 series 16-bit bi-directional tristate buffer
//
// Datasheet: http://www.ti.com/lit/ds/symlink/sn74lvcz16245a.pdf
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2012-08-29 11:19:28 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

module bfm_74LV16245_buf
   #( parameter BFM_NAME   = "bfm_74LV16245_buf"
   )
   (
      //<> inputs
      inout  wire [7:0] io_data_1A ,
      inout  wire [7:0] io_data_2A ,
      //<> outputs
      inout  wire [7:0] io_data_1B ,
      inout  wire [7:0] io_data_2B ,
      //<> controls
      input  wire [1:0] i_dir, 
      input  wire [1:0] i_oe_n 
   );

//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS 
//<> ------------------------------------------------------------   
   localparam ts_PD           = 4;           // max pin->pin propagatiopn delay (datasheet)
   localparam TRISTATE_VALUE  = 8'bZZZZZZZZ;

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------

//<> ------------------------------------------------------------
//<> GATE EMULATION
//<> ------------------------------------------------------------ 
   //<> channel 1 B-side
   assign #(ts_PD) io_data_1A = (i_dir[0] == 1'b1) ? TRISTATE_VALUE 
                              : (i_oe_n[0] == 1'b0) ? io_data_1B : TRISTATE_VALUE ; 
   
   //<> channel 1 B-side
   assign #(ts_PD) io_data_1B = (i_dir[0] == 1'b0) ? TRISTATE_VALUE 
                              : (i_oe_n[0] == 1'b0) ? io_data_1A : TRISTATE_VALUE ; 

   //<> channel 2 A-side
   assign #(ts_PD) io_data_2A = (i_dir[1] == 1'b1) ? TRISTATE_VALUE 
                              : (i_oe_n[1] == 1'b0) ? io_data_2B : TRISTATE_VALUE ; 
   
   //<> channel 2 B-side
   assign #(ts_PD) io_data_2B = (i_dir[1] == 1'b0) ? TRISTATE_VALUE 
                              : (i_oe_n[1] == 1'b0) ? io_data_2A : TRISTATE_VALUE ; 

   
endmodule


//<> ------------------------------------------------------------
//<> INSTANCE TEMPLATE
//<> ------------------------------------------------------------

// //<> ------------------------------------------------------------
// //<> 16bit Bidirectional tristate buffer model (74LV16245)
// bfm_74LV16245_buf
   // #( .BFM_NAME ("bfm_74LV16245_buf")
   // ) bfm_74LV16245_inst
   // (
      // //<> inputs
      // .io_data_1A  (),
      // .io_data_2A  (),
      // //<> outputs
      // .io_data_1B  (),
      // .io_data_2B  (),
      // //<> controls
      // .i_dir       (), 
      // .i_oe_n      ()
   // );