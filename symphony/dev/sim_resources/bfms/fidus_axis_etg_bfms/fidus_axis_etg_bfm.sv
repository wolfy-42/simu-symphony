/*------------------------------------------------------------------------------
// Title         : Ethernet packet generator
// Project       : Ethernet packet generator BFM
//------------------------------------------------------------------------------
// File          : fidus_axis_etg_bfm.sv
// Author        : Xianxin Du
// Created       : 2021-07-08
//------------------------------------------------------------------------------
// Description   : Ethernet Test Generator BFM, based on Bassem Sleiman's work.
//                 Construct this class with num_streams set to the number of 
//                 desired data streams. pcapfile option can be used to log the 
//                 generated traffic. Configure each stream with a data source
//                 and any encapsulation. Configure the base class's axis bus
//                 settings, if necessary. Call tGeneratePackets to output data.
//
//              tGeneratePackets()
//                (fidus_axis_etg_stream_pkg):
//                  streams[n].fSetDataPrbs
//                  streams[n].fSetDataFixed
//                  streams[n].fSetDataRamp
//                  streams[n].fSetDataFile
//
//                  streams[n].fSetRtpHeader
//                  streams[n].fSetUdpHeader
//                  streams[n].fSetIPv4Header
//                  streams[n].fSetEthHeader
//                  streams[n].fSetVlanHeader
//                  streams[n].fSetEthCrc
//                  streams[n].fSetEthPreamble
//              (fidus_axis_packet_gen_bfm):
//                fSetValidBubblePercent
//                fSetValidRateGen
//                fSetIFGDelay
//                fSetIFGDelayRange
//                fSetSanitizeBus
//
// Updated       : yyyy-mm-dd / author - comments
//----------------------------------------------------------------------------*/


package fidus_axis_etg_bfm_pkg;

import sim_management_pkg::*;
import fidus_axis_packet_gen_bfm_pkg::*;
import fidus_axis_etg_stream_pkg::*;
import fidus_axis_etg_pcap_pkg::*;
import fidus_prbs_pkg::*;

// This class implements the axi4 stream tx bfm
class fidus_axis_etg_bfm #(
        TDATA_WIDTH = 64,
        TUSER_WIDTH = 8,
        TKEEP_WIDTH = TDATA_WIDTH/8
    ) extends fidus_axis_packet_gen_bfm #(  // pass params to base class
        .TDATA_WIDTH(TDATA_WIDTH),
        .TUSER_WIDTH(TUSER_WIDTH),
        .TKEEP_WIDTH(TKEEP_WIDTH)
    );

    //--------------------------------------------------------------------------
    // Class Variables
    //--------------------------------------------------------------------------
    fidus_axis_etg_stream streams[];
    sim_management s;
    int log_fd;
    bit suppress_messages;
    string name;

    //--------------------------------------------------------------------------
    // Constructor
    //  io          : AXI4-Stream interface
    //  name        : name used in logs
    //  num_streams : number of sources
    //  pcapfile    : filepath to save generated packets in a pcap
    //--------------------------------------------------------------------------
    function new (
        virtual fidus_axis_etg_if #(.TDATA_WIDTH(TDATA_WIDTH),    // AXI4 stream interface
                                    .TUSER_WIDTH(TUSER_WIDTH),
                                    .TKEEP_WIDTH(TKEEP_WIDTH)) io,
        string name = "fidus_axis_etg_bfm",
        int    num_streams = 1,
        string pcapfile = ""
    );
        super.new(io, name);
        this.name = name;
        // allocate
        streams = new[num_streams];
        for (int i=0; i<streams.size(); i++) streams[i] = new();

        // open pcap file
        log_fd = 0;
        if (pcapfile != "") begin
            log_fd = fOpenNewPacketCaptureFile(pcapfile);
            s.printMessage(name, $sformatf("Opened file %s for writing.", pcapfile));
        end 

        suppress_messages = 0;

    endfunction : new


    //--------------------------------------------------------------------------
    // Generate and output packets from the configured streams.
    // num_packets is the total number of packets to send.
    // Stream sources will round-robin.
    //--------------------------------------------------------------------------
    task tGeneratePackets(input int num_packets);
        bit [7:0] temp [];
        int stream_idx = 0;

        if (!this.suppress_messages) s.printMessage(name, $sformatf("Generating %d packets.", num_packets));

        tWaitForPosClk();

        for (int i=0; i<num_packets; i++) begin
            streams[stream_idx].tGetData(temp); // generate the packet data from the selected stream
            void'(fWritePacketCaptureFile(log_fd, temp));   // write packet to pcap
            tSend(temp, stream_idx);    // send the packet data with the stream index in tuser
            // switch streams
            stream_idx++;
            if (stream_idx == streams.size()) stream_idx = 0;
        end

        // fClosePacketCaptureFile(log_fd);
    endtask : tGeneratePackets

    //-----------------------------------------------------------
    // Allow/Disallow log message output (does not include passes/errors)
    //      suppress: 1 to disable, 0 to enable
    //-----------------------------------------------------------
    function void fSuppressTransactionMessages(input bit suppress);
        super.fSuppressTransactionMessages(suppress);
        this.suppress_messages = suppress;
    endfunction : fSuppressTransactionMessages

endclass

endpackage
