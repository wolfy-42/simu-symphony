//*--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2007-11-01
//--------------------------------------------------------------------//
// Description   : Simulation management package with PASS/FAIL/etc. functions
// Updated       : date / author - comments
//--------------------------------------------------------------------//



package sim_management_pkg;

`define CMD_ARG_COLOUR 1


   localparam QUIET = 1;
   enum {
      ERRLEVEL_PASS    = -1,
      ERRLEVEL_MESSAGE = 0,
      ERRLEVEL_MESSAGEBOLD = 1,
      ERRLEVEL_WARNING = 2,
      ERRLEVEL_ERROR   = 3,
      ERRLEVEL_FATAL   = 4
   } eERRLEVEL;

class sim_management ;
   static int globalErrorCounter   = 0;
   static int globalWarningCounter = 0;
   static int globalPassCounter = 0;
   static string debug = "on";  // "on", "off", "all" to report all modules debug messages
   static string debug_file_names [string];
   static bit initDone = 0;
   static string testcase_name = "not_initialized_testcase_name";   
   static event allBfmsPleaseDoEndOfSimCheck;

   `ifdef XILINX_SIMULATOR  // xsim does not support static events
       event globalFatalErrorEvent;
   `else
       static event globalFatalErrorEvent;
   `endif

// black - 30
// red - 31
// green - 32
// yellow - 33
// blue - 34
// magenta - 35
// cyan - 36
// lightgray - 37

