//*--------------------------------------------------------------------//
//
// Copyright (C) 2006 Fidus Systems Inc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Module 1 template for Verilog and SystemVerilog 
//                 simulation environment
// Updated       : Date / author - comments           
//--------------------------------------------------------------------//

`include "./include_parameters.v"

//* Module declaration
  module module1    
    (
     // Clocks
     input wire          i_CLK,        //ref clock 200MHz, differential
     input wire          i_RESET_n,    //global reset input

     // test bus
     output wire [7:0]    ov_FPGA_TEST, // testbus
    
     // LEDs on when high
     output wire          o_LED         // turns LED 'on' when you want

     );
   

   
//* Variables 
   wire [15:0] local_clk;
    
   
//* Assigns
   // get some test points
   assign local_clk = i_CLK & i_RESET_n;   
   assign ov_FPGA_TEST = {5'h00,local_clk,i_RESET_n,i_CLK};

   // monitor the reset on a LED
   assign     o_LED = i_RESET_n;
      
                
//* Modules instantiations;
//* module1; 

//* module2;
 


	                    
endmodule 

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:
