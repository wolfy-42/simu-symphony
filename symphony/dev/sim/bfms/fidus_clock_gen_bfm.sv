//---------------------------------------------------------------------------//
//
// Copyright (C) 2018 Fidus Systems Inc.
// 
// Project       : simu
// Author        : Kevin Eckstrand
// Created       : 2018-06-19
//---------------------------------------------------------------------------//
//---------------------------------------------------------------------------//
// Description   : BFM package that contains class for clock control.
//               Extended class ties to virtual interface.
//               Contains the following functions / tasks
//               fidus_clk_gen_bfm_base (base class)
//                 - new
//                 - fSetDebugMessagingOnOff
//                 - fGetJitter
//                 - fSetJitterPerc
//                 - fSetClockPhase
//                 - fSetClockPeriodRealNs
//                 - fSetClockEnable
//                 - fSetClockDutyCycleHiPerc
//                 - fSetClockHighLowTime
//                 - tDriveClk
//               fidus_clk_gen_bfm (extended class)
//                 - new
//                 - tDriveClkOut
//               Package also contains clock interface type definition,
//               same interface type definition as used by the BFM class.
//               See bottom of file for example usage.
// Updated       : date / author - comments
//---------------------------------------------------------------------------//

package fidus_clock_gen_bfm_pkg;

import sim_management_pkg::*; 

class fidus_clock_gen_bfm_base;
    
    sim_management         s;
    string                 CLASS_NAME;

    logic  clk;
    event  clk_event, clk_rise_event, clk_fall_event;

    time   clock_period    ;          // clock period
    time   clock_period_hi ;          // clock period high time
    time   clock_period_lo ;          // clock period low time
    real   clock_jitter = 0;          // clock jitter
    real   clock_phase = 0;           // clock phase delay in degrees
    real   clock_phase_dly;           // clock phase delay in int
    real   clock_duty_hi = 50;        // clock duty cycle
    real   clock_duty_lo = 50;        // clock duty cycle
    int    clock_en = 1;              // clock enable

    logic  dbg_print_status;          // when set, debug messaging will be printed 


    //////////////////////////////////////////////////////////////////////////////////
    // function new
    //     Constructor
    //////////////////////////////////////////////////////////////////////////////////
   
    function new (
        string                name = "fidus_clk_gen_bfm",
        real                  period_ns = 0,
        int                   enable = 1,
        int                   dbg_en = 1 );
        
        this.CLASS_NAME     = name;
        // default variable states
        clock_jitter         = 0;                           // clock jitter
        clock_phase          = 0;                           // clock phase delay in degrees
        clock_duty_hi        = 50;                          // clock duty cycle
        clock_duty_lo        = 50;                          // clock duty cycle
        clock_en             = (period_ns==0) ? 0 : enable;    // clock enable
        dbg_print_status     = dbg_en;
        // default drive of IO
        clk                  = 1'b0;
        // launch looping task(s)
        if (period_ns>0) begin
            fSetClockPeriodRealNs(period_ns);
            if (clock_en!=0) begin
                fork
                   tDriveClk();
                join_none
            end
        end
    endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetDebugMessagingOnOff
   //     Enables/disables debug messaging associated with events, state
   //       transitions, etc  (intended for debug only)
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetDebugMessagingOnOff(
      input logic dbg_print_status);
      s.printMessage(CLASS_NAME,$sformatf("Turning debug logging %0s, was previously set %0s",
         ((dbg_print_status) ? "ON" : "OFF"), ((this.dbg_print_status) ? "ON" : "OFF")));
      this.dbg_print_status = dbg_print_status;
   endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fGetJitter
