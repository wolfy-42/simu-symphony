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
// Description   : Test-case for I2C Master BFM. 
// 					 It uses Xilinx IIC AXI IP and has no separate registers, just Slave address
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Module declaration
module test_case();

	// System Verilog Simulation management package
	import sim_management_pkg::*;
	import fidus_clock_gen_bfm_pkg::*;
	import fidus_reset_gen_bfm_pkg::*;
	import fidus_axi4lite_mst_bfm_pkg::*;
	import fidus_i2c_master_bfm_pkg::*;
	
	// Variables and parameters ;
	sim_management s;
	parameter TC_NAME = "tc_fidus_i2c_master_bfm";
	
	// i2c device address
	`define I2C_ADDRESS 7'h3c	
		
	logic [7:0] 	total_data_write [];
	logic [7:0] 	total_data_read [];
		
	// signals	
	// Slave signals (driven in test-case).
   logic            	m_axi_lite_awready;
   logic            	m_axi_lite_wready;
   logic    [1:0]   	m_axi_lite_bresp;
   logic            	m_axi_lite_bvalid;
   logic            	s_axi_lite_arready;
   logic    [31:0]  	s_axi_lite_rdata;
   logic            	s_axi_lite_rvalid;
   logic    [1:0]   	s_axi_lite_rresp;

   // Master signals (driven by AXI Lite Master BFM in test-case).
   logic   [8:0]   	m_axi_lite_awaddr;
   logic           	m_axi_lite_awvalid;
   logic   [31:0]  	m_axi_lite_wdata;
   logic   [1:0]   	m_axi_lite_wstrb;
   logic           	m_axi_lite_wvalid;
   logic           	m_axi_lite_bready;
   logic   [8:0]   	s_axi_lite_araddr;
   logic           	s_axi_lite_arvalid;
   logic           	s_axi_lite_rready;
	 
   logic           	slave_sda_i;
   logic           	slave_sda_o;
   logic           	slave_sda_t; 
   logic           	slave_scl_i; 
   logic           	slave_scl_o;
   logic           	slave_scl_t;
	wire 					slave_sda_io;
	wire 					slave_scl_io;

	logic [7:0]			register_addr;
	logic [8:0]			iic_addr = `I2C_ADDRESS;
	logic	[3:0]			error_cnt;
	logic 				error_sent;
	logic					error_rcved;
	logic 				error_axi_iic_slave_rcvd;
	logic 				repeated_start;
	logic [31:0]      axi_iic_slave_resp;
	
	// Global signals.
   assign axi_bfm_channel.aclk = tb.clk_if.c;
   assign axi_bfm_channel.aresetn = tb.reset_if.rn;
	 
	 // Master driven signals.
    assign m_axi_lite_awaddr = axi_bfm_channel.awaddr;
    assign m_axi_lite_awvalid = axi_bfm_channel.awvalid;
    assign m_axi_lite_wdata = axi_bfm_channel.wdata;
    assign m_axi_lite_wstrb = axi_bfm_channel.wstrb;
    assign m_axi_lite_wvalid = axi_bfm_channel.wvalid;
    assign m_axi_lite_bready = axi_bfm_channel.bready;
    assign s_axi_lite_araddr = axi_bfm_channel.araddr;
    assign s_axi_lite_arvalid = axi_bfm_channel.arvalid;
    assign s_axi_lite_rready = axi_bfm_channel.rready;

    // Slave driven signals.
    assign axi_bfm_channel.awready = m_axi_lite_awready;
    assign axi_bfm_channel.wready = m_axi_lite_wready;
    assign axi_bfm_channel.bresp = m_axi_lite_bresp;
    assign axi_bfm_channel.bvalid = m_axi_lite_bvalid;
    assign axi_bfm_channel.arready = s_axi_lite_arready;
    assign axi_bfm_channel.rdata = s_axi_lite_rdata;
    assign axi_bfm_channel.rvalid = s_axi_lite_rvalid;
    assign axi_bfm_channel.rresp = s_axi_lite_rresp;
	 
	int i, j;
	
	// BFM local instances becuse Active-HDL can't refere to the TB level (it's a tool bug)
	fidus_clock_gen_bfm clk_100mhz_bfm;
	fidus_clock_gen_bfm clk_100khz_bfm;
	fidus_reset_gen_bfm reset_bfm;  
	fidus_i2c_master_bfm i2c_master_bfm;
   fidus_axi4lite_mst_bfm #(.AWIDTH(9), .DWIDTH(32), .OUTPUT_DRV_EDGE("rise"), .OUTPUT_DRV_DLY(0)) axi4lite;
	 
	// I2C master interface
	fidus_i2c_master_if i2c_master_if
	(
		.clk		(tb.clk_i2c_if.c),
		.reset	(tb.reset_if.r)
	);
	
	// AXI Lite interface, used by BFM and test-case to communicate.
    axi4lite_intf #(
        .AWIDTH(9), 
        .DWIDTH(32)
    ) 
    axi_bfm_channel ();
	 
	// AXI i2c slave 
	axi_iic_addr_7bit  axi_iic_addr_7bit
	(
		.iic2intc_irpt    (),       
		.s_axi_aclk       (tb.clk_if.c),
		.s_axi_aresetn    (tb.reset_if.rn),
		.s_axi_awaddr     (m_axi_lite_awaddr),
		.s_axi_awvalid    (m_axi_lite_awvalid),
		.s_axi_awready    (m_axi_lite_awready),
		.s_axi_wdata      (m_axi_lite_wdata),
		.s_axi_wstrb      (4'b1111),
		.s_axi_wvalid     (m_axi_lite_wvalid),
		.s_axi_wready     (m_axi_lite_wready),
		.s_axi_bresp      (m_axi_lite_bresp),
		.s_axi_bvalid     (m_axi_lite_bvalid),
		.s_axi_bready     (m_axi_lite_bready),
		.s_axi_araddr     (s_axi_lite_araddr),
		.s_axi_arvalid    (s_axi_lite_arvalid),
		.s_axi_arready    (s_axi_lite_arready),
		.s_axi_rdata      (s_axi_lite_rdata),
		.s_axi_rresp      (s_axi_lite_rresp),
		.s_axi_rvalid     (s_axi_lite_rvalid),
		.s_axi_rready     (s_axi_lite_rready),
		.sda_i            (slave_sda_i), 
		.sda_o            (slave_sda_o),
		.sda_t            (slave_sda_t),
		.scl_i            (slave_scl_i),
		.scl_o            (slave_scl_o),
		.scl_t            (slave_scl_t),
		.gpo              ()
   );
	
	// assign slave/master ports
	assign slave_sda_io = (slave_sda_t == 0) ? slave_sda_o : 1'bz;
	assign slave_sda_i = slave_sda_io;

	assign slave_scl_io = (slave_scl_t == 0) ? slave_scl_o : 1'bz;
	assign slave_scl_i = slave_scl_io;	

	assign slave_sda_io = (i2c_master_if.sda_t == 1'b0) ? i2c_master_if.sda_out : 1'bz;
	assign i2c_master_if.sda_in = slave_sda_io;
	pullup(slave_sda_io);
	
	assign slave_scl_io = (i2c_master_if.scl_t == 1'b0) ? i2c_master_if.scl_out : 1'bz;
	assign i2c_master_if.scl_in = slave_scl_io;	
	pullup(slave_scl_io);	

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
		clk_100mhz_bfm = new("clk_100mhz", tb.clk_if, 10.00);
		s.printMessage (TC_NAME, "Set clock 100KHz for Normal Mode");
		clk_100khz_bfm = new("clk_100khz", tb.clk_i2c_if, 10000.00);
		reset_bfm = new("rst_bfm", tb.reset_if);
		// BFM class constructions
		i2c_master_bfm = new("fidus_i2c_master_bfm", i2c_master_if, 1);
      axi4lite = new("fidus_axi4lite_mst_bfm", axi_bfm_channel);		

      reset_bfm.fAssertReset();
      #100;
      reset_bfm.fDeassertReset();
		error_cnt = 0;
		error_rcved = 0;
		error_sent = 0;
		error_axi_iic_slave_rcvd = 0;
		end_wr = 0;
		repeated_start = 0;

      #20;

      // Initialize AXI BFM setings.
		axi4lite.fSetTransactionMessagingOnOff(1);             // Enable transaction messaging.
		axi4lite.fSetDebugMessagingOnOff(0);                   // Disable debug messaging.
		axi4lite.fSetWrErrorChkOnOff(0);                       // Disable write response checking (not recommended).
		axi4lite.fSetRdErrorChkOnOff(0);                       // Disable read response checking (not recommended).
		axi4lite.fSetWrRespReadyLatency(0);                    // Set Write Response Ready latency to 0 c.c.
		axi4lite.fSetRdRespReadyLatency(0);                    // Set Read Response Ready latency to 0 c.c.
		axi4lite.fSetTransactionTimeoutValues(-1, -1);         // Set read and write timeout values. Negative values mean no time-outs.
		  
		// set up i2c slave
		axi4lite.tWriteAXI4Lite(9'h100, 16'h01);	// enable the core	
		axi4lite.tWriteAXI4Lite(9'h110, {iic_addr[6:0],1'b0});	// slave address	
		axi4lite.tWriteAXI4Lite(9'h120, 16'h01);	// RX_FIFO_PIRQ	
		  
		#1000;
		// send/read message 1 byte
		total_data_write = new[1];
		total_data_read = new[1];
		register_addr = 9'h10C;
		total_data_write[0] = 8'hAA;		
		s.printMessage (TC_NAME, "Note: Start testing 1 byte write %h and read.", total_data_write[0]);		
		i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 1, register_addr, 1, total_data_write, repeated_start, error_sent);
		#500;
		axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.
		if (!axi_iic_slave_resp[6]) begin
			s.printMessage (TC_NAME, "Note: The Slave recognized the address, AAS is 1. THe FIFO is not empty %h", axi_iic_slave_resp);	
		end else begin
			error_axi_iic_slave_rcvd = 1;
			s.printError(TC_NAME,$sformatf("ERROR : The RX_FIFO is empty %h", axi_iic_slave_resp));
		end
		
		axi4lite.tReadAXI4Lite(9'h20, axi_iic_slave_resp);      // Interrupt Write transaction: address, data, strobe.
		#500;
		axi4lite.tReadAXI4Lite(9'h10C, axi_iic_slave_resp);      // RX_FIFO Write transaction: address, data, strobe.
		axi4lite.tWriteAXI4Lite(9'h108, axi_iic_slave_resp); // TX FIFO
		axi4lite.tWriteAXI4Lite(9'h20, 8'h08);
		axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.

		
		i2c_master_bfm.tReceiveMessage(`I2C_ADDRESS, 1, register_addr, 1, total_data_read, repeated_start, error_rcved);		
		
		axi4lite.tReadAXI4Lite(9'h20, axi_iic_slave_resp);	// Interrupt	
		axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.

		if (error_sent || error_rcved || (total_data_read[0] !== total_data_write[0]) || error_axi_iic_slave_rcvd) begin
			if (error_sent) begin
				s.printError(TC_NAME,$sformatf("ERROR : Something happened during message send process"));
			end
			
			if (error_rcved) begin
				s.printError(TC_NAME,$sformatf("ERROR : Something happened during message received process"));
			end
			
			s.printError(TC_NAME,$sformatf("ERROR : The read data  %h is not what is expected. Should be %h", total_data_read[0], total_data_write[0]));
			error_cnt++;
		end else begin
			s.printMessage (TC_NAME, "Note: The 1 byte read was sucessfull. The data %h was recieved same as expected %h.", total_data_read[0], total_data_write[0]);
		end 
		
		s.printMessage (TC_NAME, "Note: Start testing clock stretching.");	
		total_data_write[0] = 8'h55;		
		s.printMessage (TC_NAME, "Note: Start testing 1 byte write %h and read.", total_data_write[0]);		
		
		fork 		
			begin
				i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 1, register_addr, 1, total_data_write, repeated_start, error_sent);
				i2c_master_bfm.tReceiveMessage(`I2C_ADDRESS, 1, register_addr, 1, total_data_read, repeated_start, error_rcved);				
			end
				
			begin	
				while (axi_iic_slave_resp[6]) begin // wait till RX_FIFO is not empty
					axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.
					#500;
				end
				
				@(negedge i2c_master_if.sda_t); // wait till first ack

				s.printMessage (TC_NAME, "Note: i2c_master_if.sda_t %h ", i2c_master_if.sda_t);
				
				#400000;
				axi4lite.tReadAXI4Lite(9'h10C, axi_iic_slave_resp);      // RX_FIFO Write transaction: address, data, strobe.
				axi4lite.tWriteAXI4Lite(9'h108, axi_iic_slave_resp); 		// TX FIFO
				#500;
				axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.
			end
		join begin

			if (error_sent || error_rcved || (total_data_read[0] !== total_data_write[0]) || error_axi_iic_slave_rcvd) begin
				if (error_sent) begin
					s.printError(TC_NAME,$sformatf("ERROR : Something happened during message send process"));
				end
				
				if (error_rcved) begin
					s.printError(TC_NAME,$sformatf("ERROR : Something happened during message received process"));
				end
				
				s.printError(TC_NAME,$sformatf("ERROR : The read data  %h is not what is expected. Should be %h", total_data_read[0], total_data_write[0]));
				error_cnt++;
			end else begin
				s.printMessage (TC_NAME, "Note: The 1 byte read was sucessfull. The data %h was recieved same as expected %h.", total_data_read[0], total_data_write[0]);
			end 
		
		end
					
		// send/read message 4 byte
		// set up i2c slave
		axi4lite.tWriteAXI4Lite(9'h100, 16'h02);	// reset the TX_FIFO
		axi4lite.tWriteAXI4Lite(9'h100, 16'h01);	// enable the core	
		axi4lite.tWriteAXI4Lite(9'h120, 16'h04);	// RX_FIFO_PIRQ	
		axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.
		
		total_data_write = new[4];
		total_data_read = new[4];
		register_addr = 0;
		total_data_write[0] = 8'h01;
		total_data_write[1] = 8'h23;
		total_data_write[2] = 8'h45;
		total_data_write[3] = 8'h67;
		s.printMessage (TC_NAME, "Note: Start testing 4 bytes write of data %h%h%h%h and read.", total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0]);				
		i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 4, register_addr, 1, total_data_write, repeated_start, error_sent);
		
		#500;
		axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.
		axi4lite.tWriteAXI4Lite(9'h20, 8'h08);
		
		// read data from RX_FIFO and transfer into TX_FIFO
		for (i=0; i<4; i++) begin 
			axi4lite.tReadAXI4Lite(9'h10C, axi_iic_slave_resp);      // RX_FIFO Write transaction: address, data, strobe.
			axi4lite.tWriteAXI4Lite(9'h108, axi_iic_slave_resp); // TX FIFO
		end
		
		i2c_master_bfm.tReceiveMessage(`I2C_ADDRESS, 4, register_addr, 1, total_data_read, repeated_start, error_rcved);
		#500;
		
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
			s.printMessage (TC_NAME, "Note: The read was sucessfull. The expected data is  %h, %h, %h, and %h. The data %h, %h, %h, and %h was recieved.", total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0], total_data_read[3], total_data_read[2], total_data_read[1], total_data_read[0]);
		end
		
		axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.
		axi4lite.tWriteAXI4Lite(9'h20, 8'h08);
		
		// Repeat start test
		repeated_start = 1;
		axi4lite.tWriteAXI4Lite(9'h100, 16'h02);	// reset the TX_FIFO
		axi4lite.tWriteAXI4Lite(9'h100, 16'h01);	// enable the core
		
		s.printMessage (TC_NAME, "Note: Start testing repeated start 4 bytes write of data %h%h%h%h and read.", total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0]);				

		for (i=0; i<4; i++) begin
			total_data_write[0] = 8'h01 + i;
			total_data_write[1] = 8'h23 + i;
			total_data_write[2] = 8'h45 + i;
			total_data_write[3] = 8'h67 + i;
			i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 4, register_addr, 1, total_data_write, repeated_start, error_sent);
			#500;
			axi4lite.tReadAXI4Lite(9'h104, axi_iic_slave_resp);      // Status Write transaction: address, data, strobe.
			
			// read data from RX_FIFO and transfer into TX_FIFO
			for (j=0; j<4; j++) begin 
				axi4lite.tReadAXI4Lite(9'h10C, axi_iic_slave_resp);      // RX_FIFO Write transaction: address, data, strobe.
				axi4lite.tWriteAXI4Lite(9'h108, axi_iic_slave_resp); // TX FIFO
			end
				
			#100;
			end_wr = 1;
		
			i2c_master_bfm.tReceiveMessage(`I2C_ADDRESS, 4, register_addr, 1, total_data_read, repeated_start, error_rcved);
	
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
				s.printMessage (TC_NAME, "Note: The read was sucessfull. The expected data is  %h, %h, %h, and %h. The data %h, %h, %h, and %h was recieved.", total_data_write[3], total_data_write[2], total_data_write[1], total_data_write[0], total_data_read[3], total_data_read[2], total_data_read[1], total_data_read[0]);
			end
		end	

		s.printMessage (TC_NAME, "Note: Start testing reset.");	
		fork 		
			begin
				i2c_master_bfm.tSendMessage(`I2C_ADDRESS, 1, register_addr, 1, total_data_write, repeated_start, error_sent);
			end	
		
			begin
				#500;
				@(negedge i2c_master_if.scl_out); // wait till falling edge of the SCL
				reset_bfm.fAssertReset();
				#500;
				reset_bfm.fDeassertReset();
			end
		join begin
			@(negedge i2c_master_if.reset);
			if (i2c_master_if.scl_out && !i2c_master_if.scl_t && i2c_master_if.sda_out && !i2c_master_if.sda_t) begin
				s.printMessage (TC_NAME, "Note: The reset was sucessfull.");
			end else begin
				s.printError(TC_NAME,$sformatf("ERROR : Reset didn't work"));
				error_cnt++;
			end
		end
		
		// Simulation End
		if (error_cnt == 0) begin
			s.printPass(TC_NAME,$sformatf("The simulation passed!"));
		end	
      #500;
      s.testComplete;
	end	
	

endmodule 	  