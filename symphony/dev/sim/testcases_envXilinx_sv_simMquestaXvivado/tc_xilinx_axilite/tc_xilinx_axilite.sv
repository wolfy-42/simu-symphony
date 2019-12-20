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
//               AXI-lite master.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

module test_case();

    // Xilinx VIP
    import axi_vip_pkg::*;
    import axilite_master_pkg::*;

    // SIMU Management.
    import sim_management_pkg::*;

    // Variables, objects, parameters.
    sim_management s;
    axilite_master_mst_t agent;
    xil_axi_resp_t t_resp;
    bit [31:0] addr;
    bit [31:0] rdata;
    parameter TC_NAME = "tc_xilinx_axilite";

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
        end
        else begin
            if (tb.m_axi_arvalid && ~tb.m_axi_rvalid) begin
                tb.m_axi_rvalid <= 1'b1;
            end
            else if (tb.m_axi_rready && tb.m_axi_rvalid) begin
                tb.m_axi_rvalid <= 1'b0;
            end
            else begin
                tb.m_axi_rvalid <= tb.m_axi_rvalid;
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
            if (tb.m_axi_wvalid && ~tb.m_axi_bvalid) begin
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
        agent = new("axilite_vip_0_mst", tb.axilite_master_inst.inst.IF);
        agent.start_master();                      // agent start to run

        addr = 32'h44A00000;

        s.printMessage (TC_NAME, "Global Reset asserted");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5.5ns");
        tb.clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        tb.reset_bfm = new("rst_bfm", tb.reset_if);

        tb.reset_bfm.fAssertReset();
        #400;
        tb.reset_bfm.fDeassertReset();

        #200;

        agent.AXI4LITE_WRITE_BURST(addr, 0, 32'h4b, t_resp);
        agent.wr_driver.wait_driver_idle();

        agent.AXI4LITE_WRITE_BURST(addr, 0, 32'h36, t_resp);
        agent.wr_driver.wait_driver_idle();

        agent.AXI4LITE_WRITE_BURST(addr, 0, 32'h98, t_resp);
        agent.wr_driver.wait_driver_idle();

        agent.AXI4LITE_READ_BURST(addr, 0, rdata, t_resp);
        agent.rd_driver.wait_driver_idle();

	s.checkSig(TC_NAME, 2, "Read Data", rdata, 32'h01234567);

        agent.wait_drivers_idle();              // Wait driver is idle then stop the simulation

        #200;
        s.testComplete;
    end

endmodule

