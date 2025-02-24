//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_agent.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.12.2023
//
// Description: 
//
//----------------------------------------------------------------------

class i2c_agent #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_agent;

    i2c_config    #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) m_config; // (e.g. controller vs peripheral)
    i2c_driver    #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) m_driver;
    i2c_monitor   #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) m_monitor;
    i2c_sequencer #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) m_sequencer;
    
    `uvm_component_param_utils_begin(i2c_agent#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
        `uvm_field_object(m_config,    UVM_ALL_ON)
        `uvm_field_object(m_driver,    UVM_ALL_ON)
        `uvm_field_object(m_monitor,   UVM_ALL_ON)
        `uvm_field_object(m_sequencer, UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name, uvm_component parent = null);
        super.new(name,parent);
    endfunction // new
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_config     = i2c_config#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("m_config",    this);
        m_monitor    = i2c_monitor#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("m_monitor",    this);

	//uvm_config_db#(uvm_active_passive_enum)::get(this,"","is_active",is_active);
        //`uvm_info ("i2c_agent",$sformatf("this agent is %0s",get_is_active()),UVM_LOW)

        if(get_is_active()) begin
            m_driver               = i2c_driver#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("m_driver",    this);
            m_sequencer            = i2c_sequencer#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("m_sequencer",    this);
        end

    endfunction // build_phase

    function void connect_phase(uvm_phase phase);

        m_monitor.m_agent = this;

        if(get_is_active()) begin
            m_driver.m_agent = this;
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);            
        end
        
    endfunction // connect_phase

    function void set_disable_storage_check_at_addr(bit val);
        m_driver.m_periph_dis_storage_chk_at_addr = val;
    endfunction
          
endclass // i2c_agent

  
