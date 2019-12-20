//--------------------------------------------------------------------
//
// Copyright (C) 2015 Fidus Systems Inc.
//
// Project       : simu
// Author        : Arnold Balisch
// Created       : 2015-08-10
//--------------------------------------------------------------------
//--------------------------------------------------------------------
// Description   : This library is responsible for implementing all tasks that
//     relate to math expressions, such as a random number generator.
//
//   Dependancies:  
//    1> tb/libraries/sim_management.sv   
//
//   Available User routines:
//    - function integer ABS(integer num);
//    - function integer ABS(integer num);
//    - function reg [$size(a)-1:0] ABS_reg (input reg [$size(a)-1:0] a);  // variable-sized vector
//    - function string Comma(input logic [63:0] val);
//    - function integer RandRange();
//    - function integer RandTriRange();
//    - function real PercentDiff();
//    - function real PercentErr();
//    - function shortreal MAX_r();
//    - function shortreal MAX_sr();
//    - function shortreal MAX_i();
//    - function shortreal MIN_r();
//    - function shortreal MIN_sr();
//    - function shortreal MIN_i();
//
//   NOTE: uses SystemVerilog constructs
//
// Updated       : date / author - comments
//--------------------------------------------------------------------


//<> check to see if module already included by calling module...avoids duplicate includes

`ifndef LIB_MATH
   `define LIB_MATH

`ifndef SIM
   `define SIM  tb.sim_management_inst
