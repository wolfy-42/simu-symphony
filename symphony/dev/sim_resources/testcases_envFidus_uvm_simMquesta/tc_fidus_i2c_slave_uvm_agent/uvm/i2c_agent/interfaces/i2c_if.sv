//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_if.sv
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.12.2023
//
// Description: 
//
//----------------------------------------------------------------------

interface i2c_if #(parameter I2C_ADDR_WIDTH = 7) (input logic CLK, RESET_N);

    //tri1  SCL;

    logic SCL_oe;
    logic SDA_oe;

    logic SCL;
    logic SDA;

    //logic CLK_del;

    //assign #(0) CLK_del = CLK;
    
/* -----\/----- EXCLUDED -----\/-----
    modport controller (
                        ref    SDA,
                        output SCL
                        );

    modport peripheral (
                        ref    SDA,
                        input  SCL
                        );
 -----/\----- EXCLUDED -----/\----- */

    clocking controller_cb @(posedge CLK);
        //default input #1ns output #2ns;
        input  RESET_N;
        output SCL_oe;
        inout  SDA_oe;
    endclocking // monitor_cb

    clocking peripheral_cb @(posedge CLK);
        //default input #1ns output #2ns;
        input RESET_N;
        input SCL_oe;
        inout SDA_oe;
    endclocking // monitor_cb

    clocking monitor_cb @(posedge CLK);
        //default input #1ns output #2ns;
        input RESET_N;
        input SCL_oe;
        input SDA_oe;
    endclocking // monitor_cb

    modport controller_if_mp (clocking controller_cb);
    modport peripheral_if_mp (clocking peripheral_cb);
    modport monitor_if_mp (clocking monitor_cb);

endinterface // i2c_if

