//==========================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_packet.svh
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Defines the packet class
//               Generates random fields for transmitting various 
//               packet types.
//               Extracts and prints packet fields for received packets.
//
//=========================================================================

class eth_packet_c;

  rand bit [47:0] src_addr;
  rand bit [47:0] dst_addr;

  rand bit [15:0] pkt_leng;
  rand bit [15:0] leng_type;

  rand ipv4_hdr_t ipv4_hdr;
  rand ipv4_proto_e ipv4_proto;
  logic [$bits(ipv4_hdr_t)-1:0] ipv4_hdr_bits;
  ipv4_pkt_t ipv4_pkt;

  rand arp_t arp;
  rand arp_pkt_t arp_pkt;
  logic [$bits(arp_t)-1:0] arp_bits;

  rand udp_t udp;
  logic [$bits(udp_t)-1:0] udp_bits;

  rand tcp_t tcp;
  logic [$bits(tcp_t)-1:0] tcp_bits;

  int pkt_size_bytes;
  rand byte pkt_data[$];
  byte pkt_full[$];

  // MAC src and dest.
  constraint addr_c {
    src_addr inside {'hABCD, 'hBEEF};
    dst_addr inside {'hABCD, 'hBEEF};
  }

  // Ether Type.
  constraint leng_type_c {
    leng_type inside {IPV4_E,
                      ARP_E
                     };
  }

  // Packet length in bytes, not including ethernet header of 14 bytes.
  // min 64-14, max 1500-14
  constraint pkt_leng_c {
    if (leng_type == ARP_E)
      pkt_leng == 38;
    else
      pkt_leng inside {[400:460]};
  }

  constraint pkt_data_c {
    pkt_data.size() == pkt_leng;
  }

  // IPV4 protocol.
  constraint v4_proto_c {
    ipv4_proto inside {ICMP_E,
                       IGMP_E,
                       TCP_E,
                       UDP_E
                      };
  }

  function new(string from_file, byte data[$]);
    if (from_file == "true")
      pkt_data = data;
  endfunction
 
  function void build_custom_random();
    fill_pkt_data();
    post_randomize();
  endfunction
 
  function void fill_pkt_data();
    for(int i=0; i < pkt_leng; i++) begin
      pkt_data.push_back($urandom());
    end
  endfunction

  function void fill_pkt_from_file();
    pkt_size_bytes = pkt_data.size();
    $display("Generating packet from file with length: %0d",pkt_size_bytes);
    // MAC DA
    for(int i=0; i < 6; i++) begin
      pkt_full.push_back(dst_addr >> i*8);
    end
    // MAC SA
    for(int i=0; i < 6; i++) begin
      pkt_full.push_back(src_addr >> i*8);
    end
    // Leng/Type
    for(int i=0; i < 2; i++) begin
      pkt_full.push_back(IPV4_E >> i*8);
    end
    for(int i=0; i < pkt_size_bytes; i++) begin
      pkt_full.push_back(pkt_data[i]);
    end
  endfunction

  function void post_randomize();
    // Used by driver to determine overall packet size.
    pkt_size_bytes = pkt_leng + 6+6+2; // data byes + 6B src + 6B dest + 2B Type
    // MAC DA
    for(int i=0; i < 6; i++) begin
      pkt_full.push_back(dst_addr >> i*8);
    end
    // MAC SA
    for(int i=0; i < 6; i++) begin
      pkt_full.push_back(src_addr >> i*8);
    end
    // Leng/Type
    for(int i=0; i < 2; i++) begin
      pkt_full.push_back(leng_type >> i*8);
    end
    // Payload
    if (leng_type == IPV4_E) begin
      // IPv4 header - 20 bytes
      ipv4_hdr = 0;
      ipv4_hdr.version = 4;
      ipv4_hdr.proto = ipv4_proto;
      ipv4_hdr.sa = 'haa;
      ipv4_hdr.da = 'hda;

      ipv4_hdr_bits = ipv4_hdr;
//      $display(" IP hdr: 0x%x",ipv4_hdr_bits);
      for(int i=0; i < 20; i++) begin
