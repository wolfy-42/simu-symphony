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

// *************************** NOTE ***************************************
// Here, in the ifdef block we add the test to use the UVM agent to drive the
// interface to the i2cSlave RTL module and keep the legacy test in the else
// block, so both tests would run, one with use_uvm flag and one without it.
// Note that "THIS IS NOT A PROPER WAY TO RUN A UVM TEST!", this is just an
// example to make a UVM agent work in the SIMU environment to test a RTL
// module.
// *************************************************************************

`ifdef UVM_TESTBENCH

	$info ("calling from UVM TESTCASE");
	//import and include neede packages
        import uvm_pkg::*;
        import i2c_agent_pkg::*;
        `include "uvm_macros.svh"

	//test and agent parameters
        localparam DEMO_I2C_ADDR_WIDTH = 7;
        localparam DEMO_I2C_DATA_WIDTH = 8;
	localparam num_bytes = 4;

        //declare interface 
        i2c_if #(DEMO_I2C_ADDR_WIDTH) the_controller_if (.CLK(tb.clk_i2c_if.c),
                                                         .RESET_N(tb.reset_if.rn));
        //Declare UVM components, agents, sequences and variables
        i2c_command_addr_controller_seq                          my_command_addr_controller_seq;
        i2c_agent#(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH)      controller_agent;
	i2c_driver    #(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH) driver_agent;
        i2c_sequencer #(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH) sequencer_agent;
        i2c_config    #(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH) config_agent;
        logic [DEMO_I2C_DATA_WIDTH-1:0]                          random_data[num_bytes];

        initial begin
            // Initialize the simulation
            s.initSim(TC_NAME);
            //`uvm_info("UVM_TEST","running UVM test",UVM_LOW)
            s.printMessage (TC_NAME,"Running UVM simulation ");
            s.printMessage (TC_NAME,"Simulation is initialized");
            s.printMessage (TC_NAME, "Global Reset asserted");
            s.printMessage (TC_NAME, "Set clock 100MHz");
            
            s.printMessage (TC_NAME, "Set clock 100MHz");
            clk_100mhz_bfm = new("clk_100mhz", tb.clk_if, 10.00);
            s.printMessage (TC_NAME, "Set clock 100KHz for Normal Mode");
            clk_100khz_bfm = new("clk_100khz", tb.clk_i2c_if, 10000.00);		
            #200;
            reset_bfm = new("rst_bfm", tb.reset_if);
            
            reset_bfm.fAssertReset();
            #100;
            reset_bfm.fDeassertReset();
            
            error_cnt = 0;
            
            //creating UVM agents,sequences here
            controller_agent = new("controller_agent");
	    config_agent = new("config_agent");
            driver_agent = new("driver_agent");
            sequencer_agent  = new("sequencer_agent");
	    //controller_agent = i2c_agent#(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH)::type_id::create("controller_agent");
	    //config_agent = i2c_config#(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH)::type_id::create("config_agent", controller_agent);
	    //driver_agent = i2c_driver#(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH)::type_id::create("driver_agent", controller_agent);
	    //sequencer_agent = i2c_sequencer#(DEMO_I2C_ADDR_WIDTH,DEMO_I2C_DATA_WIDTH)::type_id::create("sequencer_agent", controller_agent);
            
	    controller_agent.m_driver = driver_agent;
	    controller_agent.m_sequencer = sequencer_agent;
	    controller_agent.m_config = config_agent;

            my_command_addr_controller_seq = new();
	    //my_command_addr_controller_seq.set_sequencer(sequencer_agent);

            //configuring agents, sequences here
	    controller_agent.m_config.m_context = i2c_agent_pkg::I2C_CONTROLLER;
            controller_agent.m_driver.vif = the_controller_if;
	    driver_agent.seq_item_port.connect(sequencer_agent.seq_item_export);

	    //this is the magic built-in UVM function used to make the ports between
	    //uvm driver and uvm sequencer connected properly.
            driver_agent.seq_item_port.resolve_bindings();

	    //for debug purpose only
            //`uvm_info("TC",$sformatf("driver port connected to %0d export",driver_agent.seq_item_port.size()),UVM_LOW)
            //`uvm_info("TC",$sformatf("sequencer port connected to %0d export",sequencer_agent.seq_item_export.size()),UVM_LOW)
	    //driver_agent.seq_item_port.debug_connected_to();
            //sequencer_agent.seq_item_export.debug_provided_to();
	    
	    //running the driver explicitly
            fork
		begin
                  `uvm_info("UVM TEST","Running driver controller",UVM_LOW)
                  driver_agent.run_controller();
	        end
            join_none

            //running sequences
            //should be randomized otherwise setting data wouldn't take effect
            void'(my_command_addr_controller_seq.randomize() with {size == 7;
                                                                   addr == 'h3c; // i2c device address is "`define I2C_ADDRESS 7'h3c"
                                                                   rwb  == 1'b0;
                                                                   nbr_data_bytes == num_bytes+1;});
            //my_command_addr_controller_seq.size = 7;
            //my_command_addr_controller_seq.addr = 'h3c; // i2c device address is "`define I2C_ADDRESS 7'h3c"
            //my_command_addr_controller_seq.rwb  = 1'b0;
            //my_command_addr_controller_seq.nbr_data_bytes = 2;
            my_command_addr_controller_seq.data[0] = 0; // the first one is "Addr"

	    //assigning random data to the sequence
	    s.printMessage (TC_NAME, "Writing the following data:");
	    foreach(random_data[i]) begin
	        random_data[i] = $urandom_range (255,0);
	        s.printMessage (TC_NAME, $sformatf(" 0x%0x",random_data[i]));
                my_command_addr_controller_seq.data[i+1] = random_data[i];
            end  

	    fork
		begin //running test sequences here
                 my_command_addr_controller_seq.start(controller_agent.m_sequencer);
		 s.printMessage (TC_NAME,"Write is done!");

                 // Write 1 bytes at i2cSlave module (e.g. Addr to read)
                 my_command_addr_controller_seq = new();
                 void'(my_command_addr_controller_seq.randomize() with {size == 7;
                                                                        addr == 'h3c; // i2c device address is "`define I2C_ADDRESS 7'h3c"
                                                                        rwb  == 1'b0;
                                                                        nbr_data_bytes == 1;});
                 my_command_addr_controller_seq.data[0] = 0; // "Addr"
                 `uvm_info("TC",$sformatf("Write address to read at i2cSlave module!"), UVM_LOW)
		 s.printMessage (TC_NAME, "Write address to read at i2cSlave module!");
	         my_command_addr_controller_seq.start(controller_agent.m_sequencer);

                 // Read bytes at i2cSlave module (e.g. x bytes from Addr to read++)
                 my_command_addr_controller_seq = new();
                 void'(my_command_addr_controller_seq.randomize() with {size == 7;
                                                                        addr == 'h3c; // i2c device address is "`define I2C_ADDRESS 7'h3c"
                                                                        rwb  == 1'b1;
                                                                        nbr_data_bytes == num_bytes;});
                 //`uvm_info("TC",$sformatf("Read bytes from i2cSlave module!"), UVM_LOW)
		 s.printMessage (TC_NAME, "Read bytes from i2cSlave module!");
		 my_command_addr_controller_seq.start(controller_agent.m_sequencer);
                 my_command_addr_controller_seq.print();
                 s.printMessage (TC_NAME,"Read is done!");

		 foreach(my_command_addr_controller_seq.data[i]) begin
                     if(my_command_addr_controller_seq.data[i] != random_data[i]) begin
                         `uvm_error("TC",$sformatf("Expected 0x%0x, Actual 0x%0x",random_data[i], my_command_addr_controller_seq.data[i]))
			 s.printError(TC_NAME,$sformatf("ERROR : Expected 0x%0x, Actual 0x%0x",random_data[i], my_command_addr_controller_seq.data[i]));
                         error_cnt++;
                     end
                     else begin
                         `uvm_info("TC",$sformatf("Expected 0x%0x, Actual 0x%0x", random_data[i], my_command_addr_controller_seq.data[i]), UVM_LOW)
			 s.printMessage (TC_NAME,$sformatf("Expected 0x%0x, Actual 0x%0x", random_data[i], my_command_addr_controller_seq.data[i]));
                     end
                 end


                 // manual data comparison
