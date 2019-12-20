//--------------------------------------------------------------------//
//
// Copyright (C) 2017 Fidus Systems Inc.
//
// Project       : simu
// Author        : Victor Dumitriu
// Created       : 2018-08-10
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : Example test-bench file for Xilinx VIP simulation.
//               AXI MM master.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Xilinx VIP
import axi_vip_pkg::*;
import axi_master_pkg::*;
import fidus_clock_gen_bfm_pkg::*;
import fidus_reset_gen_bfm_pkg::*;

module tb();

    // Test-bench signals.
    clk_bfm_if clk_if();
    reset_bfm_if reset_if();      // Reset signal
    
    wire [31:0] m_axi_awaddr;
    wire [7:0]  m_axi_awlen;
    wire [2:0]  m_axi_awsize;
    wire [1:0]  m_axi_awburst;
    wire        m_axi_awlock;
    wire [3:0]  m_axi_awcache;
    wire [2:0]  m_axi_awprot;
    wire [3:0]  m_axi_awregion;
    wire [3:0]  m_axi_awqos;
    wire        m_axi_awvalid;
    
    wire [31:0] m_axi_wdata;
    wire [3:0]  m_axi_wstrb;
    wire        m_axi_wlast;
    wire        m_axi_wvalid;
    
    wire        m_axi_bready;
    
    wire [31:0] m_axi_araddr;
    wire [7:0]  m_axi_arlen;
    wire [2:0]  m_axi_arsize;
    wire [1:0]  m_axi_arburst;
    wire        m_axi_arlock;
    wire [3:0]  m_axi_arcache;
    wire [2:0]  m_axi_arprot;
    wire [3:0]  m_axi_arregion;
    wire [3:0]  m_axi_arqos;
    wire        m_axi_arvalid;
    
    reg         m_axi_awready;
    reg         m_axi_wready;
    reg         m_axi_arready;
    
    reg         m_axi_rlast;
    reg         m_axi_rvalid;
    reg  [31:0] m_axi_rdata;
    
    reg         m_axi_bvalid;
    
    // RIPL Library instantiations
    sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    lib_math        lib_math_inst ();           // Math libraries.
    
    // Test case instantiation
    test_case test_case_inst ();
    
    // instantiate bd
    axi_master axi_master_inst (
        .aclk(clk_if.c),                      // input wire aclk
        .aresetn(reset_if.rn),                // input wire aresetn
        .m_axi_awaddr(m_axi_awaddr),      // output wire [31 : 0] m_axi_awaddr
        .m_axi_awlen(m_axi_awlen),        // output wire [7 : 0] m_axi_awlen
        .m_axi_awsize(m_axi_awsize),      // output wire [2 : 0] m_axi_awsize
        .m_axi_awburst(m_axi_awburst),    // output wire [1 : 0] m_axi_awburst
        .m_axi_awlock(m_axi_awlock),      // output wire [0 : 0] m_axi_awlock
        .m_axi_awcache(m_axi_awcache),    // output wire [3 : 0] m_axi_awcache
        .m_axi_awprot(m_axi_awprot),      // output wire [2 : 0] m_axi_awprot
        .m_axi_awregion(m_axi_awregion),  // output wire [3 : 0] m_axi_awregion
        .m_axi_awqos(m_axi_awqos),        // output wire [3 : 0] m_axi_awqos
        .m_axi_awvalid(m_axi_awvalid),    // output wire m_axi_awvalid
        .m_axi_awready(m_axi_awready),    // input wire m_axi_awready
        .m_axi_wdata(m_axi_wdata),        // output wire [31 : 0] m_axi_wdata
        .m_axi_wstrb(m_axi_wstrb),        // output wire [3 : 0] m_axi_wstrb
        .m_axi_wlast(m_axi_wlast),        // output wire m_axi_wlast
        .m_axi_wvalid(m_axi_wvalid),      // output wire m_axi_wvalid
        .m_axi_wready(m_axi_wready),      // input wire m_axi_wready
        .m_axi_bresp(2'b00),        // input wire [1 : 0] m_axi_bresp
        .m_axi_bvalid(m_axi_bvalid),      // input wire m_axi_bvalid
        .m_axi_bready(m_axi_bready),      // output wire m_axi_bready
        .m_axi_araddr(m_axi_araddr),      // output wire [31 : 0] m_axi_araddr
        .m_axi_arlen(m_axi_arlen),        // output wire [7 : 0] m_axi_arlen
        .m_axi_arsize(m_axi_arsize),      // output wire [2 : 0] m_axi_arsize
        .m_axi_arburst(m_axi_arburst),    // output wire [1 : 0] m_axi_arburst
        .m_axi_arlock(m_axi_arlock),      // output wire [0 : 0] m_axi_arlock
        .m_axi_arcache(m_axi_arcache),    // output wire [3 : 0] m_axi_arcache
        .m_axi_arprot(m_axi_arprot),      // output wire [2 : 0] m_axi_arprot
        .m_axi_arregion(m_axi_arregion),  // output wire [3 : 0] m_axi_arregion
        .m_axi_arqos(m_axi_arqos),        // output wire [3 : 0] m_axi_arqos
        .m_axi_arvalid(m_axi_arvalid),    // output wire m_axi_arvalid
        .m_axi_arready(m_axi_arready),    // input wire m_axi_arready
        .m_axi_rdata(m_axi_rdata),        // input wire [31 : 0] m_axi_rdata
        .m_axi_rresp(2'b00),        // input wire [1 : 0] m_axi_rresp
        .m_axi_rlast(m_axi_rlast),        // input wire m_axi_rlast
        .m_axi_rvalid(m_axi_rvalid),      // input wire m_axi_rvalid
        .m_axi_rready(m_axi_rready)      // output wire m_axi_rready
    );
    
    // Clock generator instantiation  
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;
    
endmodule

