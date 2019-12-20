//*--------------------------------------------------------------------//
//
// Copyright (C) 2006 Fidus Systems Inc.
//
// Project       : simu
// Author        : Chris Hesse
// Created       : 2006-09-28
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Reset generator.
// Updated       : date / author - comment
//--------------------------------------------------------------------//

module fidus_reset_gen_bfm (
                     output reg  o_bfm_rst_n = 0
                      );

   parameter BFM_NAME = "bfm_reset_gen";
   parameter RESET_NAME = "unnamed_reset";
   


//  ----------------------------------------------------------------
//* ----------------------- task and function definitions ----------

//* Assert/Release the reset signal;
   task global_reset(
         input reg[10:1] action);
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