//      This function is called each time the clock edge is changed.
//      If the clock jitter is set to zero, it returns 0.
//      If the clock jitter is non-zero, it returns a random value between 
//      -max_jitter and +max_jitter.
//////////////////////////////////////////////////////////////////////////////////

    function real fGetJitter (
        input real max_jitter);
        fGetJitter = (max_jitter == 0) ? 0 : ( ($itor( $random % ($rtoi(max_jitter*100)+1) ))/100 );
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fSetJitterPerc
//      This function is called by the user to set the associated jitter.
//////////////////////////////////////////////////////////////////////////////////

    function void fSetJitterPerc (
        input real jitter);
        if (jitter >= 100 | jitter < 0)
            s.printError(CLASS_NAME,$sformatf("Jitter must be between 0 and 100 percent, jitter %f outside range", jitter));
        else begin
            clock_jitter = jitter;
            if (dbg_print_status)
                s.printMessage(CLASS_NAME,$sformatf("Setting the jitter to %f", clock_jitter));
        end
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fSetClockPhase
//      This function is called by the user to set the associated phase.
//////////////////////////////////////////////////////////////////////////////////

    function void fSetClockPhase (
        input real phase);
        if (phase > 360 | phase < 0)
            s.printError(CLASS_NAME,$sformatf("Phase must be between 0 and 360 degrees, phase %f outside range", phase));
        else begin
            clock_phase = phase;
            if (dbg_print_status)
                s.printMessage(CLASS_NAME,$sformatf("Setting the phase to %f", clock_phase));
            if (clock_en)
                s.printWarning(CLASS_NAME, "Clock has already been enabled, phase update will not take effect until next disable/enable");
        end
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fSetClockPeriodRealNs
//      This function is called by the user to set the associated period using
//      'real' data type. The real argument is specified in ns.
//      Warning! The actual period is heavily influenced by the specified
//      simulation time precision.
//////////////////////////////////////////////////////////////////////////////////

    function void fSetClockPeriodRealNs (
        input real period_ns);
        if (period_ns < 0)
            s.printError(CLASS_NAME,$sformatf("Period must be greater than 0, period %f outside range", period_ns));
        else begin
            clock_period = period_ns * 1000ps;
            fSetClockHighLowTime();
            if (dbg_print_status)
                s.printMessage(CLASS_NAME,$sformatf("Setting the period to %0t ticks (received real %f ns)", clock_period, period_ns));
        end
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fSetClockEnable
//      This function is called by the user to set the associated enable.
//////////////////////////////////////////////////////////////////////////////////

    function void fSetClockEnable (
        input integer enable);
        if ((enable!=0) && (clock_en==0)) begin
            // launch tDriveClk if enabling clock (from disabled state)
            fork
               tDriveClk();
            join_none
        end
        clock_en = enable;
        if (dbg_print_status)
            s.printMessage(CLASS_NAME,$sformatf("Setting the enable to %0d", clock_en));
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fSetClockDutyCycleHiPerc
//      This function is called by the user to set the associated duty cycle.
//////////////////////////////////////////////////////////////////////////////////

    function void fSetClockDutyCycleHiPerc (
        input real duty_cycle_hi);
        if ((duty_cycle_hi < 0) || (duty_cycle_hi > 100)) begin
            s.printError(CLASS_NAME,$sformatf("Duty cycle high percentage must be between 0-100, duty cycle high %f outside range", duty_cycle_hi));
        end else begin
            clock_duty_hi = duty_cycle_hi;
            clock_duty_lo = (100-duty_cycle_hi);
            fSetClockHighLowTime();
            if (dbg_print_status)
                s.printMessage(CLASS_NAME,$sformatf("Duty cycle high / low set to %f / %f", clock_duty_hi, clock_duty_lo));
        end
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fSetClockHighLowTime
//      This function is called internally to recalculate high/low times.
//////////////////////////////////////////////////////////////////////////////////

    function void fSetClockHighLowTime ();
        clock_period_hi = (clock_duty_hi/100) * clock_period;
        clock_period_lo = (clock_duty_lo/100) * clock_period;   
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// task tDriveClk
//      This task drives the clock signal.
//      Task loops forever until clock_en is deasserted, then task exits.
//////////////////////////////////////////////////////////////////////////////////

    task tDriveClk();
        time  clock_current_jitter_lo = 0;  // clock current cycle jitter value
        time  clock_current_jitter_hi = 0;  // clock current cycle jitter value

        fork begin
            fork
                begin
                    // this fork branch never terminates, drives the clock in a loop
                    if (this.clock_period<=0) begin    // put in some protection
                        if (dbg_print_status)
                            s.printWarning(CLASS_NAME,$sformatf("Invalid period of %f found, waiting for specification of period > 0", clock_period));
                        wait ( this.clock_period>0 );
                    end
                    // offset start by phase delay specification
                    # ((clock_phase/360)*clock_period);
                    while (1) begin
                        clock_current_jitter_lo = fGetJitter(clock_jitter)*clock_period_lo/100;
                        clock_current_jitter_hi = fGetJitter(clock_jitter)*clock_period_hi/100;
                        #(clock_period_lo + clock_current_jitter_lo)
                        clk = 1;
                        -> clk_event;
                        -> clk_rise_event;
                        #(clock_period_hi + clock_current_jitter_hi)
                        clk = 0;
                        -> clk_event;
                        -> clk_fall_event;
                    end
                end
                begin
                    // this fork branch waits until clock is disabled
                    // if clock is disabled, entire fork will terminate and process stops
                    wait ( clock_en==0 );
                end
            join_any
            disable fork;   // nested so the fork disable doesn't kill anything else important
        end join

    endtask

        

