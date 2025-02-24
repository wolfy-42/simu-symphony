//------------------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project      : fidus_axis_eth_stream_pkg
// Author       : Xianxin Du
// Created      : 2021-06-09
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Description  : Ethernet data stream generator package.
//                This class handles the data generation and encapsulation for
//                a stream (or source). To setup, configure the data payload to
//                one of the 4 options, and enable whatever headers are needed.
//                Run tGetData to generate a packet.
//
//                Functions/Tasks:
//                  fSetDataPrbs    - configure payload to prbs (default)
//                  fSetDataFixed   - configure payload to fixed byte
//                  fSetDataRamp    - configure payload to sequential counter
//                  fSetDataFile    - configure payload to pcap file
//
//                  fSetRtpHeader   - configure 12-byte RTP header encapsulation
//                  fSetUdpHeader   - configure  8-byte UDP header encap
//                  fSetIPv4Header  - configure 20-byte IPv4 header encap
//                  fSetEthHeader   - configure 14-byte Ethernet header encap
//                  fSetVlanHeader  - configure  4-byte VLAN insertion
//                  fSetVlan2Header - configure  4-byte double VLAN insertion
//                  fSetEthCrc      - configure  4-byte Eth CRC appended to tail
//                  fSetEthPreamble - configure  8-byte preamble added to head
//
//                  tGetData        - generate/retrieve next data packet
//
// Updated      : yyyy-mm-dd / author - comments
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Encapsulation order:
//  RTP -> UDP -> IPv4 -> ETH -> [VLAN] -> CRC
//                                             -> preamble | inter-frame gap |
// |-- IPv4 datagram --|
// |------------- Ethernet Frame --------------|
// 
//  Note: RTP requires UDP, which requires IPv4, etc. 
//------------------------------------------------------------------------------
// MTU sizing:
// The 1500-byte standard MTU size for ethernet refers to the L3 data (eg.IPv4).
// Adding the Ethernet header, the max size becomes 1514.
// Adding CRC, the size becomes 1518 (this is the complete L2 ethernet frame).
// (If VLAN tagged, the size extends to 1522. If double tagged, extend to 1526.)
// For minimum sizes, L2 is 64 bytes and L3 is 46.
// (Note: The preamble and ifg are not counted as part of the frame, but they
//  affect overhead/throughput as part of Layer 1.)

//------------------------------------------------------------------------------
// Example encaps configs:
//  RTP through to ETH:
//      fSetRtpHeader();
//      fSetUdpHeader(.dst_port(5000));
//      fSetIPv4Header(.dst_ip(32'h10101010));
//      fSetEthHeader(.dst_mac(48'hDEADBEEF1234));
//  IPv4 through to VLAN:
//      fSetIPv4Header(.dst_ip(32'h10101010));
//      fSetEthHeader(.dst_mac(48'hDEADBEEF1234));
//      fSetVlanHeader(.vlan_id(2000));
//  For PCS (bypassing MAC):
//      ...
//      fSetEthCrc();
//      fSetEthPreamble();
//------------------------------------------------------------------------------


package fidus_axis_etg_stream_pkg;

import fidus_prbs_pkg::*;
import fidus_axis_etg_pcap_pkg::*;