`endif
  
//* Module declaration
module lib_math ();
    import sim_management_pkg::*;
   parameter MODULE_NAME = "lib_math";

    sim_management s;

   string msg;
   
   integer seed;

   //<>------------------------------------------------------------------------
   //<> environment startup routines
   //<>------------------------------------------------------------------------
   initial 
   begin 
     seed = `SEED_INITIAL_VALUE ;        
     msg.itoa (`SEED_INITIAL_VALUE);
     msg = {"The seed is set to ", msg," for this simulation.\n"};
     s.printMessage (MODULE_NAME, msg);
   end
   
   //<>------------------------------------------------------------------------
   //<> Absolute value functions
   //<>  - due to Verilog limitations, unique function for each operand type
   //<>------------------------------------------------------------------------
      
      //<> return positive integer
      function integer ABS(integer num);
         ABS = (num <0) ? -num : num;
      endfunction // ABS       
      
      //<> return positive real
      function real ABS_real(real num);
         ABS_real = (num < 0.0) ? -num : num;
      endfunction // ABS       

      // function reg [$size(a)-1:0] ABS_reg (input reg [$size(a)-1:0] a);  // variable-sized vector
         // ABS = (a < 0) ? -a : a;
      // endfunction
   
   //<>------------------------------------------------------------------------
   //<> task to generate a random value within selected lo->hi range
   //<>------------------------------------------------------------------------
   function integer RandRange;
      input integer range_lo;
      input integer range_hi;
   begin
      if (range_lo < range_hi)  begin // check endpoints
         RandRange = (({$random(seed)} % (range_hi - range_lo)) + range_lo);     
         seed = RandRange;    // change randomization seed for next call 
      end
      else begin    // Illegal range limits supplied ... abort simulation!! 
          fork      // Call task from function
             `SIM.printFatalError(MODULE_NAME,"RandRange() - FATAL ERROR : FAILURE: Incorrect range endpoints passed : Low >= High");
          join_none
      end
   end   
   endfunction     
   
   //<>------------------------------------------------------------------------
   //<> task to generate a random value within one of three randomly selected ranges
   //<>------------------------------------------------------------------------
   function integer RandTriRange;
      input integer r1_lo;    // first range : r1_lo -> r1_hi
      input integer r1_hi;
      input integer r2_lo;    // second range : r2_lo -> r2_hi
      input integer r2_hi;
      input integer r3_lo;    // third range : r3_lo -> r3_hi
      input integer r3_hi;
      int range;
   begin
      range = ({$random(seed)}%3);  // create three ranges of random number return spread
       case (range)  // based on randomly selected range, do...
           0 : begin  // low range
               RandTriRange = RandRange(r1_lo,r1_hi);
           end
           1 : begin  // mid range
               RandTriRange = RandRange(r2_lo,r2_hi);
           end
           2 : begin  // high range
               RandTriRange = RandRange(r3_lo,r3_hi);
           end
           default: begin
               fork      // Call task from function
                   `SIM.printFatalError(MODULE_NAME,"RandTriRange() - FATAL ERROR : Catestrophic Function Zoneing error");
               join_none
           end
       endcase
      seed = range;  // change randomization seed for next call
   end
   endfunction     

   //<>------------------------------------------------------------------------
   //<> Percentage difference between two inputs
   //<>   - takes two real inputs, returns a real output as percent difference
   //<> eg. a=15, b= 25 => 50% difference
   //<>------------------------------------------------------------------------
   function real PercentDiff(input real a,
                             input real b);
      real result;
   begin
      if (a==b)
         PercentDiff = 0.0;                   // avoid divide-by-zero situation if a=b=0
      else begin
         result = (a-b)/((a+b)/2.0);          // perform percentage difference calculation      
         PercentDiff = ABS_real(result);      // return absolute value of result
      end
   end
   endfunction
     
   
   
   //<>------------------------------------------------------------------------
   //<> Percentage Error between two inputs
   //<>   - takes two real inputs, returns real output as percent difference of measured vs exact 
   //<> eg. a=15, b= 25 =>  %
   //<>------------------------------------------------------------------------
   function real PercentErr(input real exact,
                            input real measured);
      real temp;
       begin
           if (exact == 0.0) 
               fork      // Call task from function
                   s.printFatalError ("lib_math.PercentErr()", "attempted divide by zero");
               join_none
           else begin
               temp = ((exact-measured)/exact)*100.0;  // perform error calculation and convert to percentage notation
               if (temp < 0.0)                         // check for negative result...return ABS(temp)
                   PercentErr = -temp;                  // result was negative, therefore negate
               else 
                   PercentErr = temp;                   // result was positive
           end
       end
   endfunction
     

   //<>------------------------------------------------------------------------
   //<> returns maximum of two inputs
   //<>------------------------------------------------------------------------
   function real MAX_r (input real a,b);              // accepts a 'REAL' value
      begin
         MAX_r = (a>b)? a: b;
      end
   endfunction  
   
   function shortreal MAX_sr (input shortreal a,b);   // accepts a 'SHORTREAL' value
      begin
         MAX_sr = (a>b)? a: b;
      end
   endfunction  
   
   function integer MAX_i (input integer a,b);        // accepts a 'INTEGER' value
      begin
         MAX_i = (a>b)? a: b;
      end
   endfunction  

   //<>------------------------------------------------------------------------
   //<> returns minimum of two inputs
   //<>------------------------------------------------------------------------
   function real MIN_r (input real a,b);              // accepts a 'REAL' value
      begin
         MIN_r = (a<b)? a: b;
      end
   endfunction 
   
   function shortreal MIN_sr (input shortreal a,b);   // accepts a 'shortreal' value
      begin
         MIN_sr = (a<b)? a: b;
      end
   endfunction  
 
   function integer MIN_i (input integer a,b);        // accepts a 'integer' value
      begin
         MIN_i = (a<b)? a: b;
      end
   endfunction  


   
//<> ==================  WORK IN PROGRESS ROUTINES ==========================================
//<> following routines are not currently working as intended, and are retained here in  
//<> non-functional state for future effort history.  
//<> ========================================================================================
   
   // //<> NOTE: 'a' and 'b' must have the same size to have a valid return.  return assumes size of input 'a'
   // function reg [$size(a)-1:0] MIN_reg (input reg [$size(a)-1:0] a,
                                        // input reg [$size(b)-1:0] b);   
      // begin
         // MIN_reg = (a<b)? a: b;
      // end
   // endfunction  

   // //<> NOTE: 'a' and 'b' must have the same size to have a valid return.  return assumes size of input 'a'
   // function reg [$size(a)-1:0] MAX_reg (input reg [$size(a)-1:0] a,
                                        // input reg [$size(b)-1:0] b);   
      // begin
         // if ($size(a) < $size(b)) `SIM.printWarning("LIB_NAME", {""});
         // MAX_reg = (a>b)? a: b;
      // end
   // endfunction  

   
   // // -------------------------------------------------------------------
   // // <> constant function routine to calculate the number of bits required 
   // //    for a vector to accomadate a given integer value 
   // //  eg.  parameter RAM_DEPTH = 256;
   // //       input [clogb2(RAM_DEPTH)-1:0] addr_bus;
   // //
   // function integer clogb2(input integer depth);               //<> note: copied to "sim_tools.hv" 
   // begin
      // for (clogb2=0; depth > 0; clogb2=clogb2+1)
         // depth = depth >> 1;
   // end
   // endfunction

   
   // // -------------------------------------------------------------------
   // //<> Absolute function
   //<>   
   //<>  <<NOTE>> (system)Verilog does not support operator overloading
   //<>     ...retained here for future debug opportunity
   //<>

   // function int ABS (input int a);     // 32bit signed integer
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function shortint ABS (input shortint a);     // 16bit signed integer
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function real ABS (input real a);   // 64bit float
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function shortreal ABS (input shortreal a);  //32bit float
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function reg [$size(a)-1:0] ABS (input reg [$size(a)-1:0] a);  // variable-sized vector
       // ABS = (a < 0) ? -a : a;
   // endfunction

   
endmodule // lib_math

//<> -------------------------------------END-------------------------------------------------

//<> close start of file `ifndef
`endif