// \033[0m - is the default color for the console
// \033[0;#m - is the color of the text, where # is one of the codes mentioned above
// \033[1m - makes text bold
// \033[1;#m - makes colored text bold**
// \033[2;#m - colors text according to # but a bit darker
// \033[4;#m - colors text in # and underlines
// \033[7;#m - colors the background according to #
// \033[9;#m - colors text and strikes it

    static string colour_def = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0m"; // default consol colour
    static string colour_tmp = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0m"; // temporary colour
    static string colour_red = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;31m";
    static string colour_dred = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;31m";
    static string colour_green = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;32m";
    static string colour_dgreen = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;32m"; // dark green
    static string colour_yellow = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;33m"; // yellow
    static string colour_blue = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;34m";
    static string colour_dblue = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;34m";  // dark blue
    static string colour_cyan = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;36m";
    static string colour_dcyan = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;36m";
    static string colour_purple = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;35m";
    static string colour_dpurple = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;35m";
    static string colour_brown = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;33m";
    static string colour_dbrown = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;33m";
    static string colour_bold = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;1m";
    static string colour_inverse = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;7m";

   static int seed = 0;

   // set seed  
   static function void set_seed (int seedin = 0);
      seed = seedin;
   endfunction;

   static function get_seed ();
      return seed;
   endfunction;

   // works only with 32bit Hex Max!!
   static function void print (string file_name = "file_name",
                        string input_message = "",
                        real in1 = "",
                        real in2 = "",
                        real in3 = "",
                        real in4 = "",
                        real in5 = "",
                        real in6 = "",
                        real in7 = "",
                        real in8 = "",
                        real in9 = "",
                        real in10 = "",
                        real in11 = "",
                        real in12 = "",
                        real in13 = "",
                        real in14 = "",
                        real in15 = "",
                        real in16 = "",
                        real in17 = "",
                        real in18 = "",
                        real in19 = "",
                        real in20 = ""
                        );
      //string colour_tmp = "";
      string list [21];
      real in;
      int iin;
      int length,id,number;
      string char,message;
      integer tmp;
      list[1:20] = {"in1","in2","in3","in4","in5","in6","in7","in8","in9","in10","in11","in12","in13","in14","in15","in16","in17","in18","in19","in20"};
      message = "";
      length = input_message.len();
      id = 0;
      for (int i =0; i <= length ;i++)
        begin
           number = 0;
           char = string'(input_message.getc(i));
           if (char == "%")
             begin
                id++;
                number = 1;
                case(id)
                  1: in = in1;
                  2: in = in2;
                  3: in = in3;
                  4: in = in4;
                  5: in = in5;
                  6: in = in6;
                  7: in = in7;
                  8: in = in8;
                  9: in = in9;
                  10: in = in10;
                  11: in = in11;
                  12: in = in12;
                  13: in = in13;
                  14: in = in14;
                  15: in = in15;
                  16: in = in16;
                  17: in = in17;
                  18: in = in18;
                  19: in = in19;
                  20: in = in20;
                endcase

                char = string'(input_message.getc(++i));
                case(char)
                  "d","g","t","f": begin
                     char.realtoa(in);
                    // $display("rta",char);
                  end
                  "h": begin
                    iin = in;
                     char.hextoa(iin);
                    // $display("hta",char);
                     //tmp = char.atoi();
                     //$display("ati",tmp);
                     //char.hextoa(tmp);
                     // for "sring" you need to concatenate it in the message
                     //$display("hta",char);
                  end
                endcase // case(char)
             end
           if (number)
             message = {message,colour_inverse,char,colour_def,colour_tmp}; // show nubers inversed
           else
             message = {message,char};
        end
       $timeformat(-9, 0, " ns", 9);
       $display("%s%t:\t%s%s%s", colour_tmp, $time, file_name, message, colour_def);
      //$display(colour_tmp,$time,"ns:\t", file_name,message,colour_def);
   endfunction // print

   static function void setDebug (string filename, string onoff);
      debug_file_names[filename]=onoff;
   endfunction // void

   static function string getDebug (string filename);
      getDebug = debug_file_names[filename];
   endfunction // void

   //* Task printDebug
   // Purpose: To print a message in a standard format, starting with the
   //          name of the module which invoked this task and the label PASS.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the warning message to be displayed
   // Outputs: none
   static function void printDebug (input string filename,
                           input string msg,
                           real in1 = "",
                           real in2 = "",
                           real in3 = "",
                           real in4 = "",
                           real in5 = "",
                           real in6 = "",
                           real in7 = "",
                           real in8 = "",
                           real in9 = "",
                           real in10 = "",
                           real in11 = "",
                           real in12 = "",
                           real in13 = "",
                           real in14 = "",
                           real in15 = "",
                           real in16 = "",
                           real in17 = "",
                           real in18 = "",
                           real in19 = "",
                           real in20 = ""
                      );
      begin
         if ((debug_file_names[filename] == "on" && debug == "on")|| debug == "all")
           begin
              filename = {"    debug (", filename, "): "};
              print(filename,msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
           end
      end
   endfunction

   //* Task printMessage
   // Purpose: To print a message in a standard format, starting with the
   //          name of the module which invoked this task and the label PASS.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the warning message to be displayed
   // Outputs: none
   static function void printMessage (input string filename,
                           input string msg,
                           real in1 = "",
                           real in2 = "",
                           real in3 = "",
                           real in4 = "",
                           real in5 = "",
                           real in6 = "",
                           real in7 = "",
                           real in8 = "",
                           real in9 = "",
                           real in10 = "",
                           real in11 = "",
                           real in12 = "",
                           real in13 = "",
                           real in14 = "",
                           real in15 = "",
                           real in16 = "",
                           real in17 = "",
                           real in18 = "",
                           real in19 = "",
                           real in20 = ""
                      );
         printLevel(filename, ERRLEVEL_MESSAGE,
            msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
   endfunction // printMessage

   //* Task printMessageBold
   // Purpose: To print a message in bold, starting with the
   //          name of the module which invoked this task and the label PASS.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the warning message to be displayed
   // Outputs: none
   static function void printMessageBold (input string filename,
                           input string msg,
                           real in1 = "",
                           real in2 = "",
                           real in3 = "",
                           real in4 = "",
                           real in5 = "",
                           real in6 = "",
                           real in7 = "",
                           real in8 = "",
                           real in9 = "",
                           real in10 = "",
                           real in11 = "",
                           real in12 = "",
                           real in13 = "",
                           real in14 = "",
                           real in15 = "",
                           real in16 = "",
                           real in17 = "",
                           real in18 = "",
                           real in19 = "",
                           real in20 = ""
                      );
         printLevel(filename, ERRLEVEL_MESSAGEBOLD,
            msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
   endfunction // printMessageBold

   //* Task printPass
   // Purpose: To print a message in a standard format, starting with the
   //          name of the module which invoked this task and the label PASS.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the warning message to be displayed
   // Outputs: none
   static function void printPass (input string filename,
                           input string msg,
                           real in1 = "",
                           real in2 = "",
                           real in3 = "",
                           real in4 = "",
                           real in5 = "",
                           real in6 = "",
                           real in7 = "",
                           real in8 = "",
                           real in9 = "",
                           real in10 = "",
                           real in11 = "",
                           real in12 = "",
                           real in13 = "",
                           real in14 = "",
                           real in15 = "",
                           real in16 = "",
                           real in17 = "",
                           real in18 = "",
                           real in19 = "",
                           real in20 = ""
                      );
         printLevel(filename, ERRLEVEL_PASS,
            msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
   endfunction // printPass

   //* Task printWarning
   // Purpose: To print the input warning message in a standard format, starting with the
   //          name of the module which invoked this task and the label WARNING.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the warning message to be displayed
   // Outputs: none
   static function void printWarning (input string filename,
                      input string msg,
                      real in1 = "",
                      real in2 = "",
                      real in3 = "",
                      real in4 = "",
                      real in5 = "",
                      real in6 = "",
                      real in7 = "",
                      real in8 = "",
                      real in9 = "",
                      real in10 = "",
                      real in11 = "",
                      real in12 = "",
                      real in13 = "",
                      real in14 = "",
                      real in15 = "",
                      real in16 = "",
                      real in17 = "",
                      real in18 = "",
                      real in19 = "",
                      real in20 = ""
                      );
         printLevel(filename, ERRLEVEL_WARNING,
            msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
   endfunction // printWarning

   //* Task printError
   // Purpose: To print the input error message in a standard format, starting with the
   //          name of the module which invoked this task and the label ERROR.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the error message to be displayed
   // Outputs: none
   static function void printError (input string filename,
                    input string msg,
                    real in1 = "",
                    real in2 = "",
                    real in3 = "",
                    real in4 = "",
                    real in5 = "",
                    real in6 = "",
                    real in7 = "",
                    real in8 = "",
                    real in9 = "",
                    real in10 = "",
                    real in11 = "",
                    real in12 = "",
                    real in13 = "",
                    real in14 = "",
                    real in15 = "",
                    real in16 = "",
                    real in17 = "",
                    real in18 = "",
                    real in19 = "",
                    real in20 = ""
                    );
      printLevel(filename, ERRLEVEL_ERROR,
         msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
   endfunction // printError

   //* function printFatalError
   // Purpose: To print the input error message in a standard format, starting with the
   //          name of the module which invoked this task and the label ERROR.
   //          In addition, the simulation stops immediately.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the error message to be displayed
   // Outputs: none
   static function void printFatalError (input string filename,
                    input string msg,
                    real in1 = "",
                    real in2 = "",
                    real in3 = "",
                    real in4 = "",
                    real in5 = "",
                    real in6 = "",
                    real in7 = "",
                    real in8 = "",
                    real in9 = "",
                    real in10 = "",
                    real in11 = "",
                    real in12 = "",
                    real in13 = "",
                    real in14 = "",
                    real in15 = "",
                    real in16 = "",
                    real in17 = "",
                    real in18 = "",
                    real in19 = "",
                    real in20 = ""
                    );
      printLevel(filename, ERRLEVEL_FATAL,
         msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
   endfunction // printFatalError

   //* function printLevelES
   // Purpose: To print the input  message in a standard format, starting with the
   //          name of the module which invoked this task and the label based on errlevel.
   // Inputs : string caller --> The name of the module who invoked this task
   //          string msg    --> the error message to be displayed
   // Outputs: none
   static function void printLevel (input string filename,
         input integer errlevel,
         input string msg,
         real in1 = "",
         real in2 = "",
         real in3 = "",
         real in4 = "",
         real in5 = "",
         real in6 = "",
         real in7 = "",
         real in8 = "",
         real in9 = "",
         real in10 = "",
         real in11 = "",
         real in12 = "",
         real in13 = "",
         real in14 = "",
         real in15 = "",
         real in16 = "",
         real in17 = "",
         real in18 = "",
         real in19 = "",
         real in20 = ""
      );
      case (errlevel)
         ERRLEVEL_PASS :
            begin
               colour_tmp = colour_green;
               filename = {"  +PASS (", filename, "): "};
               globalPassCounter++;
            end
         ERRLEVEL_MESSAGE :
            begin
               colour_tmp = colour_def;
               filename = {"  MESSAGE (", filename, "): "};
            end
         ERRLEVEL_MESSAGEBOLD :
            begin
               colour_tmp = colour_bold;
               filename = {"  MESSAGE (", filename, "): "};
            end            
         ERRLEVEL_WARNING :
            begin
               filename = {" >WARNING      (", filename, "): "};
               colour_tmp = colour_yellow;
               globalWarningCounter++;
            end
         ERRLEVEL_ERROR:
            begin
               filename = {">>ERROR        (", filename, "): "};
               colour_tmp = colour_red;
               globalErrorCounter++;
            end
         ERRLEVEL_FATAL:
            begin
               filename = {">>>FATAL ERROR (", filename, "): "};
               colour_tmp = colour_red;
               globalErrorCounter++;
            end
      endcase print (filename,msg,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,in17,in18,in19,in20);
      colour_tmp = colour_def;
      if(errlevel >= ERRLEVEL_FATAL)
         begin
            `ifdef XILINX_SIMULATOR
		$display ("Received FATAL error, ending testcase");
                $display ("\n\nSIMULATION STATUS: FAIL\n\n");
                $stop(2);
            `else
               ->globalFatalErrorEvent;
            `endif
         end
   endfunction

   static function void  checkSig (
        input string filename,
        input integer errlevel,
        input string sname,
        input logic [63:0] actual,
        input logic [63:0] expected,
        input bit quiet = 0
        //,input int width = 64
    );
        string message;
        if (actual !== expected)
        begin
            message = $sformatf("%s had unexpected value (%H), expected (%H)",
                sname, actual, expected);
            printLevel(filename, errlevel, message);
        end
        else if (!quiet)
        begin
            printPass(filename, $sformatf("%s matched expected value (%H)", sname, actual));
        end
        else
        begin
            globalPassCounter =  globalPassCounter + 1;
        end
   endfunction :  checkSig

   static function void checkInt (
        input string filename,
        input integer errlevel,
        input string sname,
        input integer actual,
        input integer expected,
        input bit quiet = 0,
        input integer epsilon = 0
    );
        string message;
        integer delta = actual - expected;

        if (delta > epsilon || delta < -epsilon)
        begin
            message = $sformatf("%s had unexpected value (%0d), expected (%0d)",
                sname, actual, expected);
            printLevel(filename, errlevel, message);
        end
        else if (!quiet)
        begin
            printPass(filename, $sformatf("%s matched expected value (%0d)", sname, actual));
        end
        else
        begin
            globalPassCounter =  globalPassCounter + 1;
        end
   endfunction :  checkInt

   static function void checkTime (
        input string filename,
        input integer errlevel,
        input string sname,
        input time actual,
        input time expected,
        input bit quiet = 0,
        input longint epsilon = 0
    );
        string message;
        longint delta = actual - expected;

        $timeformat(-9, 3, "ns", 0);
        if (delta > epsilon || delta < -epsilon)
        begin
            message = $sformatf("%s had unexpected value (%0t), expected (%0t), delta (%0t)",
                sname, actual, expected, delta);
            printLevel(filename, errlevel, message);
        end
        else if (!quiet)
        begin
            printPass(filename, $sformatf("%s matched expected value (%0t)", sname, actual));
        end
        else
        begin
            globalPassCounter =  globalPassCounter + 1;
        end
   endfunction :  checkTime

   static function void checkIntRange(
        input string filename,
        input integer errlevel,
        input string sname,
        input integer actual,
        input integer expected_min,
        input integer expected_max,
        input bit quiet = 0
    );
        string message;
        if (actual < expected_min || actual > expected_max)
        begin
            message = $sformatf("%s had unexpected value (%0d), expected (%0d - %0d)",
                sname, actual, expected_min, expected_max);
            printLevel(filename, errlevel, message);
        end
        else if (!quiet)
        begin
            printPass(filename, $sformatf("%s value (%0d) inside expected range (%0d-%0d)",
                sname, actual, expected_min, expected_max));
        end
        else
        begin
            globalPassCounter =  globalPassCounter + 1;
        end
   endfunction :  checkIntRange

   //* =========================== watchForFatalError task ==========================
   //* Task watchForFatalError
   // Purpose: This task watches for any fatal error event. If such an event occurs,
   //          the simulation is terminated by invoking the testComplete task.
   // Inputs : none
   // Outputs: none
`ifndef XILINX_SIMULATOR
   static task watchForFatalError ();
      @ (globalFatalErrorEvent);
      $display ("Received FATAL error, ending testcase");
      testComplete;
   endtask // watchForFatalError
`endif


   //* =========================== initSim task ==========================
   //* Task initSim
   // Purpose: This task reports the testcase name, sets the debug level
   // and starts the fatal error monitor.
   // Inputs : none
   // Outputs: none
   static task initSim(string filename, bit suppressFatal = 0, string debug_in = "off");
   testcase_name = filename;   
      if(!initDone)
      begin
         debug = debug_in;

`ifndef XILINX_SIMULATOR
         fork
            if(!suppressFatal)
               watchForFatalError();
         join_none
`endif
         initDone = 1;
         printMessage (filename, {"-------> ",filename," testcase <-------"});
      end
      else
      begin
         printError(filename, "Attempt to re-init simulation");
      end
   endtask : initSim

   //* =========================== testComplete task ==========================
   //* Task testComplete
   // Purpose: This task cleanly terminates the simulation. It reports the simulation
   //          status (pass/fail) based on the values of the globalErrorCounter. The
   //          simulation should be ended no other way than by invoking this task.
   // Inputs : none
   // Outputs: none
   static task testComplete ();
      string msg;
      begin
         if(!initDone)
            printWarning("", "simManagementPkg was not initialized, fatal errors may not be caught");

         // First, make sure no BFM needs to report any further messages, warnings or errors
         // by letting them know we are about to end the simulation.
         #10
         ->allBfmsPleaseDoEndOfSimCheck;
         #10;

         $write("%c[1;32m",27);   // print in green
         if (globalWarningCounter != 0)
           $write(colour_yellow); // blue
         if (globalErrorCounter != 0 || globalPassCounter == 0)
           $write("%c[1;31m",27); // red

         $display ("\n================================================================");
         $display ("====================== END OF SIMULATION =======================");
         $display ("================================================================\n");

         // One space between ":" and the number is required.
         msg.itoa (globalPassCounter);
         msg = {"PASS  : ", msg};
         $display (msg);
         msg.itoa (globalWarningCounter);
         // There must be no space between WARNINGS and ":", log file parsing assumes this fact.
         msg = {"WARNINGS: ", msg};
         $display (msg);
         msg.itoa (globalErrorCounter);
         msg = {"ERRORS  : ", msg};
         $display (msg);

         if (globalErrorCounter == 0 && globalPassCounter > 0)
           $display ("\n\nSIMULATION STATUS: PASS\n\n");
         else
           $display ("\n\nSIMULATION STATUS: FAIL\n\n");

         $display ({"TESTCASE NAME: ",testcase_name});
         $display ("SEED: %d",seed);

         $write("%c[0m",27); // default console colour
         $display ();


         $stop(2);
      end
   endtask // testComplete
   endclass

endpackage
