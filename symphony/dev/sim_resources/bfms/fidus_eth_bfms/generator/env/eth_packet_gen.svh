//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_packet_gen.svh
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Packet generator class
//
//===================================================================

typedef eth_packet_c;
class eth_packet_gen_c;

  // Passed from the top testbench.
  int num_pkts;
  string packet_from_file;
  string packet_fnme;
  byte pkt_data[$];

  // Put generated packets into a mailbox to pass to the driver.
  mailbox mbx_out;

  function new(mailbox mbx, int pkts, string from_file, string fnme);
    mbx_out =  mbx;
    num_pkts = pkts;
    packet_from_file = from_file;
    packet_fnme = fnme;
  endfunction

  //Method
  task run;
    eth_packet_c pkt;
    integer fptr;  
    logic [15:0] pkt_leng;
    string byte_str;
    byte pkt_byte;
    int rc;

    if (packet_from_file == "true") begin
      // Read a packet data file
      fptr = $fopen(packet_fnme, "r");
      pkt_leng = 0;
      if (fptr) begin
        $display("Packet file opened.");
        while (!$feof(fptr)) begin
          rc = $fgets(byte_str, fptr);
          pkt_byte = byte_str.atohex();
          pkt_data.push_back(pkt_byte);
//          $display("Read 0x%x", pkt_byte);
          ++pkt_leng;
        end
        $fclose(fptr);  

        // Limited to a single packet in a file for now.
        // Need to come up with a standard file format for multiple packets.
        num_pkts = 1;
      end
      else
        $display("Packet file not opened successfully.");
    end

    for (int i=0; i < num_pkts; i++) begin

      pkt = new(packet_from_file, pkt_data);
      if (packet_from_file == "true") begin
        // Generate a packet from file data and put to mailbox
        pkt.fill_pkt_from_file();
      end
      else begin
        // Create packet, randomize and put to mailbox
        assert (pkt.randomize());
        pkt.build_custom_random();
      end

      mbx_out.put(pkt);
    end
  endtask

endclass
