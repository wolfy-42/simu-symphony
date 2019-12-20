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
//               AXI stream master.
// Updated       : date / author - comments
//--------------------------------------------------------------------//

// Xilinx VIP
import axi4stream_vip_pkg::*;
import axistream_master_pkg::*;
import fidus_clock_gen_bfm_pkg::*;
import fidus_reset_gen_bfm_pkg::*;

module tb();

    // Test-bench signals.
    clk_bfm_if clk_if();
    reset_bfm_if reset_if();      // Reset signal
    
    wire [31:0] m_axis_tdata;
    wire        m_axis_tvalid;
    wire        m_axis_tlast;
    wire        m_axis_tuser;
    
    reg         m_axis_tready;
    
    // RIPL Library instantiations
    sim_management_verilog  sim_management_inst ();     // Verilog sim management instance, used by Clock and Reset BFMs
    lib_math        lib_math_inst ();           // Math libraries.
    
    // Test case instantiation
    test_case test_case_inst ();
    
    // instantiate bd
    axistream_master axistream_master_inst (
        .aclk(clk_if.c),                    // input wire aclk
        .aresetn(reset_if.rn),              // input wire aresetn
        .m_axis_tvalid(m_axis_tvalid),  // output wire [0 : 0] m_axis_tvalid
        .m_axis_tready(m_axis_tready),  // input wire [0 : 0] m_axis_tready
        .m_axis_tdata(m_axis_tdata),    // output wire [31 : 0] m_axis_tdata
        .m_axis_tlast(m_axis_tlast),    // output wire [0 : 0] m_axis_tlast
        .m_axis_tuser(m_axis_tuser)    // output wire [0 : 0] m_axis_tuser
    );
    
    // Clock generator instantiation  
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;
    
endmodule

