//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_74LV16244_buf.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : July 10st, 2012
//--------------------------------------------------------------------
//Description : model of the 7400 series 16-bit tri-state buffer
// Datasheet: http://www.ti.com/lit/ds/symlink/sn74lvcz16244a.pdf
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2012-08-29 11:19:28 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines
`timescale 1ns / 1ps

module bfm_74LV16244_buf
   #( parameter BFM_NAME = "bfm_74LV16244_buf"
   )
   (
      //<> inputs
      input  wire [3:0] i_data_1A ,
      input  wire [3:0] i_data_2A ,
      input  wire [3:0] i_data_3A ,
      input  wire [3:0] i_data_4A ,
      //<> outputs
      output wire [3:0] o_data_1Y ,
      output wire [3:0] o_data_2Y ,
      output wire [3:0] o_data_3Y ,
      output wire [3:0] o_data_4Y ,
      //<> control
      input  wire [3:0] i_oe_n 
   );

//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS 
//<> ------------------------------------------------------------
   localparam ts_PD = 4;   // 4ns max delay (datasheet)

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------

//<> ------------------------------------------------------------
//<> GATE EMULATION
//<> ------------------------------------------------------------ 
   //<> Port A
   assign #(ts_PD) o_data_1Y[0] = (i_oe_n[0] == 1'b0) ? i_data_1A[0] : 1'bZ ;
   assign #(ts_PD) o_data_1Y[1] = (i_oe_n[0] == 1'b0) ? i_data_1A[1] : 1'bZ ;
   assign #(ts_PD) o_data_1Y[2] = (i_oe_n[0] == 1'b0) ? i_data_1A[2] : 1'bZ ;
   assign #(ts_PD) o_data_1Y[3] = (i_oe_n[0] == 1'b0) ? i_data_1A[3] : 1'bZ ;
   
   //<> Port B
   assign #(ts_PD) o_data_2Y[0] = (i_oe_n[1] == 1'b0) ? i_data_2A[0] : 1'bZ ;
   assign #(ts_PD) o_data_2Y[1] = (i_oe_n[1] == 1'b0) ? i_data_2A[1] : 1'bZ ;
   assign #(ts_PD) o_data_2Y[2] = (i_oe_n[1] == 1'b0) ? i_data_2A[2] : 1'bZ ;
   assign #(ts_PD) o_data_2Y[3] = (i_oe_n[1] == 1'b0) ? i_data_2A[3] : 1'bZ ;
   
   //<> Port C
   assign #(ts_PD) o_data_3Y[0] = (i_oe_n[2] == 1'b0) ? i_data_3A[0] : 1'bZ ;
   assign #(ts_PD) o_data_3Y[1] = (i_oe_n[2] == 1'b0) ? i_data_3A[1] : 1'bZ ;
   assign #(ts_PD) o_data_3Y[2] = (i_oe_n[2] == 1'b0) ? i_data_3A[2] : 1'bZ ;
   assign #(ts_PD) o_data_3Y[3] = (i_oe_n[2] == 1'b0) ? i_data_3A[3] : 1'bZ ;
   
   //<> Port D
   assign #(ts_PD) o_data_4Y[0] = (i_oe_n[3] == 1'b0) ? i_data_4A[0] : 1'bZ ;
   assign #(ts_PD) o_data_4Y[1] = (i_oe_n[3] == 1'b0) ? i_data_4A[1] : 1'bZ ;
   assign #(ts_PD) o_data_4Y[2] = (i_oe_n[3] == 1'b0) ? i_data_4A[2] : 1'bZ ;
   assign #(ts_PD) o_data_4Y[3] = (i_oe_n[3] == 1'b0) ? i_data_4A[3] : 1'bZ ;

   // assign o_data_1Y = (i_oe_n[0] == 1'b0) ? i_data_1A : 4'bZZZZ ;
   // assign o_data_2Y = (i_oe_n[1] == 1'b0) ? i_data_2A : 4'bZZZZ ;
   // assign o_data_3Y = (i_oe_n[2] == 1'b0) ? i_data_3A : 4'bZZZZ ;
   // assign o_data_4Y = (i_oe_n[3] == 1'b0) ? i_data_4A : 4'bZZZZ ;
   
endmodule
 
// //<> 16bit tristate buffer model (74LV16244)
// bfm_74LV16244_buf
   // #( .BFM_NAME ("bfm_74LV16244_buf")
   // ) bfm_74LV16244_buf_inst
   // (
      // //<> inputs
      // .i_data_1A  (),
      // .i_data_2A  (),
      // .i_data_3A  (),
      // .i_data_4A  (),
      // //<> outputs
      // .o_data_1Y  (),
      // .o_data_2Y  (),
      // .o_data_3Y  (),
      // .o_data_4Y  (),
      // //<> control
      // .i_oe_n  ()
   // );
