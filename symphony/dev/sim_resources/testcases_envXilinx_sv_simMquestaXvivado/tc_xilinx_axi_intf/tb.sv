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
// Description   : Example test-bench file for Xilinx VIP simulation.
//               AXI MM master. Directly using VIP package instead of
//               going through IPI/IP Catalog
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Xilinx VIP
import axi_vip_pkg::*;
import fidus_clock_gen_bfm_pkg::*;
import fidus_reset_gen_bfm_pkg::*;

module tb ();

    // Test-bench signals.
    clk_bfm_if clk_if ();
    reset_bfm_if reset_if ();      // Reset signal

    axi_vip_if #(
        .C_AXI_PROTOCOL       (0 ),
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
        .C_AXI_HAS_PROT       (1 )
    ) axi_if (.ACLK(clk_if.c), .ACLKEN(1'b1), .ARESET_N(reset_if.rn));

    // RIPL Library instantiations
    sim_management_verilog sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    lib_math lib_math_inst ();           // Math libraries.

    // Test case instantiation
    test_case test_case_inst ();

    // Clock generator instantiation
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;

    // dut instatiation
    dut dut_isnt(
        .s_axi_aclk     (axi_if.ACLK),
        .s_axi_aresetn  (axi_if.ARESET_N),
        .s_axi_awaddr   (axi_if.AWADDR),
        .s_axi_awlen    (axi_if.AWLEN),
        .s_axi_awsize   (axi_if.AWSIZE),
        .s_axi_awburst  (axi_if.AWBURST),
        .s_axi_awlock   (axi_if.AWLOCK),
        .s_axi_awcache  (axi_if.AWCACHE),
        .s_axi_awprot   (axi_if.AWPROT),
        .s_axi_awregion (axi_if.AWREGION),
        .s_axi_awqos    (axi_if.AWQOS),
        .s_axi_awvalid  (axi_if.AWVALID),
        .s_axi_wdata    (axi_if.WDATA),
        .s_axi_wstrb    (axi_if.WSTRB),
        .s_axi_wlast    (axi_if.WLAST),
        .s_axi_wvalid   (axi_if.WVALID),
        .s_axi_bready   (axi_if.BREADY),
        .s_axi_araddr   (axi_if.ARADDR),
        .s_axi_arlen    (axi_if.ARLEN),
        .s_axi_arsize   (axi_if.ARSIZE),
        .s_axi_arburst  (axi_if.ARBURST),
        .s_axi_arlock   (axi_if.ARLOCK),
        .s_axi_arcache  (axi_if.ARCACHE),
        .s_axi_arprot   (axi_if.ARPROT),
        .s_axi_arregion (axi_if.ARREGION),
        .s_axi_arqos    (axi_if.ARQOS),
        .s_axi_arvalid  (axi_if.ARVALID),
        .s_axi_awready  (axi_if.AWREADY),
        .s_axi_wready   (axi_if.WREADY),
        .s_axi_arready  (axi_if.ARREADY),
        .s_axi_rready   (axi_if.RREADY),
        .s_axi_rlast    (axi_if.RLAST),
        .s_axi_rvalid   (axi_if.RVALID),
        .s_axi_rdata    (axi_if.RDATA),
        .s_axi_rresp    (axi_if.RRESP),
        .s_axi_bvalid   (axi_if.BVALID),
        .s_axi_bresp    (axi_if.BRESP)
    );

endmodule

