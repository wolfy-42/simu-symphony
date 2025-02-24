//--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
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

    // SIMU Management.
    import sim_management_pkg::*;

    // Variables, objects, parameters.
    sim_management s;
    axi_mst_agent #( .C_AXI_PROTOCOL       (0 ),
        .C_AXI_ADDR_WIDTH     (32),
        .C_AXI_WDATA_WIDTH    (32),
        .C_AXI_RDATA_WIDTH    (32),
        .C_AXI_WID_WIDTH      (0 ),
        .C_AXI_RID_WIDTH      (0 ),
        .C_AXI_AWUSER_WIDTH   (0 ),
        .C_AXI_WUSER_WIDTH    (0 ),
        .C_AXI_BUSER_WIDTH    (0 ),
        .C_AXI_ARUSER_WIDTH   (0 ),
        .C_AXI_RUSER_WIDTH    (0 ),
        .C_AXI_SUPPORTS_NARROW(1 ),
        .C_AXI_HAS_BURST      (1 ),
        .C_AXI_HAS_LOCK       (1 ),
        .C_AXI_HAS_CACHE      (1 ),
        .C_AXI_HAS_REGION     (1 ),
        .C_AXI_HAS_QOS        (1 ),
        .C_AXI_HAS_PROT       (1 )) agent;
    bit  [31:0]  addr;
    bit  [255:0] rdata;
    bit  [255:0] data;     // Data, 8 x 32 bit beats.
    reg  [7:0]   b_count;
    parameter TC_NAME = "tc_xilinx_axi_intf";

    // Transaction response.
    xil_axi_resp_t [255:0] t_resp;
    xil_axi_data_beat [255:0] ruser;




    // AXI Stimulus
    initial begin
        // Initialize the simulation
        s.initSim(TC_NAME);
        tb.axi_if.set_intf_master();

        // Instantiate master.
        agent = new("axi_vip_0_mst", tb.axi_if);
        agent.start_master();                      // agent start to run

        addr = 32'h44A00000;
        data = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;

        s.printMessage (TC_NAME, "Global Reset asserted");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5.5ns");
        tb.clk_bfm = new("clk_bfm", tb.clk_if, 5.0);
        tb.reset_bfm = new("rst_bfm", tb.reset_if);

        tb.reset_bfm.fAssertReset();
        #400;
        tb.reset_bfm.fDeassertReset();

        #200;


        agent.AXI4_WRITE_BURST(
                            .id(0),
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
                            .id(0),
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
            s.checkSig(TC_NAME, 2, $sformatf("Read Beat %0d", i), rdata[(i*32) +: 32], 32'h12345678+i);
        end

        #200;
        s.testComplete;
  end

endmodule