//        $display("%x",ipv4_hdr_bits[i*8+:8]);
        pkt_full.push_back(ipv4_hdr_bits[i*8+:8]);
      end
 
      // Transport layer
      if (ipv4_proto == UDP_E) begin
        // UDP datagram hdr - 8 bytes
        udp = 0;
        udp.src_port = 2100;
        udp.dest_port = 2020;
        udp.leng = pkt_leng - 20;
        udp.chksum = 0;

        udp_bits = udp;
        for(int i=0; i < 8; i++) begin
          pkt_full.push_back(udp_bits[i*8+:8]);
        end
        // Packet data.
        for(int i=28; i < pkt_leng; i++) begin
          pkt_full.push_back(pkt_data[i]);
        end
      end
      else if (ipv4_proto == TCP_E) begin
        // TCP datagram hdr - 20 bytes
        tcp = 0;
        tcp.src_port = 2020;
        tcp.dest_port = 2100;
        tcp.sequ_num = 5;
        tcp.ack_num = 4;
        tcp.offset = 0;
        tcp.rsvd = 0;
        tcp.flags = 'b10101010;
        tcp.win_size = 256;
        tcp.chksum = 'haaaa;
        tcp.urg_ptr = 128;

        tcp_bits = tcp;
//        $display(" TCP hdr: 0x%x",tcp_bits);
        for(int i=0; i < 20; i++) begin
