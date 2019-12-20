//*-------------------------------------------------------------------//
//
// Copyright (C) 2009 Fidus Systems Inc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : template for module level test case
// Updated       : date / author - comments
//--------------------------------------------------------------------//

//* Module declaration

  module test_case();

// System Verilog Simulation management package
   
// BFM package   

  
//* Variables and parameters ;
   sim_management_verilog s();    
   parameter  TC_NAME = "tc_fidus_clock_reset_verilog";
   integer seed;
   real      rrr = 3.14;
   reg [31:0] hhh = 32'habcd1234;
   integer j= 14;
   reg [0:7999] msg = "";
   
//* ***************************** Test case body **********************************************
   initial
     begin                          
//* Initialize the simulation
        msg = {"-------> ",TC_NAME," testcase <-------"};  
        s.printMessage (TC_NAME,msg);  
        s.printMessage (TC_NAME, "Global Reset asserted");          
        bfm_reset_gen_inst.global_reset("assert");         
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5.5ns");
        bfm_clk200Mhz_inst.set_clock_period(5.5);       
       
//* Initialize the random data generator        
        #1;        
 
//* release the reset randomly       
        #2000; 
        #(16'h00ff );
        bfm_reset_gen_inst.global_reset("release");  
        
//* check reset level
        #2000;        
	if (tb.o_LED == 1'b1) s.printMessage (TC_NAME, "RESET output released OK after initial global reset");
	else                  s.printError   (TC_NAME, "RESET output released Bad after initial global reset ");

//* print  examples
        //$display ("%g ns Compare task Data Base centroid %d with expected : h = %h  r = %f", $time,j,hhh,rrr);       
        s.printMessage (TC_NAME, "Message test.");
        s.printWarning (TC_NAME, "Warning test.");
        s.printError (TC_NAME, "Error test.");
        s.printMessage (TC_NAME, "Message test.");
        s.printWarning (TC_NAME, "Warning test.");
        s.printError (TC_NAME, "Error test.");

        
//* Simulation End 
        #1000;
        msg = {"-------> ",TC_NAME," testcase $RCSfile: tc_clk_rst.sv,v $ $Revision: 1.1 $ $Date: 2014-12-08 20:01:49 $ <-------"};
        s.printMessage (TC_NAME,msg); 
        s.testComplete;             
     end
        
     
endmodule // test_case

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:
