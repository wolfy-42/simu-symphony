//------------------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Xianxin Du
// Created       : 2021-07-08
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Description   : Testcase for Ethernet Test Generator BFM. This example
//                 configures 3 streams with different sources and encaps, and
//                 logs the output to etg_out.pcap.
// Updated       : yyyy-mm-dd / author - comments
//------------------------------------------------------------------------------

module test_case();

    // System Verilog Simulation management package
    import sim_management_pkg::*;
    import fidus_clock_gen_bfm_pkg::*;
    import fidus_reset_gen_bfm_pkg::*;

    // import fidus_axis_etg_full_pkt_pkg::*;
    import fidus_axis_packet_gen_bfm_pkg::*;
    import fidus_axis_etg_bfm_pkg::*;

    // Generated output pcap log file
    parameter PCAP_FILE_OUT         = "../testcases_envFidus_sv_simMquestaXvivado/tc_fidus_axis_etg/result_rtl/etg_out.pcap";
    // Source pcap file
    parameter PCAP_FILE_INP1        = "../testcases_envFidus_sv_simMquestaXvivado/tc_fidus_axis_etg/etg_src.pcap";
    // Number of sources for ETG
    parameter NUM_STREAMS           = 3;


    //* Variables and parameters
    sim_management s;
    parameter TC_NAME               = "tc_fidus_axis_etg";

    parameter TDATA_WIDTH           = 64;
    parameter TUSER_WIDTH           = 8;
    parameter TKEEP_WIDTH           = TDATA_WIDTH/8;

    // BFM local instances becuse Active-HDL can't refer to the TB level (it's a tool bug)
    fidus_clock_gen_bfm clk_bfm;
    fidus_reset_gen_bfm reset_bfm;

    // fidus_axis_packet_gen_bfm #(
    fidus_axis_etg_bfm #(
        .TDATA_WIDTH(TDATA_WIDTH),
        .TUSER_WIDTH(TUSER_WIDTH),
        .TKEEP_WIDTH(TKEEP_WIDTH)
    ) etg_bfm;

    // Interfaces
    fidus_axis_etg_if #(
        .TDATA_WIDTH(TDATA_WIDTH),
        .TUSER_WIDTH(TUSER_WIDTH),
        .TKEEP_WIDTH(TKEEP_WIDTH)
    )
    axi4s_source_if (
        .aclk(tb.clk_if.c),
        .aresetn(tb.reset_if.rn)
    );

    logic [TDATA_WIDTH-1 : 0] tdata;
    logic tready = 1;
    logic tvalid;
    logic [TUSER_WIDTH-1 : 0] tuser;
    logic [TKEEP_WIDTH-1 : 0] tkeep;
    logic tlast;

    assign tdata                  = axi4s_source_if.tdata;
    assign tkeep                  = axi4s_source_if.tkeep;
    assign tvalid                 = axi4s_source_if.tvalid;
    assign tuser                  = axi4s_source_if.tuser;
    assign tlast                  = axi4s_source_if.tlast;
    assign axi4s_source_if.tready = tready;


    //* ***************************** Test case body **********************************************
    initial while (1)
    begin
        // Initialize the simulation
        s.initSim(TC_NAME);

        s.printMessage (TC_NAME, "Example test case to generate packets.");
        s.printMessage (TC_NAME, "Global Reset asserted");
        s.printMessage (TC_NAME, "Set clock BIF period to 200MHz = 5.0ns");
        clk_bfm     = new("clk_bfm", tb.clk_if, 5.0);
        reset_bfm   = new("rst_bfm", tb.reset_if);
        // Construct BFM class with NUM_STREAMS, PCAP_FILE_OUT.
        etg_bfm     = new(axi4s_source_if, "etg_bfm", NUM_STREAMS, PCAP_FILE_OUT);

        reset_bfm.fAssertReset();
        #10;
        reset_bfm.fDeassertReset();

        // Reduce the tvalid rate.
        // etg_bfm.fSetValidRateGen(1, 3);

        // Zero out axi bus between packets.
        etg_bfm.fSetSanitizeBus(1);

        // Setting inter-frame gap between 0 & 10 clock cycles.
        etg_bfm.fSetIFGDelayRange(0,10);

        // Configure streams[0]: prbs data, random size, RTP/UDP/IPv4/ETH encap
        etg_bfm.streams[0].fSetDataPrbs(6, 1460);
        etg_bfm.streams[0].fSetRtpHeader(.ssrc(32'h12345678));
        etg_bfm.streams[0].fSetUdpHeader(.dst_port(1234));
        etg_bfm.streams[0].fSetIPv4Header(.dst_ip(32'hC0A85599));
        etg_bfm.streams[0].fSetEthHeader();

        // Configure streams[1]: ramp(byte counter) data, fixed size, IPv4/ETH encap
        etg_bfm.streams[1].fSetDataRamp(.min(500),.max(500));
        etg_bfm.streams[1].fSetIPv4Header();
        etg_bfm.streams[1].fSetEthHeader(.dst_mac(48'hFFFFFFFFFFFF));

        // Configure streams[2]: pcap data, vlan encap
        etg_bfm.streams[2].fSetDataFile(PCAP_FILE_INP1);
        etg_bfm.streams[2].fSetVlanHeader(.vlan_id(3000));

        // Output 12 packets (4 from each source)
        etg_bfm.tGeneratePackets(12);

        s.printPass (TC_NAME, "The simulation succeeded in sending out packets." );

        s.testComplete;
    end

    // random tready pushback
    always @ (posedge tb.clk_if.c)
    begin
        // tready <= $urandom_range(0,1);
    end

endmodule // test_case
