//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_config.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.12.2023
//
// Description: 
//
//----------------------------------------------------------------------

class i2c_config #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_object;

    rand i2c_context_e m_context;
    rand bit [I2C_ADDR_WIDTH-1:0] m_addr_min = 0;
    rand bit [I2C_ADDR_WIDTH-1:0] m_addr_max = 0;

    rand bit m_peripheral_report_all = 0;

    constraint c_default {
        soft m_addr_min <= m_addr_max;
        soft m_peripheral_report_all == 0;
    }
    
    `uvm_object_param_utils_begin(i2c_config #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
        `uvm_field_enum(i2c_context_e, m_context, UVM_ALL_ON)
        `uvm_field_int(m_addr_min, UVM_ALL_ON)        
        `uvm_field_int(m_addr_max, UVM_ALL_ON)        
        `uvm_field_int(m_peripheral_report_all, UVM_ALL_ON)        
    `uvm_object_utils_end

    function new(string name = "i2c_config");
        super.new(name);
    endfunction // new
    
endclass // i2c_config
