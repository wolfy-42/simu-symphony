//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//Filename    : bfm_clock_gen.v
//Project     : RIPL
//Author      : Arnold Balisch
//Modified    : Dec 9, 2015
//--------------------------------------------------------------------
//Description : Clock generator.
// - provides ability to insert phase and jitter
//
// Modifications
// Feb 9,2015  - adjust jitter calculation method
//             - fix issues with always(*)...could generate excessive iterations
// Dec 9,2015  - instance template
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2015-01-05 20:00:46 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines


//* Module declaration
module bfm_clock_gen 
   //<> define default startup values (can be overridden by parameter or task calls)
   #( parameter string BFM_NAME         = "bfm_clock_gen",
      parameter string CLK_NAME         = "unnamed_clock",
      parameter real   pCLOCK_PERIOD    = 10.0,
      parameter real   pCLOCK_JITTER    = 0.0,
      parameter real   pCLOCK_PHASE     = 0.0,
      parameter real   pCLOCK_PHASE_DLY = 0.0,
      parameter real   pCLOCK_DUTY_HI   = 50.0
   ) 
   (
      output reg o_clock  = 1'b0   // clock output
   );


//<> ------------------------------------------------------------
//<> CONSTANTS
//<> ------------------------------------------------------------

//<> ------------------------------------------------------------
//<> LOCAL REGISTERS
//<> ------------------------------------------------------------
  reg  clock_reg             = 0;                                   // clock signal
  real clock_period          = pCLOCK_PERIOD;                       // clock period
  real clock_period_hi ;                                            // clock period high time
  real clock_period_lo ;                                            // clock period low time
  real clock_jitter          = pCLOCK_JITTER;                       // clock jitter
  real clock_current_jitter  = 0;                                   // clock current cycle jitter value
  real clock_phase           = pCLOCK_PHASE;                        // clock phase delay in degrees
  real clock_phase_dly;                                             // clock phase delay in int
  real clock_duty_hi         = pCLOCK_DUTY_HI;                      // clock duty cycle
  real clock_duty_lo         = (100.0-pCLOCK_DUTY_HI);              // clock duty cycle
  int  clock_en              = 1;                                   // clock enable
           
//<> ------------------------------------------------------------
//<> --- CLOCK GENERATION
//<> ------------------------------------------------------------

  //<> clock code
   always @(clock_period, clock_duty_hi, clock_duty_lo, clock_phase)
    begin
      //<> set clock period
      clock_period_hi = (clock_duty_hi/100) * clock_period;
      clock_period_lo = (clock_duty_lo/100) * clock_period;   
      //<> set clock phase
      clock_phase_dly = (clock_phase/360) * clock_period;
    end

   //<> recalculate random jitter value every clock edge.
   // always @(posedge(clock_reg))
   // always @(clock_reg)
   // begin
      // clock_current_jitter = getJitter(clock_jitter);
   // end
   
   //<> ----------------------------------------------------------------
   //<> generate clock with required frequency, duty-cycle, and jitter
   //<> - jitter alternately added and subtracted to average out potential for frequency drift
   initial
   begin
      while (1) begin
         //<> Low period of duty
         if (clock_jitter != 0.0) 
            clock_current_jitter = getJitter(clock_jitter);  // recalculate random jitter value every clock edge if enabled.
         #(clock_period_lo + clock_current_jitter);   // delay prior to rising edge
         clock_reg = 1;
         //<> High period of duty
         if (clock_jitter != 0.0) 
            clock_current_jitter = getJitter(clock_jitter); // recalculate random jitter value every clock edge if enabled.
         #(clock_period_hi - clock_current_jitter);   // delay for falling duty cycle
         clock_reg = 0;
      end
   end

   //<> drive clock output with phase offset, and gated by clock enable
   always @(clock_reg, clock_en) 
   begin
      o_clock <= #clock_phase_dly (clock_reg & clock_en);
   end   