endclass


 //////////////////////////////////////////////////////////////////////////////////
 // Extended class
 //     Allows specification of virtual interface
 //////////////////////////////////////////////////////////////////////////////////

class fidus_clock_gen_bfm extends fidus_clock_gen_bfm_base;
    
    virtual clk_bfm_if       o;

    //////////////////////////////////////////////////////////////////////////////////
    // function new
    //     Constructor
    //////////////////////////////////////////////////////////////////////////////////
   
    function new (
        string                name      = "fidus_clk_gen_bfm",
        virtual clk_bfm_if      oclk,
        real                  period_ns = 0,
        int                   enable    = 1,
        int                   dbg_en    = 1 );
        
        super.new(name, period_ns, enable, dbg_en);
        this.o              = oclk;
        
        // default drive
        oclk.c              = clk;
        fork
           tDriveClkOut();
        join_none

    endfunction


//////////////////////////////////////////////////////////////////////////////////
// task tDriveClkOut
//      This task drives the clock output interface.
//////////////////////////////////////////////////////////////////////////////////

    task tDriveClkOut();
        while (1) begin
            @ (clk_event);
            o.c = clk;
        end
    endtask


endclass


endpackage


   //////////////////////////////////////////////////////////////////////////////////
   // interface type clk_bfm_if
   //     Trivial signal bundle representing clock output.
   //     No ports, no modports, no clocking.
   //////////////////////////////////////////////////////////////////////////////////

interface clk_bfm_if ;
   logic    c;
endinterface


/*
Usage example


example declaration in TB

clk_bfm_if    clk_if_sys();

assign <clock net>    = clk_if_sys.c;
OR connect to DUT as appropriate


example usage in TC

...
parameter real pCLKFRQ_MHZ_AXI4L  = 75;     parameter real pCLK_PERIOD_AXI4L_NS = (1000/pCLKFRQ_MHZ_AXI4L);
...
fidus_clk_gen_bfm    bfm_sysclk;
...
initial begin
    ...
    bfm_sysclk              = new("System Clock", tb.clk_if_sys, pCLK_PERIOD_AXI4L_NS);  // starts automatically
    ...
end

OR
(to set clock w/ jitter, phase offset, duty cycle asymmetry)
initial begin
    ...                                                             
    bfm_sysclk              = new("System Clock", tb.clk_if_sys, 0, 0);
    ...                                                             ^initially disabled
    bfm_sysclk.fSetClockPeriodRealNs(pCLK_PERIOD_AXI4L_NS);
    bfm_sysclk.fSetJitterPerc(0.5);
    bfm_sysclk.fSetClockEnable(1);
    ...
end


*/
