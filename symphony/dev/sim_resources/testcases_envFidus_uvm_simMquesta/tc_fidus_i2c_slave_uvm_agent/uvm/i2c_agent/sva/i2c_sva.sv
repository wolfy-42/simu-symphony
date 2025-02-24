//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_sva.svh
// Project         : I2C
// Author          : Reza Shomalnasab
// Created         : 06.19.2023
//
// Description: 
//               Systemverilog assertions and cover properties to check i2c
//               protocol and the coverage
//----------------------------------------------------------------------


module i2c_sva #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8)(
    input logic disable_chk,
    input logic reset,
    input logic clk,
    input logic SCL,
    input logic SDA
);

  logic bus_transfer_active;    //active when bus is in use (between Start and STOP)
  logic byte_transfer_active;   //active during bus is in use and when 8 bit data transfer is active
  logic [4:0] bit_counter;      //counting 8 serial bits and their corresponding ACK/NACK
  logic [4:0] bit_counter_d;

//=============== model logic ====================

  initial begin
    bus_transfer_active = 0;
    byte_transfer_active = 0;
    bit_counter = 0;
    bit_counter_d = 0;
  end

  always @(posedge clk)  begin
    if (SCL && $fell(SDA))
      bus_transfer_active = 1;
    else if (SCL && $rose(SDA))
      bus_transfer_active = 0;
  end

  always @(posedge SCL or negedge bus_transfer_active) begin
    if (bus_transfer_active) begin
      bit_counter_d = bit_counter;
      bit_counter++;    
      if (bit_counter > I2C_DATA_WIDTH+1)
        bit_counter = 1;
    end
    else begin
      bit_counter = 0;
      bit_counter_d = 0;
    end

    if (bit_counter >= 1 && bit_counter < I2C_DATA_WIDTH+1)
      byte_transfer_active = 1;
    else
      byte_transfer_active = 0;
  end

//=============== sequences ====================

  sequence START;
    SCL && $fell(SDA);
  endsequence

  sequence STOP;
    SCL && $rose(SDA);
  endsequence

  sequence ACK;
      bit_counter == I2C_DATA_WIDTH+1 && ~SDA;
  endsequence

  sequence NACK;
      bit_counter == I2C_DATA_WIDTH+1 && SDA;
  endsequence

//=============== assert properties ====================

  //after START there should be a STOP 
  property p_start_stop;
    @(posedge clk) disable iff (reset || disable_chk) 
    START |-> ##[1:$] STOP;
  endproperty
  assert_start_stop : assert property (p_start_stop);

  //STOP condition should happen at ACK/NACK time 
  property p_stop_location;
    @(posedge clk) disable iff (reset || disable_chk) 
    bus_transfer_active ##0 STOP |->  bit_counter == 1 && bit_counter_d == I2C_DATA_WIDTH+1;

  endproperty
  assert_stop_location : assert property (p_stop_location);

  // data should be stable during transferring data (disabled since STOP may
  // occure during 1st bit of byte_transfer_active
  property p_data_stable;
    @(posedge clk) disable iff (reset || disable_chk) 
    byte_transfer_active && SCL |-> $stable(SDA);
  endproperty
  //assert_data_stable : assert property (p_data_stable);

//=============== cover properties ====================

  property p_start_detected;
    @(posedge clk) disable iff (reset || disable_chk) 
    $stable(SCL) |->  $fell(SDA);
  endproperty
  cover_start_detected : cover property (p_start_detected);

  property p_stop_detected;
    @(posedge clk) disable iff (reset || disable_chk) 
    $stable(SCL) |->  $rose(SDA);
  endproperty
  cover_stop_detected : cover property (p_stop_detected);
/*
  property p_repeated_start_detected;
    @(posedge clk) $stable(SCL) && $fell(SDA) |-> ##[1:$] $fell(SDA);
  endproperty
  cover_repeated_start_detected : cover property (p_repeated_start_detected);
*/
  property p_ack_detected;
    @(posedge SCL)  disable iff (reset || disable_chk) ACK;
  endproperty
  cover_ack_deteced : cover property (p_ack_detected);

  property p_nack_detected;
    @(posedge SCL)  disable iff (reset || disable_chk) NACK;
  endproperty
  cover_nack_deteced : cover property (p_nack_detected);

//=======================================================

endmodule : i2c_sva
