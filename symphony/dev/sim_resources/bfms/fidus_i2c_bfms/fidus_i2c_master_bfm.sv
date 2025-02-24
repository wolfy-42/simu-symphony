//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
// 
// Project       : simu
// Author        : Anna Raikin	
// Created       : 2021-02-22
//---------------------------------------------------------------------------//
//---------------------------------------------------------------------------//
// Description   : BFM package that contains class for clock control.
//               Extended class ties to virtual interface.
//               Contains the following functions / tasks
//               fidus_i2c_master_bfm_base (base class)
//                 	- new
//                 	- fSetDebugMessagingOnOff
//							- tSendMessage
//							- tReceiveMessage
//							- tSendStartBit
//                 	- tSendDeviceAddressFrame
//                 	- tSendStopBit
//                 	- tSendDataFrame
//                 	- tReceiveDataFrame
// 						- tSetFullClock
//                 	- tWaitAckBit
//                 	- tWaitHiClk
// 						- tWaitLoClk
//               Package also contains clock interface type definition,
//               same interface type definition as used by the BFM class.
//               See bottom of file for example usage.
// Updated       : date / author - comments
// Following https://www.ti.com/lit/an/slva704/slva704.pdf?ts=1614186934841&ref_url=https%253A%252F%252Fwww.google.com%252F
//Read
//    __    ___ ___ ___ ___ ___ ___ ___         ___ ___ ___ ___ ___ ___ ___ ___     ___ ___ ___ ___ ___ ___ ___ ___        __
//sda   \__/_6_X_5_X_4_X_3_X_2_X_1_X_0_\_R___A_/_7_X_6_X_5_X_4_X_3_X_2_X_1_X_0_\_A_/_7_X_6_X_5_X_4_X_3_X_2_X_1_X_0_\_A____/
//    ____   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   ____
//scl  ST \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ SP
//
//Write
//    __    ___ ___ ___ ___ ___ ___ ___ ___     ___ ___ ___ ___ ___ ___ ___ ___     ___ ___ ___ ___ ___ ___ ___ ___ ___    __
//sda   \__/_6_X_5_X_4_X_3_X_2_X_1_X_0_/ W \_A_/_7_X_6_X_5_X_4_X_3_X_2_X_1_X_0_\_A_/_7_X_6_X_5_X_4_X_3_X_2_X_1_X_0_/ N \__/
//    ____   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   ____
//scl  ST \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ SP

//---------------------------------------------------------------------------//

package fidus_i2c_master_bfm_pkg;

import sim_management_pkg::*; 

