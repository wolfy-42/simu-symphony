//----------------------------------------------------------------------------//
// Copyright (C) 2023 Fidus Systems Inc.
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//----------------------------------------------------------------------------//
// Project       : simu
// Author        : Jack Tipper
// Created       : 2023-12-15
//----------------------------------------------------------------------------//
// Description   : BFM package that contains class for generating and checking
//                 axis packets.
//                 Can generate an axis bus on the tx_if, and check packets in
//                 order of transmission on the rx_if automatically.
//
//                 To use the transaction generator, call either fEnqueuePkt()
//                 or fEnqueuePkts() with the number of bytes you desire the
//                 transaction to generate on the tx_if.
//
//                 To use the transaction checker, simply attach your output
//                 axis bus to the rx_if, and it will check the packets in order
//                 of packet transaction. This can be disabled.
//
//                 The intended use of this module is to interact with the
//                 functions provided, but the tasks may be used to gain insight
//                 into how this bfm operates.
//
//                 Functions: (intended interface for end-user)
//                     new(...)
//                       - Creates a bfm class instance.
//                     fEnqueuePkt(n_bytes)
//                       - Enqueue a packet containing n_bytes number of bytes.
//                       - Randomness is determined by the parameter
//                         RANDOM_DATA, otherwise will count up per 32bits.
//                     fEnqueuePkts(n_bytes[])
//                       - Performs EnqueuePkts() for each item in the n_bytes
//                         array.
//                     fClearExpectedQueue()
//                       - Clears all packet entries from the expected queue.
//                       - Useful to use between tests to prevent cross
//                         communication when packets are missed.
//                     fGetSentPkts()
//                       - Returns the number of packets sent by this bfm.
//                     fGenReceivedPkts()
//                       - Returns the number of packets received by this bfm.
//                     fGenTxData()
//                       - Returns data that fits the width of the tx tdata bus.
//                       - Will be random if the RANDOM_DATA parameter is high.
//                       - Otherwise, will count upwards (repeated every 32b).
//
//                 Main Tasks: (performs key logic and data manipulation)
//                     tDoTvalidPushback()
//                       - Will assert tvalid on tx interface after a maximum of
//                         TVALID_PUSHBACK tx clock cycles.
//                     tDoTreadyPushback()
//                       - Will assert tready on tx interface after a maximum of
//                         TREADY_PUSHBACK rx clock cycles.
//                     tTransmitPkt()
//                       - Transmits a queued packet on the tx interface.
//                       - Requires GEN_PKTS to be high to work automatically.
//                     tCaptureExpected()
//                       - Captures packets on tx interface, adding them to the
//                         expected packet queue.
//                       - Requires CHECK_PKTS to be high to work automatically.
//                     tCaptureReceived()
//                       - Captures packets on rx interface, adding them to the
//                         received packet queue.
//                       - Requires CHECK_PKTS to be high to work automatically.
//                     tCheckPacket()
//                       - Compares the collected packet in the received queue
//                         to the oldest packet in the expected queue.
//                       - Requires CHECK_PKTS to be high to work automatically.
//
//                 Driver Tasks: (drives enabled automatic tasks)
//                     tDriveIfTx()
//                       - Transmits queued packets on the tx interface.
//                       - Enabled if the GEN_PKTS parameter is set to high.
//                     tDriveExpected()
//                       - Monitors the tx interface, and captures packets on
//                         transaction.
//                       - Enabled if the CHECK_PKTS parameter is set to high.
//                     tDriveReceived()
//                       - Monitors the rx interface, and captures packets on
//                         transaction.
//                       - Enabled if the CHECK_PKTS parameter is set to high.
//
//                 Helper Tasks: (for code readability and cleanliness)
//                     tZeroIfTx()
//                       - Zeros all controlled tx interface signals.
//                     tZeroIfRx()
//                       - Zeros all controlled rx interface signals (tready).
//                     tWaitForQueuedPkt()
//                       - Waits for a packet to be queued.
//                     tWaitForTransactionTx()
//                       - Waits for a transaction on the tx interface.
//                     tWaitForTransactionRx()
//                       - Waits for a transaction on the rx interface.
//                     tWaitClkTx()
//                       - Waits until a posedge on tx interface clock.
//                     tWaitClkRx()
//                       - Waits until a posedge on rx interface clock.
//
// Updated       : date / author - comments
//----------------------------------------------------------------------------//

