//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_defines.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.12.2023
//
// Description: 
//
//----------------------------------------------------------------------
//`define I2C_ADDR_WIDTH 7
//`define I2C_DATA_WIDTH 8

//`define I2C_PARAM_DECL #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8)
//`define I2C_PARAM_IF #(.I2C_ADDR_WIDTH(7), .I2C_DATA_WIDTH(8))
//`define I2C_PARAM_ITEM #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)
//`define I2C_PARAM_ORDER #(7,8)
