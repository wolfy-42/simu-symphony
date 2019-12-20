//--------------------------------------------------------------------//
//
// Copyright (C) 2018 Fidus Systems Inc.
//
// Project       : simu
// Author        : Victor Dumitriu
// Created       : 2018-08-10
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Example test-case file for Xilinx VIP simulation.
//               AXI stream master.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

module test_case();

    // Xilinx VIP
    import axi4stream_vip_pkg::*;
    import axistream_master_pkg::*;

    // SIMU Management.
    import sim_management_pkg::*;

    // Variables, objects, parameters.
    sim_management s;
    axistream_master_mst_t agent;
    parameter TC_NAME = "tc_xilinx_axis";

    xil_axi4stream_data_byte data[3:0];     // Data.
    reg [31:0] last_data;

    // TReady signal generation.
    always @(posedge tb.clk_if.c)
    begin
        if (~tb.reset_if.rn) begin
            tb.m_axis_tready <= 1'b0;
        end
        else begin
            tb.m_axis_tready <= 1'b1;
        end;
    end
    always @(posedge tb.clk_if.c)
    begin 
	if(tb.m_axis_tvalid && tb.m_axis_tready && tb.m_axis_tlast)
	begin 
	    last_data = tb.m_axis_tdata;
	end
    end

    // AXI Stimulus
    initial begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        // Instantiate master.
        agent = new("axilite_vip_0_mst", tb.axistream_master_inst.inst.IF);
        agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        agent.set_verbosity(400);
        agent.start_master();                      // agent start to run

        data[0] = 8'h01;
        data[1] = 8'h23;
        data[2] = 8'h45;
        data[3] = 8'h67;

        s.printMessage (TC_NAME, "Global Reset asserted");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5.5ns");
        tb.clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        tb.reset_bfm = new("rst_bfm", tb.reset_if);

        tb.reset_bfm.fAssertReset();
        #400;
        tb.reset_bfm.fDeassertReset();

        #200;

        for (int i = 0; i < 8; i++) begin
            if (i == 0) begin
                mst_gen_transaction(.last(0), .user(1), .data(data));
            end
            else if (i == 7) begin
		data[0] = 8'hFF;
                mst_gen_transaction(.last(1), .user(0), .data(data));
            end
            else begin
                mst_gen_transaction(.last(0), .user(0), .data(data));
            end
        end
	
	s.checkSig(TC_NAME, 2, "Last Data", last_data, 32'hFF234567);
        #200;
        s.testComplete;
    end

    task mst_gen_transaction( input bit last,
                            input bit user,
                            input xil_axi4stream_data_byte data [3:0]);
        // Transaction handle.
        axi4stream_transaction wr_transaction;
        string wr_transaction_str;

        // Create transaction.
        wr_transaction = agent.driver.create_transaction("Master VIP write transaction");
        wr_transaction.set_verbosity(400);

        // Configure transaction.
        //wr_transaction.set_data_width(32);
        //wr_transaction.set_user_width(1);
        //wr_transaction.resize_payload_arrays();
        wr_transaction.set_user_beat(user);
        wr_transaction.set_last(last);
        wr_transaction.set_data(data);

        //wr_transaction.randomize();

        wr_transaction_str = wr_transaction.convert2string();

        $display(wr_transaction_str);


        // Will avoid using the more advanced features in this instance....
        //WR_TRANSACTION_FAIL: assert(wr_transaction.randomize());

        // Send transaction.
        agent.driver.send(wr_transaction);

        while (~agent.driver.is_driver_idle()) begin
            #10;
        end

  endtask

endmodule

