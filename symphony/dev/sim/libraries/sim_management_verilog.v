//-------------------------------------------------------------------
//
// Copyright (C) 2012 Fidus Systems Inc.
//
// Project       : simu
// Author        : Arnold Balisch
// Created       : 2012-05-10
//--------------------------------------------------------------------
// Description   : This include library is responsible for implementing tasks that:
//    - aid in testcase transcript logging to an external logfile 
//    - testbench startup/finish routines
//    - global error and warning counters and flags
//
//   Usage: intended for include in testbench and testcases
//
//   Available User routines:
//    - task printMessage (input string caller, input string msg);
//    - task printWarning (input string caller, input string msg);
//    - task printError (input string caller, input string msg);
//    - task printFatalError (input string caller, input string msg);
//    - task testComplete ();
//
// Updated       : 2015-08-10 / Arnold B. - fixes
// Updated       : date / author - comments
//-------------------------------------------------------------------

//<> check to see if module already included by calling module...avoids duplicate includes
`ifndef SIM_MANAGEMENT_VERILOG
   `define SIM_MANAGEMENT_VERILOG
   
//* Module declaration
module sim_management_verilog () ;
 

   integer globalErrorCounter   = 0;
   integer globalWarningCounter = 0;
   `define cN 200 // Max characters in a string.
   
   event globalErrorEvent;
   event globalWarningEvent;

   
   
   //<> The allBfmsPleaseDoEndOfSimCheck event is only activated once by the testComplete task.
   //<> This event should not be activated anytime else by any other task.
   event allBfmsPleaseDoEndOfSimCheck;

   //* ============================= I/O Tasks =================================

   //<>------------------------------------------------------------------------------------
   //* Task printMessage
   // Purpose: To print the input message in a standard format, starting with the 
   //          name of the module which invoked this task and the label MESSAGE.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the message to be displayed
   // Outputs: none
   task printMessage (input reg [8*`cN:1] caller, input reg [8*`cN:1] msg);
      string s_caller, s_msg, s_temp;
      begin
          $cast(s_caller, caller);
          $cast(s_msg, msg);
          s_temp = {"MESSAGE (", s_caller, "): ", s_msg};
`ifndef ERROR_ONLY
    $display(s_temp);
`endif         
      end
   endtask // printMessage
   

   //<>------------------------------------------------------------------------------------
   //* Task printWarning
   // Purpose: To print the input warning message in a standard format, starting with the 
   //          name of the module which invoked this task and the label WARNING.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the warning message to be displayed
   // Outputs: none
   task printWarning (input reg [8*`cN:1] caller, input reg [8*`cN:1] msg);
      string s_temp;
      string s_cntrstr;
       string s_caller, s_msg;
      begin
          globalWarningCounter = globalWarningCounter + 1;
         $sformat(s_cntrstr,"%0d", globalWarningCounter);  // convert integer counter to text string equivalent

          $cast(s_caller, caller);
          $cast(s_msg, msg);
         s_temp = {"-WARNING_",s_cntrstr,"- (", s_caller, "): ", s_msg};
         $display(s_temp);
         ->globalWarningEvent;
      end
   endtask // printWarning

   //<>------------------------------------------------------------------------------------
   //* Task printError
   // Purpose: To print the input error message in a standard format, starting with the 
   //          name of the module which invoked this task and the label ERROR.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the error message to be displayed
   // Outputs: none
   task printError (input reg [8*`cN:1] caller, input reg [8*`cN:1] msg);
      string s_temp;
      string s_cntrstr;
      string s_caller, s_msg;
      begin
          globalErrorCounter = globalErrorCounter + 1;
         $sformat(s_cntrstr,"%0d", globalErrorCounter);  // convert integer counter to text string equivalent

          $cast(s_caller, caller);
          $cast(s_msg, msg);
         s_temp = {"<< ERROR_",s_cntrstr," >> (", s_caller, "): ", s_msg}; 
         $display(s_temp);
         ->globalErrorEvent;
      end
   endtask // printError

   //<>------------------------------------------------------------------------------------
   //* Task printFatalError
   // Purpose: To print the input error message in a standard format, starting with the 
   //          name of the module which invoked this task and the label FATAL_ERROR.
   //          - then terminates simulation!
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the error message to be displayed
   // Outputs: none
   task printFatalError (input reg [8*`cN:1] caller, input reg [8*`cN:1] msg);
      string s_temp;
      string s_caller, s_msg;
      begin
          $cast(s_caller, caller);
          $cast(s_msg, msg);
         s_temp = {"<<<< FATAL_ERROR >>>> (", s_caller, "): ", s_msg}; 
         $display(s_temp);
         globalErrorCounter = globalErrorCounter + 1;
         ->globalErrorEvent;
         $finish;
      end
   endtask // printError
   
   //* =========================== testComplete task ==========================

   //<>------------------------------------------------------------------------------------
   //* Task testComplete
   // Purpose: This task cleanly terminates the simulation. It reports the simulation
   //          status (pass/fail) based on the values of the globalErrorCounter. The
   //          simulation should be ended no other way than by invoking this task.
   // Inputs : none
   // Outputs: none
   task testComplete ();
      begin
         $display ("\n================================================================");
         $display ("====================== END OF SIMULATION =======================");
         $display ("================================================================\n");
         
         //<> First, make sure no BFM needs to report any further messages, warnings or errors
         //<> by letting them know we are about to end the simulation.
         ->allBfmsPleaseDoEndOfSimCheck;
         #1;

         $display ("WARNINGS: %d", globalWarningCounter);
         $display ("ERRORS:   %d", globalErrorCounter);
         
         if (globalErrorCounter == 0)
           $display ("\n\nSIMULATION STATUS: PASS\n\n");
         else
           $display ("\n\nSIMULATION STATUS: FAIL\n\n");

         $stop(2);
      end
   endtask // testComplete
  

   
endmodule // sim_management

//<> close start of file `ifndef
`endif

//<> -------------------------------------END-------------------------------------------------