//          $display("%x",tcp_bits[i*8+:8]);
          pkt_full.push_back(tcp_bits[i*8+:8]);
        end
        // Random packet data.
        for(int i=40; i < pkt_leng; i++) begin
          pkt_full.push_back(pkt_data[i]);
        end
      end
      else begin
        // Random packet data.
        for(int i=20; i < pkt_leng; i++) begin
          pkt_full.push_back(pkt_data[i]);
        end
      end
 
    end
    else if (leng_type == ARP_E) begin
      // ARP packet - 28 + 10 padding bytes
      arp = 0;
      arp.htype = 1;
      arp.ptype = 'h0800;
      arp.hlen = 6;
      arp.plen = 4;
      arp.oper = 1;
      arp.sha = 'haa;
      arp.spa = 'hda;
      arp.tha = 0;
      arp.tpa = 'hdadda;
 
      arp_bits = arp;
      for(int i=0; i < 38; i++) begin
        pkt_full.push_back(arp_bits[i*8+:8]);
      end
    end
    else begin
      // Random packet data.
      for(int i=2; i < pkt_leng; i++) begin
        pkt_full.push_back(pkt_data[i]);
      end
    end
  endfunction

  function void extract_fields();
    // Extract ethernet fields from a received packet.
    // MAC DA
    for(int i=0; i < 6; i++) begin
      dst_addr[i*8+:8] = pkt_data[i];
    end
    // MAC SA
    for(int i=0; i < 6; i++) begin
      src_addr[i*8+:8] = pkt_data[i+6];
    end
    // Leng/Type
    for(int i=0; i < 2; i++) begin
      leng_type[i*8+:8] = pkt_data[i+12];
    end
    // Payload
    // IPv4 header - 20 bytes
    for (int i=0; i<34; i++) begin
      ipv4_pkt[i*8+:8] = pkt_data[i];
    end
    if (ipv4_pkt.ipv4_hdr.proto == UDP_E) begin
      // UDP header - 8 bytes
      for (int i=34; i<42; i++) begin
        udp[(i-34)*8+:8] = pkt_data[i];
      end
    end
    if (ipv4_pkt.ipv4_hdr.proto == TCP_E) begin
      // TCP header - 20 bytes
      for (int i=34; i<54; i++) begin
        tcp[(i-34)*8+:8] = pkt_data[i];
      end
    end
 
    // ARP packet - 38 bytes + 14 bytes eth hdr.
    for (int i=0; i<52; i++) begin
      arp_pkt[i*8+:8] = pkt_data[i];
    end
  endfunction
 
  // Return a string that prints ethernet header fields
  function string to_string();
    string msg;
    msg = $psprintf(" mac_sa=0x%x mac_da=0x%x lt=0x%x",src_addr,dst_addr,leng_type);
    return msg;
  endfunction

  // Return a string that prints IP header fields
  function string ip_to_string();
    string msg;
    string protocol;
    string datagram;
    case (ipv4_pkt.ipv4_hdr.proto)
      ICMP_E: protocol = "ICMP";
      IGMP_E: protocol = "IGMP";
      TCP_E: protocol = "TCP";
      UDP_E: protocol = "UDP";
      default: protocol = "Unknown";
    endcase
    msg = $sformatf("\n---------------------------------------------------------\n",
                    " lt = 0x%x\n", ipv4_pkt.eth_hdr.leng_type,
                    " version = 0x%x\n", ipv4_pkt.ipv4_hdr.version,
                    " ihl = 0x%x\n", ipv4_pkt.ipv4_hdr.ihl,
                    " dscp = 0x%x\n", ipv4_pkt.ipv4_hdr.dscp,
                    " ecn = 0x%x\n", ipv4_pkt.ipv4_hdr.ecn,
                    " leng = 0x%x\n", ipv4_pkt.ipv4_hdr.leng,
                    " id = 0x%x\n", ipv4_pkt.ipv4_hdr.id,
                    " flags = 0x%x\n", ipv4_pkt.ipv4_hdr.flags,
                    " frag = 0x%x\n", ipv4_pkt.ipv4_hdr.frag,
                    " ttl = 0x%x\n", ipv4_pkt.ipv4_hdr.ttl,
                    " protocol = %0s\n", protocol,
                    " chksum = 0x%x\n", ipv4_pkt.ipv4_hdr.chksum,
                    " sa = 0x%x\n", ipv4_pkt.ipv4_hdr.sa,
                    " da = 0x%x\n", ipv4_pkt.ipv4_hdr.da,
                    "---------------------------------------------------------\n"
                    );
 
    if (ipv4_pkt.ipv4_hdr.proto == UDP_E) begin
      datagram = $sformatf(" UDP Datagram:\n",
                    " src_port = %d\n", udp.src_port,
                    " dest_port = %d\n", udp.dest_port,
                    " leng = 0x%x\n", udp.leng,
                    " chksum = 0x%x\n", udp.chksum,
                    "---------------------------------------------------------\n"
                    );
      msg = {msg, datagram};
    end
 
    if (ipv4_pkt.ipv4_hdr.proto == TCP_E) begin
      datagram = $sformatf(" TCP Datagram:\n",
                    " src_port = %d\n", tcp.src_port,
                    " dest_port = %d\n", tcp.dest_port,
                    " sequ_num = 0x%x\n", tcp.sequ_num,
                    " ack_num = 0x%x\n", tcp.ack_num,
                    " offset = 0x%x\n", tcp.offset,
                    " rsvd = 0x%x\n", tcp.rsvd,
                    " flags = 0x%x\n", tcp.flags,
                    " win_size = 0x%x\n", tcp.win_size,
                    " chksum = 0x%x\n", tcp.chksum,
                    " urg_ptr = 0x%x\n", tcp.urg_ptr,
                    "---------------------------------------------------------\n"
                    );
      msg = {msg, datagram};
    end
 
    return msg;
  endfunction
 
  // Return a string that prints ARP fields
  function string arp_to_string();
    string msg;
    msg = $sformatf("\n---------------------------------------------------------\n",
                    " lt = 0x%x\n", arp_pkt.eth_hdr.leng_type,
                    " htype = 0x%x\n", arp_pkt.arp.htype,
                    " ptype = 0x%x\n", arp_pkt.arp.ptype,
                    " hlen = 0x%x\n", arp_pkt.arp.hlen,
                    " plen = 0x%x\n", arp_pkt.arp.plen,
                    " oper = 0x%x\n", arp_pkt.arp.oper,
                    " sha = 0x%x\n", arp_pkt.arp.sha,
                    " spa = 0x%x\n", arp_pkt.arp.spa,
                    " tha = 0x%x\n", arp_pkt.arp.tha,
                    " tpa = 0x%x\n", arp_pkt.arp.tpa,
                    "---------------------------------------------------------\n"
                    );
    return msg;
  endfunction
 
  function bit compare_pkt(eth_packet_c pkt);
    return 1'b1;  //TBD
  endfunction

endclass : eth_packet_c
