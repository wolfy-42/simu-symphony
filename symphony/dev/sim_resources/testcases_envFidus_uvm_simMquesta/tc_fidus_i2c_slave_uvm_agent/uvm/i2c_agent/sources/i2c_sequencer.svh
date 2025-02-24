//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_sequencer.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.16.2023
//
// Description: 
//
//----------------------------------------------------------------------

class i2c_sequencer #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_sequencer #(i2c_item#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH));

    //i2c_agent #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)      m_agent;

    `uvm_component_param_utils_begin(i2c_sequencer#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
    `uvm_component_utils_end

    function new(string name, uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

endclass // i2c_sequencer
