//------------------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project      : fidus axis etg bfm
// Author       : Xianxin Du
// Created      : 2021-06-08
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Description  : Package for handling pcap (tcpdump/wireshark) files.
//                https://wiki.wireshark.org/Development/LibpcapFileFormat
//                Functions/Tasks:
//                  fOpenNewPacketCaptureFile - create/replace a file for writing
//                  fWritePacketCaptureFile - write a packet to file
//                  fClosePacketCaptureFile - close file
//                  fOpenReadPacketCaptureFile - open a file for reading
//                  tReadPacketCaptureFile - read the next packet from file
// Updated      : yyyy-mm-dd / author - comments
//------------------------------------------------------------------------------

package fidus_axis_etg_pcap_pkg;

    //----------------------------------------------------------------------------------------------
    // Opens a new pcap file in write mode for recording. The libpcap header (with ns precision
    // timestamps) is written to prepare for capture.
    //
    // Arg - file   : filepath for the file to be created. (eg. "../etg_packet.pcap")
    // Return : file handle integer
    //----------------------------------------------------------------------------------------------
    function automatic int fOpenNewPacketCaptureFile(string file);
        int fd = $fopen(file, "wb");
        if (fd) begin
            // PCAP header
            // $fwrite(fd, "%u", 32'hA1B2C3D4);    // magic number
            $fwrite(fd, "%u", 32'hA1B23C4D);    // magic number (ns accuracy ver)
            $fwrite(fd, "%u", 32'h00040002);    // version_major, version_minor
            $fwrite(fd, "%u", 32'h00000000);    // thiszone
            $fwrite(fd, "%u", 32'h00000000);    // sigfigs
            $fwrite(fd, "%u", 32'h0000FFFF);    // snaplen = 65535 bytes max
            $fwrite(fd, "%u", 32'h00000001);    // network = 1 (eth)
        end
        return fd;
    endfunction : fOpenNewPacketCaptureFile

    //----------------------------------------------------------------------------------------------
    // Write a packet into an opened file.
    //
    // Arg - fd         : File handle integer of opened file.
    // Arg - data       : Byte array of packet data to be written.
    // Arg - custom_ts  : Optional flag to enable custom packet timestamp.
    // Arg - ts_s       : Optional custom packet timestamp (seconds field).
    // Arg - ts_ns      : Optional custom packet timestamp (nanoseconds field).
    // Return : number of bytes written (including record header, so data.size() + 16)
    //----------------------------------------------------------------------------------------------
    function int fWritePacketCaptureFile(
        int         fd,
        bit[ 7:0]   data[],
        bit         custom_ts = 0,
        bit[31:0]   ts_s      = '0,
        bit[31:0]   ts_ns     = '0
    );
        longint unsigned pkt_time_ns;
        longint unsigned pkt_time_s;
        // assuming ns timescale
        pkt_time_ns = $time;
        pkt_time_s  = pkt_time_ns / 1000000000;
        pkt_time_ns = pkt_time_ns - pkt_time_s * 1000000000;
        // $display("Time: %d, %d", pkt_time_s, pkt_time_ns);

        if (fd) begin
            // Record (Packet) Header
            $fwrite(fd, "%u", custom_ts ? ts_s  : 32'(pkt_time_s ));    // ts_sec
            $fwrite(fd, "%u", custom_ts ? ts_ns : 32'(pkt_time_ns));    // ts_usec (ns)
            $fwrite(fd, "%u", 32'(data.size()));    // incl_len
            $fwrite(fd, "%u", 32'(data.size()));    // orig_len
            // Packet Data
            for (int i=0; i<data.size(); i++) begin
                $fwrite(fd, "%c", data[i]);
            end
            return data.size() + 16;
        end
        return 0;
    endfunction : fWritePacketCaptureFile

    //----------------------------------------------------------------------------------------------
    // Close an opened file.
    // 
    // Arg - fd : File handle integer of opened file.
    //----------------------------------------------------------------------------------------------
    function void fClosePacketCaptureFile(int fd);
        if (fd) $fclose(fd);
    endfunction : fClosePacketCaptureFile


    //----------------------------------------------------------------------------------------------
    // Opens an existing pcap file in read mode. Checks the magic number and skips the header.
    //
    // Arg - file   : filepath for the file to be read. (eg. "../etg_packet.pcap")
    // Return : file handle integer
    //----------------------------------------------------------------------------------------------
    function automatic int fOpenReadPacketCaptureFile(string file);
        int err;
        bit[31:0] magic_number;
        bit[31:0] version;
        bit[31:0] thiszone;
        bit[31:0] sigfigs;
        bit[31:0] snaplen;
        bit[31:0] network;
        int fd = $fopen(file, "rb");
        if (fd) begin
            // PCAP header
            err = $fscanf(fd, "%u%u%u%u%u%u", magic_number, version, thiszone, sigfigs, snaplen, network);
            if (err != 6) begin
                $display("Error reading pcap header! err = %d", err);
                $fclose(fd);
                return 0;
            end
            if (magic_number != 32'hA1B23C4D && magic_number != 32'hA1B2C3D4) begin
                $display("Error wrong pcap magic number! (%h)", magic_number);
                $fclose(fd);
                return 0;
            end
        end
        return fd;
    endfunction : fOpenReadPacketCaptureFile


    task automatic tReadPacketCaptureFile(
        input  int          fd,
        output bit          success,
        output bit [ 7:0]   data[],
        output bit [31:0]   ts_s,
        output bit [31:0]   ts_ns
    );
        int err;
        bit[7:0]    readdata[];
        bit[31:0]   pkt_time_s = 0;
        bit[31:0]   pkt_time_ns = 0;
        bit[31:0]   incl_len;
        bit[31:0]   orig_len;

        if (fd) begin
            // Read (Packet) Header
            err = $fscanf(fd, "%u%u%u%u", pkt_time_s, pkt_time_ns, incl_len, orig_len);
            if (err == 4) begin
                readdata = new[incl_len];
                for (int i=0; i<incl_len; i++) begin
                    err = $fscanf(fd, "%c", readdata[i]);
                    if (err != 1) begin
                        success = 0;
                        return;
                    end
                end
            end

            success = 1;
            data  = readdata;
            ts_s  = pkt_time_s;
            ts_ns = pkt_time_ns;
            return;
        end
        // zero data
        readdata = new[64];
        success = 0;
        data  = readdata;
        ts_s  = pkt_time_s;
        ts_ns = pkt_time_ns;
    endtask : tReadPacketCaptureFile

endpackage