class fidus_i2c_master_bfm #(
		ADDR_SIZE = 7 // size of address bus, can be 7 or 10
);
    
   sim_management         	s;
   string                 	CLASS_NAME;
		
	static bit 					error_set;
	static int					number_frame_read;
	int 							hi_time;					
	int 							lo_time;
	
	virtual fidus_i2c_master_if i2c_master_io;   // i2c master interface
 
   logic  dbg_print_status;          // when set, debug messaging will be printed 


    //////////////////////////////////////////////////////////////////////////////////
    // function new
    //     Constructor
    //////////////////////////////////////////////////////////////////////////////////
   
    function new (
      string                	name = "fidus_i2c_master_bfm",
		virtual 						fidus_i2c_master_if i2c_master_io,
      int                   	dbg_en = 1);
        
      this.CLASS_NAME     = name;
		
		this.i2c_master_io             		= i2c_master_io;
		
      // default variable states
		i2c_master_io.scl_out         		= 1;                          // SCL out
		i2c_master_io.scl_t         			= 0;                          // SCL tri-state
		i2c_master_io.sda_out          		= 1;                          // SDA out
		i2c_master_io.sda_t          			= 0;                          // SDA tri-state
      dbg_print_status     					= dbg_en;
		this.error_set								= 0;
		this.number_frame_read 					= 0;

    endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetDebugMessagingOnOff
   //     Enables/disables debug messaging associated with events, state
   //       transitions, etc  (intended for debug only)
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetDebugMessagingOnOff(
      input logic dbg_print_status);
      s.printMessage(CLASS_NAME,$sformatf("Turning debug logging %0s, was previously set %0s",
         ((dbg_print_status) ? "ON" : "OFF"), ((this.dbg_print_status) ? "ON" : "OFF")));
      this.dbg_print_status = dbg_print_status;
   endfunction : fSetDebugMessagingOnOff


   //////////////////////////////////////////////////////////////////////////////////
   // Waits for Hi and Lo clock edge
   //////////////////////////////////////////////////////////////////////////////////
   task tWaitHiClk();
		@(posedge i2c_master_io.clk);
   endtask : tWaitHiClk
	
	task tWaitLoClk();
		@(negedge i2c_master_io.clk);
   endtask : tWaitLoClk


	//////////////////////////////////////////////////////////////////////////////////
   // Send Address Frame (start bit, address, read/write, wait for ack)
	// Raising error if something wrong
   //////////////////////////////////////////////////////////////////////////////////
	task tSendDeviceAddressFrame (
		input logic [ADDR_SIZE-1:0] address,
		input bit	read_write_n,
		output bit 	error
	);
		int 			addr_bit;
		logic [7:0] address_loc;
		int 			stretched_found;
		
		i2c_master_io.sda_t = 0;
		i2c_master_io.scl_t = 0;
		
		if (dbg_print_status && (ADDR_SIZE != 7) && (ADDR_SIZE != 10))  
			s.printError(CLASS_NAME,$sformatf("ERROR : The address size %0h is wrong. Has to be 7 or 10!", ADDR_SIZE));
		else if (dbg_print_status)	
			s.printMessage(CLASS_NAME,$sformatf("Start sending address frame with address %0h", address));
	
		
		// send address bus
		if (ADDR_SIZE == 7) begin
			for (addr_bit = ADDR_SIZE; addr_bit > 0; addr_bit--) begin
				i2c_master_io.sda_out = address[addr_bit-1];
				tSetFullClock(stretched_found);
			end
			// send read/write bit
			i2c_master_io.sda_out = read_write_n;

			tSetFullClock(stretched_found);
			
			tWaitAckBit(0, error_set);
						
			if (dbg_print_status && error_set)  
				s.printError(CLASS_NAME,$sformatf("ERROR : Ack never happened"));
			else if (dbg_print_status)  
				s.printMessage(CLASS_NAME,$sformatf("Notice : Ack happened"));	
		
		end else begin // 10 bits
			address_loc = {5'b11110, address[9:8], 1'b0};
			
			for (addr_bit = 8; addr_bit > 0; addr_bit--) begin
				i2c_master_io.sda_out = address_loc[addr_bit-1];
				tSetFullClock(stretched_found);
			end	
			
			i2c_master_io.sda_out = 0;
			tWaitAckBit(0, error_set); // first ack
			
			if (dbg_print_status && error_set)  
				s.printError(CLASS_NAME,$sformatf("ERROR : Ack never happened after first part of address"));
			else if (dbg_print_status)  
				s.printMessage(CLASS_NAME,$sformatf("Notice : Ack happened after first part of address"));	
			
			tWaitHiClk();
			i2c_master_io.sda_out = 1;
			tWaitHiClk();
			i2c_master_io.sda_out = 0;
			
			for (addr_bit = 8; addr_bit > 0; addr_bit--) begin
				i2c_master_io.sda_out = address[addr_bit-1];
				tSetFullClock(stretched_found);
			end	
			
			tWaitAckBit(0, error_set); // second ack
			
		
			if (read_write_n) begin // if it is read, send address again with read bit
				tWaitHiClk();
				i2c_master_io.sda_out = 1;
				tSendStartBit(); // request data from this register
				address_loc = {5'b11110, address[9:8], 1'b1};
			
				for (addr_bit = 8; addr_bit > 0; addr_bit--) begin
					i2c_master_io.sda_out = address_loc[addr_bit-1];
					tSetFullClock(stretched_found);
				end	
				
				i2c_master_io.sda_out = 0;
				tWaitAckBit(0, error_set); // third ack
				
				if (dbg_print_status && error_set)  
					s.printError(CLASS_NAME,$sformatf("ERROR : Ack never happened after first part of address"));
				else if (dbg_print_status)  
					s.printMessage(CLASS_NAME,$sformatf("Notice : Ack happened after first part of address"));	
			end
			
			if (dbg_print_status && error_set)  
				s.printError(CLASS_NAME,$sformatf("ERROR : Ack never happened"));
			else if (dbg_print_status)  
				s.printMessage(CLASS_NAME,$sformatf("Notice : Ack happened"));	

			
		end
		
		i2c_master_io.sda_out = 1;
		error = error_set;
					
	endtask : tSendDeviceAddressFrame
	
	//////////////////////////////////////////////////////////////////////////////////
    // Send Start Bit. Separate task because it can be called few times
    //////////////////////////////////////////////////////////////////////////////////
	task tSendStartBit ();
		int i;
		tWaitHiClk();
		i2c_master_io.sda_t = 0;
		i2c_master_io.scl_t = 0;
		i2c_master_io.sda_out = 1; // start of start condition, pull data high
		i2c_master_io.scl_out = 1; // start of start condition, pull clock high
		tWaitHiClk();	
		// start bit
		i2c_master_io.sda_out = 0; // start of start condition, pull data low 
		tWaitHiClk();
		i2c_master_io.scl_out = 0; // pull clock low

	endtask : tSendStartBit
	
	
	//////////////////////////////////////////////////////////////////////////////////
   // Send Stop Bit. Separate task because it can be omitted if repeated start condition happened
   //////////////////////////////////////////////////////////////////////////////////
	task tSendStopBit ();
		i2c_master_io.sda_t = 0;
		i2c_master_io.scl_t = 0;
		
		// stop bit
		i2c_master_io.sda_out = 0; // start of stop condition, pull scl high
		tWaitHiClk();
		i2c_master_io.scl_out = 1; // start of stop condition, pull scl high
		tWaitHiClk();
		i2c_master_io.sda_out = 1; // pull data high
	endtask : tSendStopBit
	
		
	//////////////////////////////////////////////////////////////////////////////////
   // Send Data Frame (data, wait for ack) 
	// This is just for 1 byte, if there are more bytes, this task will be called 
	// more times
	// Raising error if something wrong
   //////////////////////////////////////////////////////////////////////////////////
	task tSendDataFrame (
		input logic [7:0] data_write,
		output 				error
	);	
		int data_byte;
		int stretched_found;
		
		i2c_master_io.sda_t = 0;
		i2c_master_io.scl_t = 0;
		tWaitHiClk();
		i2c_master_io.sda_out = 0;
		i2c_master_io.scl_out = 0;
		
		for (data_byte = 8;  data_byte > 0; ) begin

			i2c_master_io.sda_out = data_write[data_byte-1];
			tSetFullClock(stretched_found);
			if (!stretched_found) begin
				data_byte--;
			end	
		end
			
		// ack
		tWaitAckBit(0, error_set);
		
		if (dbg_print_status && error_set) begin
			s.printError(CLASS_NAME,$sformatf("ERROR : Ack never happened after data frame was sent"));
		end else if (dbg_print_status) begin
			s.printMessage(CLASS_NAME,$sformatf("Note : Data was succefully sent"));
		end			
		
		error = error_set;
	
	endtask : tSendDataFrame
	
	//////////////////////////////////////////////////////////////////////////////////
   // Receive Data Frame (put out clock, receive data, wait for ack)
	// This is just for 1 byte, if there are more bytes, this task will be called 
	// more times	
	// Raising error if something wrong
   //////////////////////////////////////////////////////////////////////////////////
	task tReceiveDataFrame (
		output logic [7:0]	data_read,
		output logic 			error_rcved
	);
	
		int data_byte;
		int stretched_found;

		i2c_master_io.sda_t = 1;
		i2c_master_io.scl_t = 0;
		
		s.printMessage(CLASS_NAME,$sformatf("Note : Start receiving data"));
		
		for (data_byte = 8; data_byte > 0;) begin
			tSetFullClock(stretched_found);
	
			data_read[data_byte-1] = i2c_master_io.sda_in;
			if (!stretched_found) begin
				data_byte--;
			end			
		end
		
		if (dbg_print_status && error_set) begin
			s.printError(CLASS_NAME,$sformatf("ERROR : Ack never happened after data frame was receieved"));
		end else if (dbg_print_status) begin
			s.printMessage(CLASS_NAME,$sformatf("Note : Data Frame was received"));
		end	
			
		error_rcved = error_set;
		
	endtask : tReceiveDataFrame
		
	//////////////////////////////////////////////////////////////////////////////////
   // Wait for the ACK event
   /////////////////////////////////////////////////////////////////////////////////
	task tWaitAckBit (
		input bit ack_nack,
		output bit error
	);
	
		int stretched_found;
	
		i2c_master_io.sda_t = 1;
		i2c_master_io.scl_t = 0;
		i2c_master_io.sda_out = 0;
		stretched_found = 1;

		fork 
			begin
				while (stretched_found) begin
					tSetFullClock(stretched_found);
				end	
			end
			
			begin
				@ (posedge i2c_master_io.scl_in);
				if (i2c_master_io.sda_in !== ack_nack) begin
					error = 1;
				end else begin
					error = 0;
				end
			end	
		join 	begin
			
		end
		
		if (dbg_print_status && error) begin
			s.printError(CLASS_NAME,$sformatf("ERROR : Ack never happened"));
		end else if (dbg_print_status) begin
			s.printMessage(CLASS_NAME,$sformatf("Note : Ack was received"));
		end
		
		i2c_master_io.scl_out = 0; // pull clock low

		i2c_master_io.sda_t = 0;
		tWaitHiClk();		
	
	endtask : tWaitAckBit

	//////////////////////////////////////////////////////////////////////////////////
   // Set full period of SCL
   //////////////////////////////////////////////////////////////////////////////////
	
	task tSetFullClock (
		output stretched_found
	);
		tWaitLoClk();
		i2c_master_io.scl_out = 1; // pull clock high
		
		tWaitHiClk();
		// Checking whether the slave is throttling
		// yes, release the clock 
		if (i2c_master_io.scl_in !== 1'b1) begin
			s.printMessage(CLASS_NAME,$sformatf("Note : Looks like the slave is stretching it's clock"));
			stretched_found = 1;
			i2c_master_io.scl_t = 1; // pull clock high
		end else begin
			
			stretched_found = 0;
			i2c_master_io.scl_t = 0; // pull clock high
		end	
		i2c_master_io.scl_out = 0; // pull clock low
		
	endtask : tSetFullClock 
	
	//////////////////////////////////////////////////////////////////////////////////
   // Put this all together 
   /////////////////////////////////////////////////////////////////////////////////
	// Send message 
   /////////////////////////////////////////////////////////////////////////////////
	
	task tSendMessage (
		input logic [ADDR_SIZE-1:0] 	device_address,
		input int							number_total_bytes,
		input logic [7:0] 				reg_address,
		input bit							no_register_addr,
		ref logic [7:0] 					total_data_write[],
		input bit 							repeated_start,		
		output logic						error	
	);	

		int i;
		int error_send_addr;
		int error_send_data;
		int all_done = 0;
		
		fork : send_msg
		begin
			tSendStartBit();
			tSendDeviceAddressFrame(device_address, 0, error_send_addr);
			
			
			if (error_send_addr || error_send_data) begin
				error = 1;
			end
			
			// register address
			if (!no_register_addr) begin // some i2c don't have registers. if that's a case, no need to send register address
				tSendDataFrame(reg_address, error_send_data);
			end
			
			s.printMessage(CLASS_NAME,$sformatf("Note : sending addres register %h", reg_address));
			
			if (number_total_bytes > 0) begin
				for (i=0; i<number_total_bytes; i++) begin
					tSendDataFrame(total_data_write[i], error_send_data);
					if (error_send_data) begin
						error = 1;
					end
				end
			end else begin	
				s.printError(CLASS_NAME,$sformatf("ERROR : Number of byte can't be 0"));
			//	return;
			end
			
			if (!repeated_start) begin // if not repeated start condition
				tSendStopBit();
			end
			
			all_done = 1;
				
		end
		join_none begin

				
			begin
				@(posedge all_done, posedge i2c_master_io.reset);
				disable send_msg;
				if (i2c_master_io.reset) begin	
				   // default variable states
					i2c_master_io.scl_out         		= 1;                          // SCL out
					i2c_master_io.scl_t         			= 0;                          // SCL tri-state
					i2c_master_io.sda_out          		= 1;                          // SDA out
					i2c_master_io.sda_t          			= 0;                          // SDA tri-state
				end				
			end	
		end
		
	endtask : tSendMessage

	/////////////////////////////////////////////////////////////////////////////////
	// Recieve message 
   /////////////////////////////////////////////////////////////////////////////////
	task tReceiveMessage (
		input logic [ADDR_SIZE-1:0] 	device_address,
		input int							number_total_bytes,
		input logic [7:0] 				reg_address,
		input bit							no_register_addr,
		ref logic [7:0] 					total_data_read[],
		input bit 							repeated_start,
		output logic						error
	);
		
		int i;
		int error_send_addr = 0;
		int error_send_data = 0;
		int stretched_found = 0;
		int all_done = 0;
		
		tSendStartBit(); // set the register address
		
		fork : rcv_msg 
		begin
			// register address
			if (!no_register_addr) begin // some i2c don't have registers. if that's a case, no need to send register address
				tSendDeviceAddressFrame(device_address, 0, error_send_addr);
				tSendDataFrame(reg_address, error_send_data);
				tSendStartBit(); // request data from this register
			end
			
			if (error_send_addr || error_send_data) begin
				error = 1;
			end
			
			
			tSendDeviceAddressFrame(device_address, 1, error_send_addr);
			
			if (error_send_addr) begin
				error = 1;
			end
			
			if (number_total_bytes > 0) begin
		
				for (i=0; i<number_total_bytes; ) begin
					tReceiveDataFrame(total_data_read[i], error);
					if (i != (number_total_bytes-1)) begin // ack is sent after every byte but last
						i2c_master_io.sda_t = 0;
						i2c_master_io.sda_out = 0;
						
						tSetFullClock (stretched_found);
						if (!stretched_found) begin
							i++;
						end	
					end else begin
						i++;
					end	
				end
					
			end else begin	
				s.printError(CLASS_NAME,$sformatf("ERROR : Number of byte can't be 0"));
			//	return;
			end
			

			// nack
			tWaitAckBit(1, error_set);

			if (!repeated_start) begin // if not repeated start condition
				tSendStopBit();
			end
			
			
			all_done = 1;
				
		end
		join_none begin

				
			begin
				@(posedge all_done, posedge i2c_master_io.reset);
				if (i2c_master_io.reset) begin	
				   // default variable states
					i2c_master_io.scl_out         		= 1;                          // SCL out
					i2c_master_io.scl_t         			= 0;                          // SCL tri-state
					i2c_master_io.sda_out          		= 1;                          // SDA out
					i2c_master_io.sda_t          			= 0;                          // SDA tri-state
				end
				
				disable rcv_msg;
			end	
		end
		
	endtask : tReceiveMessage
	
endclass : fidus_i2c_master_bfm
endpackage : fidus_i2c_master_bfm_pkg


////////////////////////////////////////////////////////////////////////////////////////////////////
// For the usage example check 2 test cases - tc_fidus_i2c_master and tc_fidus_axi4lite_i2c_master
