//*--------------------------------------------------------------------//
//
// Copyright (C) 2006 Fidus Systems Inc.
//
// Project       : simu
// Author        : Chris Hesse
// Created       : 2006-09-28
//---------------------------------------------------------------------//
//---------------------------------------------------------------------//
// Description   : Clock generator.
// Updated       : date / author - comment
//---------------------------------------------------------------------//

`timescale 1ns/1ps
//* Module declaration
module fidus_clock_gen_bfm (
                o_clock
                );

//* Outputs
  output o_clock; // clock
  
  parameter BFM_NAME = "bfm_clock_gen";
  parameter CLK_NAME = "unnamed_clock";   

//* Registers
  // clock signals
  reg  o_clock;                  // clock output
  reg  clock_reg = 0;            // clock signal
  real  clock_period    ;       // clock period
  real  clock_period_hi ;     // clock period high time
  real  clock_period_lo ;     // clock period low time
  real  clock_jitter = 0;         // clock jitter
  real clock_phase = 0;          // clock phase delay in degrees
  real clock_phase_dly;          // clock phase delay in int
  real clock_duty_hi = 50;       // clock duty cycle
  real clock_duty_lo = 50;       // clock duty cycle
  integer  clock_en = 1;             // clock enable
  real  clock_current_jitter = 0; // clock current cycle jitter value
           
  //* --- clock generation

  // clock code
  always @(*)
    begin
      // set clock period
      clock_period_hi = (clock_duty_hi/100) * clock_period;
      clock_period_lo = (clock_duty_lo/100) * clock_period;   
      // set clock phase
      clock_phase_dly = (clock_phase/360) * clock_period;
    end

  always @(posedge(clock_reg))
    begin
      clock_current_jitter = getJitter(clock_jitter);
    end
   
  always
    begin
      #(clock_period_lo + clock_current_jitter)
        clock_reg = 1;
      #(clock_period_hi - clock_current_jitter)
        clock_reg = 0;
    end

  always @(*) 
    begin
      o_clock <= #clock_phase_dly (clock_reg & clock_en);
    end   

  //  ----------------------------------------------------------------
  //* ----------------------- task and function definitions ----------

  // This function is called each time the clock edge is changed.
  // If the clock jitter is set to zero, it returns 0.
  // If the clock jitter is non-zero, it returns a random value between 
  // -max_jitter and +max_jitter.
  function integer getJitter (input integer max_jitter);
    begin
      if (max_jitter == 0)
        begin
          getJitter = 0;
        end
      else
        begin
          getJitter = $random % (max_jitter + 1);
        end
    end
  endfunction // getJitter

  //task set_clock_jitter(
  //                      input     real jitter);
  //    reg [200:1] jitter_str;
  //    reg [200:1] msg;
  //    begin
  //      jitter_str.realtoa (jitter);
  //      msg = {"Setting the jitter for ", CLK_NAME, " to ", jitter_str};
  //      sim_management_inst.printMessage (BFM_NAME, msg);
  //      clock_jitter = jitter;
  //    end
  //endtask // set_clock_jitter
   
  //task set_clock_phase(
  //                     input     real phase);
  //    string phase_str;
  //    string msg;
  //    begin
  //      phase_str.realtoa (phase);
  //      if (phase > 360 | phase < 0)
  //        sim_management_inst.printError (BFM_NAME, "Phase must be between 0 and 360 degrees");
  //      else begin                         
  //        msg = {"Setting the phase for ", CLK_NAME, " to ", phase_str};
  //        sim_management_inst.printMessage (BFM_NAME, msg);
  //        clock_phase = phase;
  //      end
  //    end
  // endtask // set_clock_phase

  task set_clock_period(
                        input     real period);
      reg [200:1] msg;
      begin         
         if (period <= 0)
           sim_management_inst.printError (BFM_NAME, "Period must be greater than 0");
         else begin
            clock_period = period;
            msg = {"Setting the period for ", CLK_NAME, " to "};
            sim_management_inst.printMessage (BFM_NAME, msg);              
             $display("%d", period);
         end         
      end
  endtask // set_clock_period
   
  //task set_clock_enable(
  //                      input     real enable);
  //    string msg;
  //    begin
  //      clock_en = enable;
  //      msg = {"Setting the enable for ", CLK_NAME, " to ", enable_str};
  //      sim_management_inst.printMessage (BFM_NAME, msg);              
  //    end
  // endtask // set_clock_enable

  //task set_clock_duty_cycle(
  //                          input     real duty_cycle_hi,
  //                          input     real duty_cycle_lo);
  //    string duty_cycle_hi_str;
  //    string duty_cycle_lo_str;
  //    string msg;
  //    begin
  //      duty_cycle_hi_str.realtoa (duty_cycle_hi);
  //      duty_cycle_lo_str.realtoa (duty_cycle_lo);
  //      if (duty_cycle_hi + duty_cycle_lo != 100)
  //        sim_management_inst.printError (BFM_NAME, "duty_cycle_hi + duty_cycle_lo must add up to 100");
  //      else begin                         
  //        msg = {"Setting the duty_cycle for ", CLK_NAME, " to ", duty_cycle_hi_str, " / ", duty_cycle_lo_str};
  //        sim_management_inst.printMessage (BFM_NAME, msg);
  //        clock_duty_hi = duty_cycle_hi;
  //        clock_duty_lo = duty_cycle_lo;
  //      end
  //    end
  // endtask // set_clock_duty_cycle
            
endmodule // bfm_clock_gen

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:
 
