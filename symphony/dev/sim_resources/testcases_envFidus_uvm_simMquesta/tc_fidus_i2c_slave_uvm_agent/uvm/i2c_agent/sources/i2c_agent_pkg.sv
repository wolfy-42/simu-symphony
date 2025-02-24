//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_agent_pkg.sv
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.12.2023
//
// Description: 
//
//----------------------------------------------------------------------

package i2c_agent_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"
    
   `include "i2c_defines.svh"

    typedef enum {
                  I2C_PERIPHERAL = 'b0,
                  I2C_CONTROLLER = 'b1
                  } i2c_context_e;

    `include "i2c_item.svh"   
    `include "i2c_sequences.svh"

    // Components knows theirs parent
    typedef  i2c_agent;
    `include "i2c_sequencer.svh"
    
    `include "i2c_config.svh"
    `include "i2c_driver.svh"
    `include "i2c_driver_delayed.svh"
    `include "i2c_monitor.svh"
    `include "i2c_agent.svh"

endpackage // i2c_agent_pkg