//<> ------------------------------------------------------------
//<> ----------------------- TASK AND FUNCTION DEFINITIONS 
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> This function is called each time the clock edge is changed.
   //<> If the clock jitter is set to zero, it returns 0.
   //<> If the clock jitter is non-zero, it returns a random value between 
   //<> -max_jitter and +max_jitter.
   function real getJitter (input real max_jitter);
      int rnd_num;
   begin
      if (max_jitter == 0)
         begin
            getJitter = 0;
         end
      else
         begin
            // getJitter = $random % (max_jitter + 1);
            rnd_num = $random;  
            if (rnd_num==0)   // avoid divide by zero risk
               getJitter = 0;    
            else
               getJitter = max_jitter/(rnd_num % 100);      // generate percentage of maxjitter
         end
      end
   endfunction // getJitter

   //<> ----------------------------------------------------------------
   //<> set clock jitter
   task set_clock_jitter(input real jitter);
      string jitter_str;
      string msg;
   begin
      jitter_str.itoa (jitter);
      msg = {"Setting the jitter for ", CLK_NAME, " to ", jitter_str};
      sim_management_inst.printMessage (BFM_NAME, msg);
      clock_jitter = jitter;
   end
   endtask // set_clock_jitter
   
   //<> ----------------------------------------------------------------
   //<> set clock phase offset
   task set_clock_phase(input real phase);
      string phase_str;
      string msg;
   begin
      phase_str.itoa (phase);
      if (phase > 360 | phase < 0)
         sim_management_inst.printError (BFM_NAME, "Phase must be between 0 and 360 degrees");
      else begin                         
         msg = {"Setting the phase for ", CLK_NAME, " to ", phase_str," deg"};
         sim_management_inst.printMessage (BFM_NAME, msg);
         clock_phase = phase;
      end
   end
   endtask // set_clock_phase

   //<> ----------------------------------------------------------------
   //<> define period of output clock
   task set_clock_period(
      input     real period);
         string period_str;
         string msg;
      begin         
         if (period <= 0)
           sim_management_inst.printError (BFM_NAME, "Period must be greater than 0");
         else begin
            clock_period = period;
            period_str.realtoa (period);
            msg = {"Setting the period for ", CLK_NAME, " to ", period_str,"ns"};
            sim_management_inst.printMessage (BFM_NAME, msg);              
         end         
      end
  endtask // set_clock_period
   
   //<> ----------------------------------------------------------------
   //<> clock enable on/off control
   task set_clock_enable(input real enable);
         string enable_str;
         string msg;
      begin
         enable_str.itoa (enable);
         clock_en = enable;
         msg = {"Setting the enable for ", CLK_NAME, " to ", enable_str};
         sim_management_inst.printMessage (BFM_NAME, msg);              
      end
   endtask // set_clock_enable

   //<> ----------------------------------------------------------------
   //<> Clock duty cycle 
   //<> - define duty hi and lo durations in percentages (ie 50 = 50%)
   task set_clock_duty_cycle(input real duty_cycle_hi,
                            input real duty_cycle_lo);
         string duty_cycle_hi_str;
         string duty_cycle_lo_str;
         string msg;
      begin
         duty_cycle_hi_str.itoa (duty_cycle_hi);
         duty_cycle_lo_str.itoa (duty_cycle_lo);
         if (duty_cycle_hi + duty_cycle_lo != 100)
            sim_management_inst.printError (BFM_NAME, "duty_cycle_hi + duty_cycle_lo must add up to 100");
         else begin                         
            msg = {"Setting the duty_cycle for ", CLK_NAME, " to ", duty_cycle_hi_str, " / ", duty_cycle_lo_str};
            sim_management_inst.printMessage (BFM_NAME, msg);
            clock_duty_hi = duty_cycle_hi;
            clock_duty_lo = duty_cycle_lo;
         end
      end
   endtask // set_clock_duty_cycle
            
endmodule // bfm_clock_gen

// //<>----------------------------------------------------------
// //<> Behavioural Clock Source 
// //<>----------------------------------------------------------
// bfm_clock_gen 
   // #( .BFM_NAME         ("bfm_clock_gen"),
      // .CLK_NAME         ("unnamed_clock"),
      // .pCLOCK_PERIOD    (10.0),
      // .pCLOCK_JITTER    ( 0.0),
      // .pCLOCK_PHASE     ( 0.0),
      // .pCLOCK_PHASE_DLY ( 0.0),
      // .pCLOCK_DUTY_HI   (50.0)
   // ) bfm_clock_gen_inst
   // (
      // .o_clock   ()  // clock output
   // );