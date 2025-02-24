/*------------------------------------------------------------------------------
// Title         : Ethernet packet generator
// Project       : Ethernet packet generator BFM
//------------------------------------------------------------------------------
// File          : fidus_axis_packet_gen_bfm.sv
// Author        : Xianxin Du
// Created       : 2021-06-04
//------------------------------------------------------------------------------
// Description   : AXI4-Stream generator BFM, based on Bassem Sleiman's work.
//                  tSend
//                  fSetValidBubblePercent
//                  fSetValidRateGen
//                  fSetIFGDelay
//                  fSetIFGDelayRange
//                  fSetSanitizeBus
//                  fSuppressTransactionMessages
//                
// Updated       : yyyy-mm-dd / author - comments
//----------------------------------------------------------------------------*/

package fidus_axis_packet_gen_bfm_pkg;

import sim_management_pkg::*;

// This class implements the axi4 stream tx bfm
class fidus_axis_packet_gen_bfm #(
        TDATA_WIDTH = 64,
        TUSER_WIDTH = 8,
        TKEEP_WIDTH = TDATA_WIDTH/8
    );

    //--------------------------------------------------------------------------
    // Class Variables
    //--------------------------------------------------------------------------
    int ifg_min;        // inter-frame gap range (in clock cycles)
    int ifg_max;
    int rand_bubble_pc; // percent chance tvalid is randomly low during a transfer
    // tvalid will be reduced to (m/n) rate (like the output of a slow to fast clock transfer)
    int rate_m;         // rategen numerator
    int rate_n;         // rategen divisor
    bit sanitize_bus;
    bit suppress_messages;
    int pkt_cnt;        // number of sent packets
    sim_management s;
    string class_name;
    virtual fidus_axis_etg_if #(.TDATA_WIDTH(TDATA_WIDTH),    // AXI4 stream interafce
                                .TUSER_WIDTH(TUSER_WIDTH),
                                .TKEEP_WIDTH(TKEEP_WIDTH) )io;

    //-----------------------------------------------------------
    // Constructor
    //  io  : AXI4-Stream interface
    //  name: name used in logs
    //-----------------------------------------------------------
    function new (

        virtual fidus_axis_etg_if #(.TDATA_WIDTH(TDATA_WIDTH),    // AXI4 stream interafce
                                    .TUSER_WIDTH(TUSER_WIDTH),
                                    .TKEEP_WIDTH(TKEEP_WIDTH)) io,
        string  name = "fidus_axis_packet_gen_bfm"
    );
        ifg_min             = 0;
        ifg_max             = 0;
        rand_bubble_pc      = 0;
        rate_m              = 1;
        rate_n              = 1;
        sanitize_bus        = 0;
        suppress_messages   = 0;
        pkt_cnt             = 0;

        class_name = name;

        this.io = io;

        io.tdata            = 'h0;
        io.tlast            = 'b0;
        io.tuser            = 'h0;
        io.tvalid           = 'b0;
        io.tkeep            = 'b0;

    endfunction : new

    //----------------------------------------------------------------------------------------------
    // This task sends a frame to the virtual io interface that is connected to the test case.
    // It upsizes the 8-bit data coming from the byte_array_t to the bus data width, and forms tkeep
    // and tlast.
    // The task ends after the inter-frame gap following the packet has transpired.
    //----------------------------------------------------------------------------------------------
    task tSend(bit[7:0] pkt[], bit[TUSER_WIDTH-1:0] tuser_data = '0);
        int p = 0;  // pkt byte pointer
        int rate_accum = 0;

        if (!suppress_messages) s.printMessage(class_name, $sformatf("Sending packet %0d with length [%0d]", pkt_cnt, pkt.size));

        io.tuser = tuser_data;
        io.tlast = '0;

        do begin
            //Reset signals
            io.tdata = '0;
            io.tkeep = '0;
            io.tvalid = 1'd1;

            //Set bytes - AXI4S is little endian
            for (int i = 0; i<(TDATA_WIDTH/8) && (p+i)<pkt.size(); i++) begin
                io.tdata[i*8+:8] = pkt[p+i];
                io.tkeep[i] = 1'd1;
            end
            p += TDATA_WIDTH/8;

            if (p >= pkt.size) begin
               io.tlast = 1'd1;         // when the pkt reach the end set tlast
            end
            tWaitForPosClk();
            rate_accum += rate_m;

            // if downstream is not ready, pause until it has been consumed
            while (!io.tready) begin
                tWaitForPosClk();
                rate_accum += rate_m;
            end

            // optional tvalid gaps in the middle of the packet
            if (!io.tlast) begin
                // wait for rate gen limiter to fill
                while (rate_accum < rate_n) begin
                    io.tvalid = 1'd0;
                    tWaitForPosClk();
                    rate_accum += rate_m;
                end
                rate_accum -= rate_n;

                // add random tvalid low delay
                while (rand_bubble_pc >= $urandom_range(1,100)) begin
                    io.tvalid = 1'd0;
                    tWaitForPosClk();
                end
            end
        end
        while (!io.tlast);

        io.tvalid = '0;
        if (sanitize_bus) begin
            io.tlast  = '0;
            io.tkeep  = '0;
            io.tdata  = '0;
            io.tuser  = '0;
        end

        pkt_cnt++;

        tWaitForIFG();
    endtask : tSend


    //----------------------------------------------------------------------------------------------
    // Set a percentage from 0 to 99.
    // For each transmitted data word, this percentage is the chance that a tvalid low clock cycle
    // will be added. Any value greater than 0 results in gap bubbles in the middle of data packets.
    // Note: If you want a more predicatable tvalid rate, use the rategen function instead.
    //----------------------------------------------------------------------------------------------
    function void fSetValidBubblePercent(int pc);
        rand_bubble_pc = pc;
    endfunction : fSetValidBubblePercent

    //----------------------------------------------------------------------------------------------
    // Set (m/n) rategen fractions for limiting the tvalid output. Requires m <= n.
    // For example, setting(390625, 400000) will throttle the rate to behave like a packet
    // that's sourced from a 390MHz link clock, crossed into a 400MHz core domain.
    // Note: this does not impact the number of IFG cycles.
    // Note: fSetValidBubblePercent, if enabled, will apply after this rategen. xxx
    //----------------------------------------------------------------------------------------------
    function void fSetValidRateGen(int m, int n);
        rate_m = m;
        rate_n = n;
    endfunction : fSetValidRateGen

    //----------------------------------------------------------------------------------------------
    // Set a fixed number of clock cycles for the inter-frame gap.
    //----------------------------------------------------------------------------------------------
    function void fSetIFGDelay(int d);
        ifg_min = d;
        ifg_max = d;
    endfunction : fSetIFGDelay

    //----------------------------------------------------------------------------------------------
    // Set a random min/max range for the number of clock cycles for the inter-frame gap.
    //----------------------------------------------------------------------------------------------
    function void fSetIFGDelayRange(int min, int max);
        ifg_min = min;
        ifg_max = max;
    endfunction : fSetIFGDelayRange

    //----------------------------------------------------------------------------------------------
    // By default, after a packet is transferred, the values of the final word (tdata, tkeep, tlast,
    // tuser) are held until the next tvalid. Enabling this will zero those signals between packets,
    // and may offer a cleaner waveform for debugging. Those values should only ever be used with
    // tvalid (and tready) high, so both options should be functionally identical.
    //----------------------------------------------------------------------------------------------
    function void fSetSanitizeBus(bit enable);
        sanitize_bus = enable;
    endfunction : fSetSanitizeBus


    //-----------------------------------------------------------
    // Allow/Disallow log message output (does not include passes/errors)
    //      suppress: 1 to disable, 0 to enable
    //-----------------------------------------------------------
    function void fSuppressTransactionMessages(input bit suppress);
        this.suppress_messages = suppress;
    endfunction : fSuppressTransactionMessages

    // This task advances by the inter-frame gap period.
    task tWaitForIFG();
        int delay = $urandom_range(ifg_min, ifg_max);
        repeat (delay)
        begin
            tWaitForPosClk();
        end
    endtask

    // This task advance one clock
    task tWaitForPosClk();
        forever begin
            @(posedge io.aclk);
            break;
        end
    endtask : tWaitForPosClk

endclass

endpackage