interface axis_bfm_if #(
    parameter int   DATA_WIDTH  = 128*8,
    localparam int  KEEP_WIDTH  = DATA_WIDTH/8
) (
    input logic             aclk
);
    logic                   tvalid;
    logic                   tready;
    logic [DATA_WIDTH-1:0]  tdata;
    logic                   tlast;
    logic [KEEP_WIDTH-1:0]  tkeep;
endinterface : axis_bfm_if

package fidus_axis_gen_bfm_pkg;

import sim_management_pkg::*;

class fidus_axis_gen_bfm #(
    parameter int   TX_DATA_WIDTH       = 32,   // Tx interface data width. Must be divisible by 8.
    parameter int   RX_DATA_WIDTH       = 32,   // Rx interface data width. Must be divisible by 8.
    parameter bit   GEN_PKTS            = 1,    // Whether this bfm controls the tx interface and generate packets on it.
    parameter bit   CHECK_PKTS          = 1,    // Whether packet checking will occur between the tx and rx interface.
    parameter bit   CONTROL_RX_TREADY   = 1,    // Whether this bfm controls the rx tready signal (1 for control, 0 for just detection).
    parameter int   TVALID_PUSHBACK     = 0,    // Upper bound of delay cycles between successful transmission and being valid for the next one on the tx interface.
    parameter int   TREADY_PUSHBACK     = 0,    // Upper bound of delay cycles between successful transmission and being ready for the next one on the rx interface.
    parameter bit   RANDOM_DATA         = 1,    // Whether generated packets will be filled by random numbers or the current frame of the packet transmission.
    parameter int   SEED                = 0     // Seed for random data generation.
);
    //------------------------------------------------------------------------------
    // Local Parameters
    //------------------------------------------------------------------------------
    localparam int  TX_DATA_WIDTH_BYTES = TX_DATA_WIDTH/8;
    localparam int  RX_DATA_WIDTH_BYTES = RX_DATA_WIDTH/8;
    localparam int  DATA_REPLICATION    = TX_DATA_WIDTH/32; // used to determine how many times to gather 32'b urandom() to fill bus

    //------------------------------------------------------------------------------
    // Class Members
    //------------------------------------------------------------------------------
    sim_management s;
    string CLASS_NAME;

    virtual axis_bfm_if #(
        .DATA_WIDTH(TX_DATA_WIDTH)
    ) io_tx;
    virtual axis_bfm_if #(
        .DATA_WIDTH(RX_DATA_WIDTH)
    ) io_rx;

    int     pkt_byte_len[$];
    byte    expected_collector[$];
    byte    pkts_expected[$][$]; // disconnected from the input and output data widths
    byte    pkt_received[$];

    int stat_queued_pkts;
    int stat_sent_pkts;
    int stat_expected_pkts;
    int stat_received_pkts;
    int stat_checked_pkts;
    int stat_removed_pkts;

    bit [TX_DATA_WIDTH-1:0] random_gen_offset;


    //------------------------------------------------------------------------------
    // Functions
    //------------------------------------------------------------------------------
    // constructor
    function new (
        string name = "axis_gen_bfm",
        virtual axis_bfm_if #(
            .DATA_WIDTH(TX_DATA_WIDTH)
        ) tx,
        virtual axis_bfm_if #(
            .DATA_WIDTH(RX_DATA_WIDTH)
        ) rx
    );
        this.CLASS_NAME = name;
        this.io_tx      = tx;
        this.io_rx      = rx;

        this.pkt_byte_len       = {};
        this.expected_collector = {};
        this.pkts_expected      = {};
        this.pkt_received       = {};

        this.stat_queued_pkts   = '0;
        this.stat_sent_pkts     = '0;
        this.stat_expected_pkts = '0;
        this.stat_received_pkts = '0;
        this.stat_checked_pkts  = '0;
        this.stat_removed_pkts  = '0;

        this.random_gen_offset          = '0;

        fork
           tDriveIfTx();
           tDriveExpected();
           tDriveReceived();
        join_none

    endfunction : new

    // add a single packet to the data queue
    function void fEnqueuePkt(
        input int n_bytes
    );
        if (GEN_PKTS) begin
            this.pkt_byte_len.push_back(n_bytes);
            s.printMessage(CLASS_NAME, $sformatf("Queued packet %d with: n_bytes=%d.", this.stat_queued_pkts, n_bytes));
            this.stat_queued_pkts++;
        end // endif
        else begin
            s.printWarning(CLASS_NAME, "Cannot queue packet as GEN_PKTS is disabled.");
        end // endelse
    endfunction : fEnqueuePkt

    // add multiple packets to the data queue
    function void fEnqueuePkts(
        input int n_bytes[]
    );
        for (int i=0; i<$size(n_bytes); i++) begin
            fEnqueuePkt(n_bytes[i]);
        end // endfor
    endfunction : fEnqueuePkts

    // clear the expected queue
    function void fClearExpectedQueue();
        while (this.pkts_expected.size() > 0) begin
            this.pkts_expected.delete(0);
            s.printMessage(CLASS_NAME, $sformatf("Removed packet %d from expected queue.", this.stat_checked_pkts + this.stat_removed_pkts));
            this.stat_removed_pkts++;
        end // endwhile
    endfunction : fClearExpectedQueue

    // get number of transmitted pkts
    function int fGetSentPkts();
        return this.stat_sent_pkts;
    endfunction : fGetSentPkts

    // get number of checked packets
    function int fGetCheckedPkts();
        return this.stat_checked_pkts;
    endfunction : fGetCheckedPkts

    // read the next expected packet
    function void fReadExpectedPkt();
        string frameData;
        byte pkt_data[$] = this.pkts_expected[0];
        for (int i = 0; i < pkt_data.size(); i++) begin
            s.printMessage(CLASS_NAME, $sformatf("Expected Packet %d: index=%d, byte=%d.", this.stat_checked_pkts, i, pkt_data[i]));
        end // endfor
    endfunction : fReadExpectedPkt

    // read the current state of the received packet
    function void fReadReceivedPkt();
        for (int i = 0; i < $size(this.pkt_received); i++) begin
            s.printMessage(CLASS_NAME, $sformatf("Recieved Packet %d thusfar: index=%d, byte=%d", this.stat_checked_pkts, i, this.pkt_received[i]));
        end // endfor
    endfunction : fReadReceivedPkt

    // generate random data of proper width
    function bit [TX_DATA_WIDTH-1:0] fGenTxData();
        this.random_gen_offset++;
        return RANDOM_DATA ? {DATA_REPLICATION{$urandom(SEED + this.random_gen_offset)}} : {DATA_REPLICATION{this.random_gen_offset}};
    endfunction : fGenTxData

    //------------------------------------------------------------------------------
    // Tasks
    //------------------------------------------------------------------------------
    // do tvalid pushback
    task automatic tDoTvalidPushback();
        int n_pushbacks;

        this.random_gen_offset++;
        n_pushbacks = $urandom(SEED + this.random_gen_offset) % (TVALID_PUSHBACK+1);

        this.io_tx.tvalid <= 0;
        for (int i = 0; i < n_pushbacks; i++) begin
            tWaitClkTx();
        end // endfor
        this.io_tx.tvalid <= 1;
    endtask : tDoTvalidPushback
    // do tready pushback
    task automatic tDoTreadyPushback();
        int n_pushbacks;

        this.random_gen_offset++;
        n_pushbacks = $urandom(SEED + this.random_gen_offset) % (TREADY_PUSHBACK+1);

        this.io_rx.tready <= 0;
        for (int i = 0; i < n_pushbacks; i++) begin
            tWaitClkRx();
        end // endfor
        this.io_rx.tready <= 1;
    endtask : tDoTreadyPushback

    // transmit packet on tx interface
    task automatic tTransmitPkt();
        // capture data to transmit
        int n_bytes = pkt_byte_len.pop_front();
        int keep    = n_bytes % (TX_DATA_WIDTH_BYTES);
        int length  = n_bytes / (TX_DATA_WIDTH_BYTES) + (keep != 0);

        // general case, just add data to a frame
        for (int i = 0; i < length - (keep != 0); i++) begin
            this.io_tx.tdata    <= fGenTxData();
            this.io_tx.tkeep    <= -1; // set all high
            this.io_tx.tlast    <= i == length-1; // perfectly filled frame case

            tDoTvalidPushback();
            tWaitForTransactionTx();
            this.io_tx.tvalid   <= 0; // not bothering with resetting entire if
        end // endfor

        // last frame
        if (keep != 0) begin
            this.io_tx.tdata    <= fGenTxData(); // not bothering with tkeep masking
            this.io_tx.tkeep    <= (1 << keep) - 1;
            this.io_tx.tlast    <= 1;

            tDoTvalidPushback();
            tWaitForTransactionTx();
            this.io_tx.tvalid   <= 0; // not bothering with resetting entire if
        end // endif

        s.printMessage(CLASS_NAME, $sformatf("Transmitted packet %d.", this.stat_sent_pkts));
        this.stat_sent_pkts++;
    endtask : tTransmitPkt

    // capture transmitted packets
    task automatic tCaptureExpected();
        // masking using keep
        for (int i = 0; i < TX_DATA_WIDTH_BYTES; i++) begin
            if (this.io_tx.tkeep[i]) begin
                this.expected_collector.push_back(this.io_tx.tdata[i*8+:8]);
            end // endif
        end // endfor

        if (this.io_tx.tlast) begin
            this.pkts_expected.push_back(this.expected_collector);
            this.expected_collector.delete();
            this.stat_expected_pkts++;
        end // endif
    endtask : tCaptureExpected

    // capture received packets
    task automatic tCaptureReceived();
        // masking using keep
        for (int i = 0; i < RX_DATA_WIDTH_BYTES; i++) begin
            if (this.io_rx.tkeep[i]) begin
                this.pkt_received.push_back(this.io_rx.tdata[i*8+:8]);
            end // endif
        end // endfor
        if (this.io_rx.tlast) begin
            this.stat_received_pkts++;
        end // endif
    endtask : tCaptureReceived

    // compare expected versus received packets
    task automatic tCheckPacket();
        byte    pkt_expected[$];
        byte    expected;
        byte    received;
        int     byte_index = 0;
        string  info_string = "";
        int     errorCount = 0;

        // wait for an expected packet if one does not exist yet
        if (this.pkts_expected.size() == 0) begin
            s.printError(CLASS_NAME, $sformatf("Received packet %d before any packet was expected.", this.stat_checked_pkts));
            this.pkt_received.delete();
            errorCount++;
        end // endwhile
        else begin
            pkt_expected = this.pkts_expected.pop_front();

            while (pkt_expected.size() > 0) begin
                if (this.pkt_received.size() == 0) begin
                    s.printError(CLASS_NAME, $sformatf("Packet received %d is smaller than expected. %d bytes remain in expected queue.", this.stat_checked_pkts, pkt_expected.size()));
                    errorCount++;
                    break;
                end // endif

                received = this.pkt_received.pop_front();
                expected = pkt_expected.pop_front();

                info_string = $sformatf("Packet:%d, Byte:%d", this.stat_checked_pkts, byte_index);
                // s.checkSig(CLASS_NAME, ERRLEVEL_ERROR, info_string, received, expected, 0);
                errorCount += (received != expected);

                byte_index++;
            end // endwhile

            if (this.pkt_received.size() > 0) begin
                s.printError(CLASS_NAME, $sformatf("Packet received %d is larger than expected. %d bytes remain in received queue.", this.stat_checked_pkts, this.pkt_received.size()));
                // clear queue for next packet
                this.pkt_received.delete();
                errorCount++;
            end // endif
        end // endelse

        if (errorCount == 0) begin
            s.printPass(CLASS_NAME, $sformatf("Packet %d was successfully received!", this.stat_checked_pkts));
        end // endif

        this.stat_checked_pkts++;
    endtask : tCheckPacket

    //------------------------------------------------------------------------------
    // Drivers
    //------------------------------------------------------------------------------
    // drive tx transactions
    task automatic tDriveIfTx();
        // init to zeros
        tZeroIfTx();
        while (GEN_PKTS) begin // run forever
            tWaitForQueuedPkt();
            tTransmitPkt();
        end // endwhile
    endtask : tDriveIfTx
    // capture tx transactions
    task automatic tDriveExpected();
        while (CHECK_PKTS) begin // run forever
            tWaitForTransactionTx();
            tCaptureExpected();
        end // endwhile
    endtask : tDriveExpected
    // capture rx transactions & initiate checks on expected versus received
    task automatic tDriveReceived();
        // init to zero (if bfm has control)
        if (CONTROL_RX_TREADY) begin
            tZeroIfRx();
        end // endif
        while (CHECK_PKTS) begin // run forever
            if (CONTROL_RX_TREADY) begin
                tDoTreadyPushback();
            end // endif
            tWaitForTransactionRx();
            tCaptureReceived();
            if (this.io_rx.tlast) begin
                tCheckPacket();
            end // endif
        end // endwhile
    endtask : tDriveReceived

    //------------------------------------------------------------------------------
    // Helper Tasks
    //------------------------------------------------------------------------------
    // reset all controllable tx interface signals
    task automatic tZeroIfTx();
        this.io_tx.tvalid   <= '0;
        this.io_tx.tdata    <= '0;
        this.io_tx.tlast    <= '0;
        this.io_tx.tkeep    <= '0;
    endtask : tZeroIfTx

    // reset all controllable rx interface signals
    task automatic tZeroIfRx();
        this.io_rx.tready   <= '0;
    endtask : tZeroIfRx

    // advance tx clock if a packet is not queued
    task automatic tWaitForQueuedPkt();
        while($size(pkt_byte_len) == 0) begin
            tWaitClkTx();
        end // endwhile
    endtask : tWaitForQueuedPkt

    // advance tx clock until tx transaction occurs
    task automatic tWaitForTransactionTx();
        do begin
            tWaitClkTx();
        end while(!(this.io_tx.tvalid && this.io_tx.tready));
    endtask : tWaitForTransactionTx

    // advance rx clock until rx transaction occurs
    task automatic tWaitForTransactionRx();
        do begin
            tWaitClkRx();
        end while(!(this.io_rx.tvalid && this.io_rx.tready));
    endtask : tWaitForTransactionRx

    // wait a tx clock cycle
    task automatic tWaitClkTx();
        @(posedge this.io_tx.aclk);
    endtask : tWaitClkTx;

    // wait a rx clock cycle
    task automatic tWaitClkRx();
        @(posedge this.io_rx.aclk);
    endtask : tWaitClkRx;

    // // print a debug message with precise timing for ease of waveform viewing
    // task automatic tPrintDebugMessage(input string message);
    //     $display("%dps (%s): %s", $time, CLASS_NAME, message);
    // endtask : tPrintDebugMessage

endclass : fidus_axis_gen_bfm

endpackage : fidus_axis_gen_bfm_pkg