/*		 // first the address (data[0])
                 if(my_command_addr_controller_seq.data[0] != 'h0) begin
                     `uvm_error("TC",$sformatf("Expected 0x%0x, Actual 0x%0x",'h0, my_command_addr_controller_seq.data[0]))
		     s.printError(TC_NAME,$sformatf("ERROR : Expected 0x%0x, Actual 0x%0x",'h0, my_command_addr_controller_seq.data[0]));
                     error_cnt++;
                 end
                 else begin
                     `uvm_info("TC",$sformatf("Expected 0x%0x, Actual 0x%0x",'h0, my_command_addr_controller_seq.data[0]), UVM_LOW)
		     s.printMessage (TC_NAME,$sformatf("Expected 0x%0x, Actual 0x%0x",'h0, my_command_addr_controller_seq.data[0]));
                 end
		 
		 //compare data [1]
                 if(my_command_addr_controller_seq.data[0] != 'h57) begin
                     `uvm_error("TC",$sformatf("Expected 0x%0x, Actual 0x%0x",'h57, my_command_addr_controller_seq.data[0]))
		     s.printError(TC_NAME,$sformatf("ERROR : Expected 0x%0x, Actual 0x%0x",'h57, my_command_addr_controller_seq.data[0]));
                     error_cnt++;
                 end
                 else begin
                     `uvm_info("TC",$sformatf("Expected 0x%0x, Actual 0x%0x",'h57, my_command_addr_controller_seq.data[0]), UVM_LOW)
		     s.printMessage (TC_NAME,$sformatf("Expected 0x%0x, Actual 0x%0x",'h57, my_command_addr_controller_seq.data[0]));
                 end
		 //compare data [2]
                 if(my_command_addr_controller_seq.data[1] != 'hB9) begin
                     `uvm_error("TC",$sformatf("Expected 0x%0x, Actual 0x%0x",'hB9, my_command_addr_controller_seq.data[1]))
		     s.printError(TC_NAME,$sformatf("ERROR : Expected 0x%0x, Actual 0x%0x",'hB9, my_command_addr_controller_seq.data[1]));
                     error_cnt++;
                 end
                 else begin
                     `uvm_info("TC",$sformatf("Expected 0x%0x, Actual 0x%0x",'hB9, my_command_addr_controller_seq.data[1]), UVM_LOW)
		     s.printMessage (TC_NAME,$sformatf("Expected 0x%0x, Actual 0x%0x",'hB9, my_command_addr_controller_seq.data[1]));
                 end
*/
                 s.printMessage (TC_NAME,"comparison is done!");

                end
                begin  //timeout
		  #10000us;
                  s.printMessage (TC_NAME,"Timedout!");
		  error_cnt++;
	        end
	     join_any
                 
            // Simulation End
            if (error_cnt == 0) begin
            	s.printPass(TC_NAME,$sformatf("The simulation passed!"));
            end	
            #100;
            s.testComplete;
        end    

	// assign slave/master ports
	assign slave_sda = (the_controller_if.SDA_oe == 1'b0) ? 1'b0 : 1'bz;
	assign the_controller_if.SDA = slave_sda;
	pullup (slave_sda);
	
	assign slave_scl = (the_controller_if.SCL_oe == 1'b0) ? 1'b0 : 1'bz;
	assign the_controller_if.SCL = slave_scl;	
	pullup (slave_scl);

`else

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
`endif

endmodule 	  
