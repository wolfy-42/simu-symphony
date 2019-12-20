//*--------------------------------------------------------------------//
//
// Copyright (C) 2006 Fidus Systems Inc.
//
// Project       : simu 
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Sample top level for Verilog simulation environment.
// Updated       : date / author - comments           
//--------------------------------------------------------------------//

`include "./include_parameters.v"

//* Module declaration
  module top_simuverilog    
    (
     // Clocks
     input wire          i_CLK_200p,   //ref clock 200MHz, differential
     input wire          i_CLK_200n,   //ref clock 200MHz   
     input wire          i_RESET_n,    //global reset input

     // test bus
     output wire [7:0]    ov_FPGA_TEST, // testbus
    
     // LEDs on when high
     output wire          o_LED         // turns LED on when you want

     );
   

   
//* Variables 
   reg [15:0] reset;
 
   
   
//* Assigns

                 
                
//* Modules instantiations

//* module1   
module1  module1_inst ( 
                        .i_CLK             (i_CLK_200p),      // comment  
                        .i_RESET_n         (i_RESET_n),                         
                        .ov_FPGA_TEST      (ov_FPGA_TEST),    // comment
	                    .o_LED             (o_LED)
                        );
   
   
//* module2
 


	                    
endmodule 

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:
