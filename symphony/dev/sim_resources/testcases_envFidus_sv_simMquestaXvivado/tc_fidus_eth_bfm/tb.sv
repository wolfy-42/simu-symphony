//-------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Dessislav Valkov
// Created       : 2009-01-27
//--------------------------------------------------------------------

// Module declaration
module tb ();
  import sim_management_pkg::*;
  parameter MODULE_NAME = "tb";

  sim_management s;
  string msg;
  integer seed;

  // Packages
  // NOTE - sim_management_pkg is included inside the test-case.

  initial 
  begin 
    seed = `SEED_INITIAL_VALUE ;        
    msg.itoa (`SEED_INITIAL_VALUE);
    msg = {"The seed is set to ", msg," for this simulation.\n"};
    s.printMessage (MODULE_NAME, msg);
  end
  
  // RIPL Library instantiations
  sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
  
  // Test case instantiation
  test_case test_case_inst ();

endmodule 

