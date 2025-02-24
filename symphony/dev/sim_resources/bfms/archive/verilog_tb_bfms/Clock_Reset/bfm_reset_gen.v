//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//Filename    : bfm_reset_gen.v
//Project     : RIPL
//Author      : Chris Hesse
//Created     : Sept. 28, 2006
//--------------------------------------------------------------------
//Description : Reset generator. (active LOW)
// tasks:
//    - global_reset()
//
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2013-10-28 17:31:45 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

module bfm_reset_gen
   #( parameter BFM_NAME = "bfm_reset_gen",     // instance name for Logfile messages
      parameter RESET_NAME = "unnamed_reset",   // Name of reset signal 
      parameter RST_INITIAL = 0                 // initial POR state of reset line
   )
   (  
      output reg  o_bfm_rst_n = RST_INITIAL     
   );


//<>  ----------------------------------------------------------------
//<> ----------------------- task and function definitions ----------

//<> Assert/Release the reset signal;
   task global_reset(
         input string action);   // valid options are "assert" and "release"
      begin
         if ( action == "assert")
           begin
              o_bfm_rst_n = 1'b0;
              sim_management_inst.printMessage (BFM_NAME," Reset asserted ");
           end          
         else
           begin
              o_bfm_rst_n = 1'b1;
               sim_management_inst.printMessage (BFM_NAME," Reset released ");             
           end
      end
   endtask
   
endmodule