class fidus_axis_etg_stream #(
);
    // Constants
    localparam ETHERTYPE_IPV4   = 16'h0800;
    localparam ETHERTYPE_VLAN   = 16'h8100; // 802.1Q
    localparam ETHERTYPE_VLAN2  = 16'h88A8; // 802.1ad double tagging
    localparam ETHERTYPE_ARP    = 16'h0806;

    localparam IPV4_PROTOCOL_ICMP   = 8'h01;
    localparam IPV4_PROTOCOL_IGMP   = 8'h02;
    localparam IPV4_PROTOCOL_TCP    = 8'h06;
    localparam IPV4_PROTOCOL_UDP    = 8'h11;
    localparam IPV4_PROTOCOL_TEST   = 8'hFD;

    localparam ENCAP_LEN_RTP    = 12;
    localparam ENCAP_LEN_UDP    = 8;
    localparam ENCAP_LEN_IPV4   = 20;
    localparam ENCAP_LEN_ETH    = 14;
    localparam ENCAP_LEN_VLAN   = 4;
    localparam ENCAP_LEN_CRC    = 4;

    localparam CRC32POL = 32'hEDB88320; /* Ethernet CRC-32 Polynomial, reversed */

    enum {
        DATA_MODE_PRBS,
        DATA_MODE_FIXED,
        DATA_MODE_RAMP,
        DATA_MODE_FILE
    } DATA_MODES;

    // Variables
    int         data_mode;
    int         payload_size_min;
    int         payload_size_max;
    bit[7:0]    payload_fixed_data;
    bit[7:0]    payload_ramp_data;
    int         source_file;
    int         crc_err_pc;

    bit[7:0]    payload_data[]; // dynamic array to payload data

    fidus_prbs #(.pPRBS_LEN(7)) prbs;   // PRBS generator


    // Configuration of encap - controls whether each protocol is enabled.
    typedef struct {
        bit eth_preamble;
        bit eth_crc;
        bit eth;
        bit vlan;
        bit vlan2;
        bit ipv4;
        bit udp;
        bit rtp;
    } encap_config_t;
    encap_config_t encap_config;

    //--------------------------------------------------------------------------
    // Encap data types
    // Note that the following structs are packed in transmission bit order.
    //--------------------------------------------------------------------------
    // Ethernet frame header - 12 bytes
    typedef struct packed {
        logic [47 : 0] dst_mac;
        logic [47 : 0] src_mac;
        logic [15 : 0] ethertype;
    } eth_hdr_t;
    eth_hdr_t eth_hdr;

    // VLAN tag - 4 bytes
    typedef struct packed {
        logic [15 : 0] tpid;
        logic [ 2 : 0] pcp;
        logic          dei;
        logic [11 : 0] vid;
    } vlan_hdr_t;
    vlan_hdr_t vlan_hdr;
    vlan_hdr_t vlan2_hdr;

    // IPv4 header - 20 bytes
    typedef struct packed {
        logic [ 3 : 0] version;
        logic [ 3 : 0] ihl;
        logic [ 5 : 0] dscp;
        logic [ 1 : 0] ecn;
        logic [15 : 0] tot_len;
        logic [15 : 0] id;
        logic [ 2 : 0] flags;
        logic [12 : 0] frag_offset;
        logic [ 7 : 0] ttl;
        logic [ 7 : 0] protocol;
        logic [15 : 0] hdr_cksm;
        logic [31 : 0] src_ip;
        logic [31 : 0] dst_ip;
    } ipv4_hdr_t;
    ipv4_hdr_t ipv4_hdr;

    // UDP header - 8 bytes
    typedef struct packed {
        logic [15 : 0] src_port;
        logic [15 : 0] dst_port;
        logic [15 : 0] length;
        logic [15 : 0] checksum;
    } udp_hdr_t;
    udp_hdr_t udp_hdr;

    // RTP header - 12 bytes
    typedef struct packed {
        logic [ 1 : 0] version;
        logic          p;
        logic          x;
        logic [ 3 : 0] cc;
        logic          m;
        logic [ 6 : 0] pt;
        logic [15 : 0] seq_num;
        logic [31 : 0] timestamp;
        logic [31 : 0] ssrc;
    } rtp_hdr_t;
    rtp_hdr_t rtp_hdr;


    //----------------------------------------------------------------------------------------------
    // Constructor
    //----------------------------------------------------------------------------------------------
    function new ();
        data_mode = DATA_MODE_PRBS;
        payload_size_min = 46;
        payload_size_max = 1442;
        prbs = new();
    endfunction : new

    //----------------------------------------------------------------------------------------------
    // Configure the payload data to be PRBS7.
    //----------------------------------------------------------------------------------------------
    function void fSetDataPrbs(
        int         min = 46,   // 46 + 14(ETH) + 4(FCS) = 64, which is the minimum sized frame
        int         max = 1442  // 1442 + 54(RTP through ETH) + 4 (FCS) = 1500
    );
        data_mode = DATA_MODE_PRBS;
        payload_size_min = min;
        payload_size_max = max;
    endfunction : fSetDataPrbs;

    //----------------------------------------------------------------------------------------------
    // Configure the payload data to repeat a fixed byte.
    // The payload size (in bytes) will be randomly selected between min and max.
    // Depending on the encapsulation overhead, the min and/or max values should be adjusted.
    //----------------------------------------------------------------------------------------------
    function void fSetDataFixed(
        bit [7:0]   data,
        int         min = 46,   // 46 + 14(ETH) + 4(FCS) = 64, which is the minimum sized frame
        int         max = 1442  // 1442 + 54(RTP through ETH) + 4 (FCS) = 1500
    );
        data_mode = DATA_MODE_FIXED;
        payload_size_min = min;
        payload_size_max = max;
        payload_fixed_data = data;
    endfunction : fSetDataFixed;

    //----------------------------------------------------------------------------------------------
    // Configure the payload data to be a byte counter.
    //----------------------------------------------------------------------------------------------
    function void fSetDataRamp(
        bit [7:0]   data = 0,   // optional init data
        int         min = 46,   // 46 + 14(ETH) + 4(FCS) = 64, which is the minimum sized frame
        int         max = 1442  // 1442 + 54(RTP through ETH) + 4 (FCS) = 1500
    );
        data_mode = DATA_MODE_RAMP;
        payload_size_min = min;
        payload_size_max = max;
        payload_ramp_data = data;
    endfunction : fSetDataRamp;

    //----------------------------------------------------------------------------------------------
    // Configure the payload data to be from a pcap file.
    // Note: if pcap runs out of data, xxx what happens?
    //----------------------------------------------------------------------------------------------
    function void fSetDataFile(
        string      filename
    );
        data_mode = DATA_MODE_FILE;
        if (source_file) fClosePacketCaptureFile(source_file);
        source_file = fOpenReadPacketCaptureFile(filename);
        // if (source_file) $display("source_file opened: %d", source_file);
    endfunction : fSetDataFile;

    //----------------------------------------------------------------------------------------------
    // Encap configuration functions
    //----------------------------------------------------------------------------------------------
    // 12-byte RTP header encapsulation
    function void fSetRtpHeader(
        bit         enable  = 1,
        bit         marker  = 0,
        bit [ 6:0]  pt      = 6'h21,
        bit [15:0]  seq_num = 16'h0,
        bit [31:0]  tstamp  = 32'h0,
        bit [31:0]  ssrc    = 32'h0
    );
        encap_config.rtp = enable;

        rtp_hdr.version     = 2'h2;
        rtp_hdr.p           = 0;
        rtp_hdr.x           = 0;
        rtp_hdr.cc          = 4'b0;
        rtp_hdr.m           = marker;
        rtp_hdr.pt          = pt;
        rtp_hdr.seq_num     = seq_num;
        rtp_hdr.timestamp   = tstamp;
        rtp_hdr.ssrc        = ssrc;
    endfunction : fSetRtpHeader

    //  8-byte UDP header encap
    function void fSetUdpHeader(
        bit         enable      = 1,
        bit [15:0]  dst_port    = 16'h1234,
        bit [15:0]  src_port    = 16'hABCD
    );
        encap_config.udp = enable;

        udp_hdr.src_port = src_port;
        udp_hdr.dst_port = dst_port;
        udp_hdr.length   = 16'h0;    // calculated at transmit
        udp_hdr.checksum = 16'h0;    // calculated at transmit
    endfunction : fSetUdpHeader;

    // 20-byte IPv4 header encap
    function void fSetIPv4Header(
        bit         enable      = 1,
        bit [31:0]  dst_ip      = 32'hEF640A01, // 239.100.10.1
        bit [31:0]  src_ip      = 32'hC0A86401, // 192.168.100.1
        bit [ 7:0]  protocol    = IPV4_PROTOCOL_TEST,
        bit [ 7:0]  ttl         = 8'd128,
        bit [ 5:0]  dscp        = 6'h0          // standard
    );
        encap_config.ipv4   = enable;

        ipv4_hdr.version        = 4'h4;
        ipv4_hdr.ihl            = 4'h5;
        ipv4_hdr.dscp           = dscp;
        ipv4_hdr.ecn            = 2'h0;
        ipv4_hdr.tot_len        = 16'h0;     // calculated at transmit
        ipv4_hdr.id             = 16'h0;
        ipv4_hdr.flags          = 3'h0;
        ipv4_hdr.frag_offset    = 13'h0;
        ipv4_hdr.ttl            = ttl;
        ipv4_hdr.protocol       = protocol; // note: may be replaced if encap_config.udp
        ipv4_hdr.hdr_cksm       = '0;     // calculated at transmit
        ipv4_hdr.src_ip         = src_ip;
        ipv4_hdr.dst_ip         = dst_ip;
    endfunction : fSetIPv4Header;

    // 14-byte Ethernet header encap
    function void fSetEthHeader(
        bit         enable      = 1,
        bit [47:0]  dst_mac     = 48'h01005E640A01, // multicast, matching 239.100.10.1
        bit [47:0]  src_mac     = 48'hFC9FAE010203, // FC:9F:AE is Fidus OUI
        bit [15:0]  ethertype   = 16'h0800          // IPv4
    );
        encap_config.eth    = enable;

        eth_hdr.dst_mac     = dst_mac;
        eth_hdr.src_mac     = src_mac;
        eth_hdr.ethertype   = ethertype;    // note: may be replaced if encap_config.ipv4
    endfunction : fSetEthHeader;

    //  4-byte VLAN inserted into Eth header
    function void fSetVlanHeader(
        bit         enable  = 1,
        bit [11:0]  vlan_id = 12'h001,
        bit [ 2:0]  pcp     = '0,       // default (Best effort)
        bit         dei     = '0        // drop eligible indicator
    );
        encap_config.vlan   = enable;
        vlan_hdr.tpid   = ETHERTYPE_VLAN;
        vlan_hdr.pcp    = pcp;
        vlan_hdr.dei    = dei;
        vlan_hdr.vid    = vlan_id;
    endfunction : fSetVlanHeader;

    //  4-byte Double Tag VLAN inserted into Eth header
    function void fSetVlan2Header(
        bit         enable  = 1,
        bit [11:0]  vlan_id = 12'h002,
        bit [ 2:0]  pcp     = '0,       // default (Best effort)
        bit         dei     = '0        // drop eligible indicator
    );
        encap_config.vlan2  = enable;
        vlan2_hdr.tpid  = ETHERTYPE_VLAN2;
        vlan2_hdr.pcp   = pcp;
        vlan2_hdr.dei   = dei;
        vlan2_hdr.vid   = vlan_id;
    endfunction : fSetVlan2Header;

    //  4-byte Ethernet CRC32 appended to the tail end of frame/packet
    function void fSetEthCrc(
        bit         enable      = 1,
        int         err_percent = 0
    );
        encap_config.eth_crc = enable;
        crc_err_pc = err_percent;
    endfunction : fSetEthCrc;

    //  8-byte preamble added to head of packet (before Eth header)X
    function void fSetEthPreamble(
        bit         enable  = 1
    );
        encap_config.eth_preamble = enable;
    endfunction : fSetEthPreamble;



    //----------------------------------------------------------------------------------------------
    // Task to create packet.
    //----------------------------------------------------------------------------------------------
    task tGetData(
        output bit [7:0] o_data []
    );
        // bit [7:0]   encapped_data [];
        int         payload_size;

        // generate the payload data
        if (data_mode == DATA_MODE_FIXED) begin
            payload_size = $urandom_range(payload_size_min, payload_size_max);
            payload_data = new[payload_size];
            for (int i = 0; i < payload_size; i++) begin
                payload_data[i] = payload_fixed_data;
            end
        end else if (data_mode == DATA_MODE_RAMP) begin
            payload_size = $urandom_range(payload_size_min, payload_size_max);
            payload_data = new[payload_size];
            for (int i = 0; i < payload_size; i++) begin
                payload_data[i] = payload_ramp_data;
                payload_ramp_data++;
            end
        end else if (data_mode == DATA_MODE_PRBS) begin
            payload_size = $urandom_range(payload_size_min, payload_size_max);
            payload_data = new[payload_size];
            prbs.tGenPrbsPacket(payload_size, payload_data);
            // for (int i = 0; i < payload_size; i++) begin
                // payload_data[i] = $urandom_range(0,255);
            // end
        end else if (data_mode == DATA_MODE_FILE) begin
            bit         read_success;
            bit [7:0]   temp_data [];
            bit [31:0]  ts_s;
            bit [31:0]  ts_ns;
            tReadPacketCaptureFile(
                .fd(source_file),
                .success(read_success),
                .data(temp_data),
                .ts_s(ts_s),
                .ts_ns(ts_ns)
            );
            payload_size = temp_data.size();
            payload_data = temp_data;
            // $display("File packet success=%d, size=%d, ts_s=%d, ts_ns=%d", read_success, payload_size, ts_s, ts_ns);
        end

        // apply encapsulations
        tEncapData(payload_data, o_data);

        // o_data = encapped_data;

    endtask : tGetData

    //----------------------------------------------------------------------------------------------
    // Subtask to encap raw payload into packet.
    //----------------------------------------------------------------------------------------------
    task automatic tEncapData (
        input  bit [7:0] i_data [],
        output bit [7:0] o_data []
    );
        bit [16:0] calc_ipv4_cs = '0;
        // use a queue for push_front/back capabilities
        bit [7:0] packet_queue [$];
        packet_queue = i_data;

        if (encap_config.rtp) begin
            for (int i=0; i<ENCAP_LEN_RTP; i++) begin
                packet_queue.push_front(rtp_hdr[i*8 +: 8]);
            end
            rtp_hdr.seq_num++;  // auto increment rtp sequence number
        end

        if (encap_config.udp) begin
            // update the length field
            udp_hdr.length = packet_queue.size() + ENCAP_LEN_UDP;
            for (int i=0; i<ENCAP_LEN_UDP; i++) begin
                packet_queue.push_front(udp_hdr[i*8 +: 8]);
            end
        end

        if (encap_config.ipv4) begin
            // update length
            ipv4_hdr.tot_len = packet_queue.size() + ENCAP_LEN_IPV4;
            // update protocol
            if (encap_config.udp) ipv4_hdr.protocol = IPV4_PROTOCOL_UDP;
            // calculate header checksum
            ipv4_hdr.hdr_cksm = '0;
            for (int i=0; i<10; i++) begin
                calc_ipv4_cs += ipv4_hdr[i*16 +: 16];
                if (calc_ipv4_cs[16]) begin
                    calc_ipv4_cs += 1;
                    calc_ipv4_cs[16] = 0;
                end
            end
            ipv4_hdr.hdr_cksm = ~calc_ipv4_cs[15:0];

            for (int i=0; i<ENCAP_LEN_IPV4; i++) begin
                packet_queue.push_front(ipv4_hdr[i*8 +: 8]);
            end
        end

        if (encap_config.eth) begin
            // update ethertype
            if (encap_config.ipv4) eth_hdr.ethertype = ETHERTYPE_IPV4;
            for (int i=0; i<ENCAP_LEN_ETH; i++) begin
                packet_queue.push_front(eth_hdr[i*8 +: 8]);
            end
        end

        if (encap_config.vlan) begin
            for (int i=0; i<ENCAP_LEN_VLAN; i++) begin
                packet_queue.insert(12, vlan_hdr[i*8 +: 8]);    // insert at ethertype position
            end
        end
        if (encap_config.vlan2) begin
            for (int i=0; i<ENCAP_LEN_VLAN; i++) begin
                packet_queue.insert(12, vlan2_hdr[i*8 +: 8]);
            end
        end

        if (encap_config.eth_crc) begin
            // CRC calculation
            bit [31:0] crc32_val = 32'hffffffff;    // shiftregister,startvalue
            bit [7:0]  data;

            //The result of the loop generate 32-Bit-mirrowed CRC
            for (int i = 0; i < packet_queue.size(); i++)
            begin
                data = packet_queue[i];
                for (int j=0; j < 8; j++) // Bitwise from LSB to MSB
                begin
                    if ((crc32_val[0]) != (data[0])) begin
                        crc32_val = (crc32_val >> 1) ^ CRC32POL;
                    end else begin
                        crc32_val >>= 1;
                    end
                    data >>= 1;
                end
            end
            crc32_val ^= 32'hffffffff; //invert results

            // fudge crc value
            if (crc_err_pc >= $urandom_range(1,100)) begin
                crc32_val ^= 32'(1<<$urandom_range(0,31));
            end

            for (int i=0; i<ENCAP_LEN_CRC; i++) begin
                packet_queue.push_back(crc32_val[i*8 +: 8]);
            end
        end

        if (encap_config.eth_preamble) begin
            packet_queue.push_front(8'hD5);
            for (int i=0; i<7; i++) packet_queue.push_front(8'h55);
        end

        o_data = packet_queue;

    endtask : tEncapData

endclass
endpackage
