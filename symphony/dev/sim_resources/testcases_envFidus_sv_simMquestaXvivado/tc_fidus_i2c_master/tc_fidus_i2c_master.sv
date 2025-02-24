//--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Anna Raikin
// Created       : 2018-05-22
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Test-case for I2C Master BFM in Native Mode.
// 					 The test uses Slave block from Open Source
//--------------------------------------------------------------------//
`include "i2cSlave_define.v"

// Module declaration
module test_case();

	// System Verilog Simulation management package
	import sim_management_pkg::*;
	import fidus_clock_gen_bfm_pkg::*;
	import fidus_reset_gen_bfm_pkg::*;
	import fidus_i2c_master_bfm_pkg::*;
	
	// Variables and parameters ;
	sim_management s;
	parameter TC_NAME = "tc_fidus_i2c_master_bfm";
		
	logic [7:0] 	total_data_write [];
	logic [7:0] 	total_data_read [];
		
	// signals	
	wire				slave_sda;
	wire				slave_scl;
	logic [7:0]		reg0_out;
	logic [7:0]		reg1_out;
	logic [7:0]		reg2_out;
	logic [7:0]		reg3_out;
	logic [7:0]		reg0_in;
	logic [7:0]		reg1_in;
	logic [7:0]		reg2_in;
	logic [7:0]		reg3_in;
	logic [7:0]		register_addr;
	logic	[3:0]		error_cnt;
	logic 			error_sent;
	logic				error_rcved;
	logic 			repeated_start;
	int i;
	
	// BFM local instances becuse Active-HDL can't refere to the TB level (it's a tool bug)
	fidus_clock_gen_bfm clk_100mhz_bfm;
	fidus_clock_gen_bfm clk_100khz_bfm;
	fidus_reset_gen_bfm reset_bfm;  
	fidus_i2c_master_bfm i2c_master_bfm;
	 
	// I2C master interface
	fidus_i2c_master_if i2c_master_if
	(
		.clk		(tb.clk_i2c_if.c),
		.reset	(tb.reset_if.r)
	);
	
	// slave 
	i2cSlave i2cSlave
	(
		.clk			(tb.clk_if.c),
		.rst			(tb.reset_if.r),
		.sda			(slave_sda),
		.scl			(slave_scl),
		.myReg0		(reg0_out),
		.myReg1		(reg1_out),
		.myReg2		(reg2_out),
		.myReg3		(reg3_out),
		.myReg4		(reg0_in), 
		.myReg5		(reg1_in), 
		.myReg6		(reg2_in), 
		.myReg7		(reg3_in)  
	);
	
	assign reg0_in  = reg0_out;
	assign reg1_in  = reg1_out;
	assign reg2_in  = reg2_out;
	assign reg3_in  = reg3_out;
	
	reg end_wr;
	//----------------------------------------------------------------
	// Tests are based on write to slave and read back.
	// There are 4 registers in slave 
	// Errors are reported if there in no ACK or data read back is wrong
	initial begin
		// Initialize the simulation
		s.initSim(TC_NAME);
	
		s.printMessage (TC_NAME,"Simulation is initialized");
		s.printMessage (TC_NAME, "Global Reset asserted");
		s.printMessage (TC_NAME, "Set clock 100MHz");

		s.printMessage (TC_NAME, "Set clock 100MHz");
		clk_100mhz_bfm = new("clk_100mhz", tb.clk_if, 10.00);
		s.printMessage (TC_NAME, "Set clock 100KHz for Normal Mode");
		clk_100khz_bfm = new("clk_100khz", tb.clk_i2c_if, 10000.00);		
	
		reset_bfm = new("rst_bfm", tb.reset_if);

      reset_bfm.fAssertReset();
      #100;
      reset_bfm.fDeassertReset();
		error_cnt = 0;
		error_rcved = 0;
		error_sent = 0;
		end_wr = 0;
		repeated_start = 0;
		// Initialize master BFM
		i2c_master_bfm = new("fidus_i2c_master_bfm", i2c_master_if, 1);
		#1000;
		// send/read message 1 byte
		total_data_write = new[1];
		total_data_read = new[1];
		register_addr = 2;
		total_data_write[0] = 8'hAA;		
		s.printMessage (TC_NAME, "Note: Start testing 1 byte write %h and read.", total_data_write[0]);		
		i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 1, register_addr, 0, total_data_write, repeated_start, error_sent);
		#100;
		end_wr = 1;
		i2c_master_bfm.tReceiveMessage(`I2C_ADDRESS, 1, register_addr, 0, total_data_read, repeated_start, error_rcved);
		
		if (error_sent || error_rcved || (total_data_read[0] !== total_data_write[0])) begin
			if (error_sent) begin
				s.printError(TC_NAME,$sformatf("ERROR : Something happened during message send process"));
			end
			
			if (error_rcved) begin
				s.printError(TC_NAME,$sformatf("ERROR : Something happened during message received process"));
			end
			
			s.printError(TC_NAME,$sformatf("ERROR : The read data  %h is not what is expected. Should be  %h", total_data_read[0], total_data_write[0]));
			error_cnt++;
		end else begin
			s.printMessage (TC_NAME, "Note: The 1 byte read was sucessfull. The data %h was recieved.", total_data_read[0]);
		end
		
		
		// send/read message 4 byte
		total_data_write = new[4];
		total_data_read = new[4];
		register_addr = 0;
		total_data_write[0] = 8'h01;
		total_data_write[1] = 8'h23;
		total_data_write[2] = 8'h45;
		total_data_write[3] = 8'h67;
		s.printMessage (TC_NAME, "Note: Start testing 4 bytes write of data %h%h%h%h and read.", total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0]);				
		i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 4, register_addr, 0, total_data_write, repeated_start, error_sent);
		#100;
		i2c_master_bfm.tReceiveMessage(`I2C_ADDRESS, 4, register_addr, 0, total_data_read, repeated_start, error_rcved);

		if (error_sent || error_rcved || (total_data_read[0] !== total_data_write[0]) || (total_data_read[1] !== total_data_write[1]) || (total_data_read[2] !== total_data_write[2]) || (total_data_read[3] !== total_data_write[3])) begin
			if (error_sent) begin
				s.printError(TC_NAME,$sformatf("ERROR : Something happened during message send process"));
			end
			if (error_rcved) begin
				s.printError(TC_NAME,$sformatf("ERROR : Something happened during message received process"));
			end
			
			s.printError(TC_NAME,$sformatf("ERROR : The read data %h, %h, %h, and %h is not what is expected. Should be %h, %h, %h, and %h", total_data_read[3], total_data_read[2], total_data_read[1], total_data_read[0], total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0]));
			error_cnt++;
		end else begin
			s.printMessage (TC_NAME, "Note: The read was sucessfull. The data %h, %h, %h, and %h was recieved.", total_data_read[3], total_data_read[2], total_data_read[1], total_data_read[0]);
		end
		
		// Repeat start test
		repeated_start = 1;
		
		for (i=0; i<4; i++) begin
			total_data_write[0] = 8'h01 + i;
			total_data_write[1] = 8'h23 + i;
			total_data_write[2] = 8'h45 + i;
			total_data_write[3] = 8'h67 + i;
			s.printMessage (TC_NAME, "Note: Start testing 4 bytes write of data %h%h%h%h and read.", total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0]);				
			i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 4, register_addr, 0, total_data_write, repeated_start, error_sent);
			#100;
			end_wr = 1;
			i2c_master_bfm.tReceiveMessage(`I2C_ADDRESS, 4, register_addr, 0, total_data_read, repeated_start, error_rcved);
	
			if (error_sent || error_rcved || (total_data_read[0] !== total_data_write[0]) || (total_data_read[1] !== total_data_write[1]) || (total_data_read[2] !== total_data_write[2]) || (total_data_read[3] !== total_data_write[3])) begin
				if (error_sent) begin
					s.printError(TC_NAME,$sformatf("ERROR : Something happened during message send process"));
				end
				if (error_rcved) begin
					s.printError(TC_NAME,$sformatf("ERROR : Something happened during message received process"));
				end
				
				s.printError(TC_NAME,$sformatf("ERROR : The read data %h, %h, %h, and %h is not what is expected. Should be %h, %h, %h, and %h", total_data_read[3], total_data_read[2], total_data_read[1], total_data_read[0], total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0]));
				error_cnt++;
			end else begin
				s.printMessage (TC_NAME, "Note: The read was sucessfull. The data %h, %h, %h, and %h was recieved.", total_data_read[3], total_data_read[2], total_data_read[1], total_data_read[0]);
			end
		end	
		
		// Simulation End
		if (error_cnt == 0) begin
			s.printPass(TC_NAME,$sformatf("The simulation passed!"));
		end	
      #100;
      s.testComplete;
	end	
		
	// assign slave/master ports
	assign slave_sda = (i2c_master_if.sda_t == 1'b0) ? i2c_master_if.sda_out : 1'bz;
	assign i2c_master_if.sda_in = slave_sda;
	pullup(slave_sda);
	
	assign slave_scl = (i2c_master_if.scl_t == 1'b0) ? i2c_master_if.scl_out : 1'bz;
	assign i2c_master_if.scl_in = slave_scl;	
	pullup(slave_scl);

endmodule 	  