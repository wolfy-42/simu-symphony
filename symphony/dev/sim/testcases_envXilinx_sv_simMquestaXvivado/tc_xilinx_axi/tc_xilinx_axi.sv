//--------------------------------------------------------------------//
//
// Copyright (C) 2017 Fidus Systems Inc.
//
// Project       : simu
// Author        : Victor Dumitriu
// Created       : 2018-08-10
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Example test-case file for Xilinx VIP simulation.
//               AXI MM master.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

module test_case();

    // Xilinx VIP
    import axi_vip_pkg::*;
    import axi_master_pkg::*;

    // SIMU Management.
    import sim_management_pkg::*;

    // Variables, objects, parameters.
    sim_management s;
    axi_master_mst_t agent;
    bit  [31:0]  addr;
    bit  [255:0] rdata;
    bit  [255:0] data;     // Data, 8 x 32 bit beats.
    reg  [7:0]   b_count;
    parameter TC_NAME = "tc_xilinx_axi";

    // Transaction response.
    xil_axi_resp_t [255:0] t_resp;
    xil_axi_data_beat [255:0] ruser;


    // Ready signal gen.
    always @(posedge tb.clk_if.c)
    begin
        if (~tb.reset_if.rn) begin
            tb.m_axi_awready <= 1'b0;
            tb.m_axi_wready <= 1'b0;
            tb.m_axi_arready <= 1'b0;
        end
        else begin
            tb.m_axi_awready <= 1'b1;
            tb.m_axi_wready <= 1'b1;
            tb.m_axi_arready <= 1'b1;
        end;
    end

    // Rvalid signal generation.
    always @(posedge tb.clk_if.c)
    begin
        if (~tb.reset_if.rn) begin
            tb.m_axi_rvalid <= 1'b0;
            tb.m_axi_rlast <= 1'b0;
            b_count <= 3'b000;
        end
        else begin
            if (tb.m_axi_arvalid && ~tb.m_axi_rvalid) begin
                tb.m_axi_rvalid <= 1'b1;
                tb.m_axi_rlast <= 1'b0;
                b_count <= 3'b000;
            end
            else if (tb.m_axi_rready && tb.m_axi_rvalid && b_count < 3'h6) begin
                tb.m_axi_rvalid <= 1'b1;
                tb.m_axi_rlast <= 1'b0;
                b_count <= b_count + 1'b1;
            end
            else if (tb.m_axi_rready && tb.m_axi_rvalid && b_count == 3'h6) begin
                tb.m_axi_rvalid <= 1'b1;
                tb.m_axi_rlast <= 1'b1;
                b_count <= b_count + 1'b1;
            end
            else if (tb.m_axi_rready && tb.m_axi_rvalid && tb.m_axi_rlast) begin
                tb.m_axi_rvalid <= 1'b0;
                tb.m_axi_rlast <= 1'b0;
                b_count <= 3'b000;
            end
        end
    end

    // Bvalid signal generation.
    always @(posedge tb.clk_if.c)
    begin
        if (~tb.reset_if.rn) begin
            tb.m_axi_bvalid <= 1'b0;
        end
        else begin
            if (tb.m_axi_wvalid && ~tb.m_axi_bvalid && tb.m_axi_wlast) begin
                tb.m_axi_bvalid <= 1'b1;
            end
            else if (tb.m_axi_bready && tb.m_axi_bvalid) begin
                tb.m_axi_bvalid <= 1'b0;
            end
            else begin
                tb.m_axi_bvalid <= tb.m_axi_bvalid;
            end
        end
    end


    // AXI Stimulus
    initial begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        // Instantiate master.
        agent = new("axi_vip_0_mst", tb.axi_master_inst.inst.IF);
        agent.start_master();                      // agent start to run

        addr = 32'h44A00000;
        data = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
        tb.m_axi_rdata = 32'h12345678;

        s.printMessage (TC_NAME, "Global Reset asserted");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5.5ns");
        tb.clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        tb.reset_bfm = new("rst_bfm", tb.reset_if);

        tb.reset_bfm.fAssertReset();
        #400;
        tb.reset_bfm.fDeassertReset();

        #200;


        agent.AXI4_WRITE_BURST(
                            .id(1),
                            .addr(addr),
                            .len(8),
                            .size(XIL_AXI_SIZE_4BYTE),
                            .burst(XIL_AXI_BURST_TYPE_INCR),
                            .lock(XIL_AXI_ALOCK_NOLOCK),
                            .cache(0),
                            .prot(0),
                            .region(0),
                            .qos(0),
                            .awuser(0),
                            .data(data),
                            .wuser(0),
                            .resp(t_resp));


        agent.wr_driver.wait_driver_idle();

        agent.AXI4_READ_BURST(
                            .id(1),
                            .addr(addr),
                            .len(7),
                            .size(XIL_AXI_SIZE_4BYTE),
                            .burst(XIL_AXI_BURST_TYPE_INCR),
                            .lock(XIL_AXI_ALOCK_NOLOCK),
                            .cache(0),
                            .prot(0),
                            .region(0),
                            .qos(0),
                            .aruser(0),
                            .data(rdata),
                            .resp(t_resp),
                            .ruser(ruser));

        agent.rd_driver.wait_driver_idle();


        agent.wait_drivers_idle();              // Wait driver is idle then stop the simulation

        // Display read data.
        s.printMessage (TC_NAME, "Data read:");
        for (int i = 0; i < 8; i++) begin
            s.checkSig(TC_NAME, 2, $sformatf("Read Beat %0d", i), rdata[(i*32) +: 32], 32'h12345678);
        end

        #200;
        s.testComplete;
  end

endmodule

