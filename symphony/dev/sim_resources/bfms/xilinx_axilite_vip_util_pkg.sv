//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename    : xilinx_axilite_vip_util_pkg.sv
// Project     : RIPL/SIMU
// Author      : Paul Roukema
// Created     : May 26, 2021
// Description : Utility functions for using Xilinx AXI VIP in AXI-Lite mode
//
// Interface declaration
// axi_vip_if #(
//     .C_AXI_PROTOCOL       (2 ),
//     .C_AXI_ADDR_WIDTH     (32),
//     .C_AXI_WDATA_WIDTH    (32),
//     .C_AXI_RDATA_WIDTH    (32),
//     .C_AXI_WID_WIDTH      (0 ),
//     .C_AXI_RID_WIDTH      (0 ),
//     .C_AXI_AWUSER_WIDTH   (0 ),
//     .C_AXI_WUSER_WIDTH    (0 ),
//     .C_AXI_BUSER_WIDTH    (0 ),
//     .C_AXI_ARUSER_WIDTH   (0 ),
//     .C_AXI_RUSER_WIDTH    (0 ),
//     .C_AXI_SUPPORTS_NARROW(0 ),
//     .C_AXI_HAS_BURST      (0 ),
//     .C_AXI_HAS_LOCK       (0 ),
//     .C_AXI_HAS_CACHE      (0 ),
//     .C_AXI_HAS_REGION     (0 ),
//     .C_AXI_HAS_QOS        (0 ),
//     .C_AXI_HAS_PROT       (1 )
// ) axi_if (.ACLK(ACLK), .ACLKEN(1'b1), .ARESET_N(ARESETN));
//
//---------------------------------------------------------------------------//

package xilinx_axilite_vip_util_pkg;
    import sim_management_pkg::*;
    import axi_vip_pkg::*;

    typedef     axi_mst_agent #(
        .C_AXI_PROTOCOL(2),
        .C_AXI_ADDR_WIDTH(32),
        .C_AXI_WDATA_WIDTH(32),
        .C_AXI_RDATA_WIDTH(32),
        .C_AXI_WID_WIDTH(0),
        .C_AXI_RID_WIDTH(0),
        .C_AXI_AWUSER_WIDTH(0),
        .C_AXI_WUSER_WIDTH(0),
        .C_AXI_BUSER_WIDTH(0),
        .C_AXI_ARUSER_WIDTH(0),
        .C_AXI_RUSER_WIDTH(0),
        .C_AXI_SUPPORTS_NARROW(0),
        .C_AXI_HAS_BURST(0),
        .C_AXI_HAS_LOCK(0),
        .C_AXI_HAS_CACHE(0),
        .C_AXI_HAS_REGION(0),
        .C_AXI_HAS_QOS(0),
        .C_AXI_HAS_PROT(1)
    ) axilite_mst_agent;

    task axilite_write(axilite_mst_agent mst,  bit [31:0] addr, bit [31:0] wdata);
        xil_axi_resp_t bresp;

        mst.AXI4LITE_WRITE_BURST(addr, 3'h0, wdata, bresp );
        sim_management::checkSig(mst.get_name(), 2, $sformatf("AXILITE Write @ 0x%04x bresp", addr), bresp, XIL_AXI_RESP_OKAY, QUIET);
    endtask

    task axilite_read(axilite_mst_agent mst, bit [31:0] addr, output bit [31:0] rdata);
        xil_axi_resp_t rresp;

        mst.AXI4LITE_READ_BURST(addr, 3'h0, rdata, rresp );
        sim_management::checkSig(mst.get_name(), 2, $sformatf("AXILITE Read @ 0x%04x rresp", addr), rresp, XIL_AXI_RESP_OKAY, QUIET);
    endtask

    task axilite_read_check(axilite_mst_agent mst, bit [31:0] addr, bit [31:0] expected, bit [31:0] mask = '1);
        bit [63:0] rdata;

        axilite_read(mst, addr, rdata);
        sim_management::checkSig(mst.get_name(), 2, $sformatf("AXILITE Read @ 0x%04x rdata", addr), rdata[31:0] & mask, expected & mask);
    endtask

    task axilite_write_read_check(axilite_mst_agent mst,  bit [31:0] addr, bit [31:0] wdata, bit [31:0] mask = '1);

        axilite_write(mst, addr, wdata);
        axilite_read_check(mst, addr, wdata, mask);
    endtask

endpackage
