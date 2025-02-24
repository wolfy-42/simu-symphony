//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_item.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.16.2023
//
// Description: 
//
//----------------------------------------------------------------------

class i2c_item #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_sequence_item;

    //NOTE: update_SDA is 1 by default to update SDA bus, if you don't want to
	    //update the SDA bus and this variable is set to 0 so the driver
	    //will release the bus and other components may take over the bus.
	    //in case you want to keep the previous cycle value on the SDA
	    //bus, you need to set update_SDA=1 and create a req with the
	    //previous SDA bus value.
    //NOTE: if you want to apply customized delay to SDA and SCL make sure the
	    //coresponding update_* field is set to 1.

    rand int                    size;
    rand bit                    update_SDA;
    rand bit                    update_SCL;
    rand bit                    wait_posedge;
    rand logic                  SDA[];
    rand logic                  SCL[];
    rand int                    t_to_SDA_ps;
    rand int                    t_to_SCL_ps;

    constraint c_consistant {
        SDA.size() == SCL.size();
        SDA.size() == size;
        SCL.size() == size;        
    }

    constraint c_default {
        soft update_SDA == 1'b1;
        soft update_SCL == 1'b1;
        soft wait_posedge == 1'b1;
        soft t_to_SDA_ps == 0;
        soft t_to_SCL_ps == 0;        
    }

    `uvm_object_param_utils_begin(i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
        `uvm_field_int(update_SDA,     UVM_ALL_ON)
        `uvm_field_int(update_SCL,     UVM_ALL_ON)
        `uvm_field_int(wait_posedge,  UVM_ALL_ON)
        `uvm_field_sarray_int(SDA,    UVM_ALL_ON)
        `uvm_field_sarray_int(SCL,    UVM_ALL_ON)
        `uvm_field_int(t_to_SDA_ps,   UVM_ALL_ON)
        `uvm_field_int(t_to_SCL_ps,   UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_item");
        super.new(name);
    endfunction // new
    
endclass // i2c_item
