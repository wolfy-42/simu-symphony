//---------------------------------------------------------------------------//
//
// Copyright (C) 2018 Fidus Systems Inc.
// 
// Project       : simu
// Author        : Kevin Eckstrand
// Created       : 2018-06-19
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : BFM package that contains class for reset control.
//               Contains the following functions / tasks
//                 - new
//                 - fSetDebugMessagingOnOff
//                 - fAssertReset
//                 - fDeassertReset
//                 - tPulseRealNsReset
//               Package also contains reset interface type definition,
//               same interface type definition as used by the BFM class.
//               See bottom of file for example usage.
// Updated       : date / author - comment
//---------------------------------------------------------------------------//

package fidus_reset_gen_bfm_pkg;

import sim_management_pkg::*; 

class fidus_reset_gen_bfm;
    
    sim_management       s;
    string               CLASS_NAME;
    virtual reset_bfm_if o;

    logic  dbg_print_status;          // when set, debug messaging will be printed 
    

    //////////////////////////////////////////////////////////////////////////////////
    // function new
    //     Constructor
    //////////////////////////////////////////////////////////////////////////////////
   
    function new (
        string                name = "fidus_reset_bfm",
        virtual reset_bfm_if      orst,
        int                   dbg_en = 1 );
        
        this.CLASS_NAME     = name;
        this.o              = orst;
        dbg_print_status    = dbg_en;
        // default drive of interface
        orst.r              = 1'b0;
        orst.rn             = 1'b1;
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
// function fAssertReset
//      This function asserts the reset outputs.
//////////////////////////////////////////////////////////////////////////////////

    function void fAssertReset ();
        o.r  = 1'b1;
        o.rn = 1'b0;
        if (dbg_print_status)
            s.printMessage(CLASS_NAME, "Reset is asserted");
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// function fDeassertReset
//      This function deasserts the reset outputs.
//////////////////////////////////////////////////////////////////////////////////

    function void fDeassertReset ();
        o.r  = 1'b0;
        o.rn = 1'b1;
        if (dbg_print_status)
            s.printMessage(CLASS_NAME, "Reset is deasserted");
    endfunction


//////////////////////////////////////////////////////////////////////////////////
// task tAssertReset
//      This function deasserts the reset outputs.
//      Time unit is ps.
//////////////////////////////////////////////////////////////////////////////////

    task tPulseRealNsReset (
        input real pulsetime);
        if (pulsetime < 0)
            s.printError(CLASS_NAME,$sformatf("Pulse must be greater than 0 ps, pulse %f outside range", pulsetime));
        else begin
            fAssertReset();
            #(pulsetime*1000ps);
            fDeassertReset();
        end
    endtask


endclass

endpackage


   //////////////////////////////////////////////////////////////////////////////////
   // interface type reset_bfm_if
   //     Trivial signal bundle representing reset output.
   //     No ports, no modports, no clocking.
   //////////////////////////////////////////////////////////////////////////////////

interface reset_bfm_if ;
   logic    r;        // use this for active high reset
   logic    rn;       // use this for active low reset
endinterface

// example declaration
//    reset_bfm_if    ref_rst;


/*
Usage example


example declaration in TB

reset_bfm_if    rst_if_sys();

assign <active high reset>    = rst_if_sys.r;
assign <active low reset>     = rst_if_sys.rn;
OR connect to DUT as appropriate


example usage in TC

...
fidus_reset_bfm    bfm_sysrst;
...
initial begin
    ...
    bfm_sysrst              = new("System Reset", tb.rst_if_sys);
    ...
    bfm_sysrst.tPulseRealNsReset(1000);

    OR
    
    bfm_sysrst.fAssertReset();
    #1us;
    bfm_sysrst.fDeassertReset();
    ...
end


*/
