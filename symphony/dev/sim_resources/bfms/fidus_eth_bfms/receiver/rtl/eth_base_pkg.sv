//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_base_pkg.sv
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : Base package file for the Ethernet BFM.
//
//===================================================================

package eth_base_pkg;

parameter AXI_DATA_WIDTH = 8;

///////////////////////////////////
// Data Structures
///////////////////////////////////

typedef logic [7:0] cqid_t;

// Ethernet Header - 14 bytes.
typedef struct packed {
  logic [15:0] leng_type;
  logic [47:0] mac_sa;
  logic [47:0] mac_da;
} eth_hdr_t;

typedef enum logic [15:0] {
  IPV4_E = 16'h0800,
  ARP_E = 16'h0806
} ether_type_e;

typedef enum logic [7:0] {
  ICMP_E = 8'h1,
  IGMP_E = 8'h2,
  TCP_E = 8'h6,
  UDP_E = 8'h11
} ipv4_proto_e;

////////////////////////
// Internet layer
////////////////////////

// IPv4 Header - 20 bytes.
typedef struct packed {
  logic [31:0] da;
  logic [31:0] sa;
  logic [15:0] chksum;
  ipv4_proto_e proto;
  logic [7:0] ttl;
  logic [12:0] frag;
  logic [2:0] flags;
  logic [15:0] id;
  logic [15:0] leng;
  logic [1:0] ecn;
  logic [5:0] dscp;
  logic [3:0] ihl;
  logic [3:0] version;
} ipv4_hdr_t;

typedef struct packed {
  ipv4_hdr_t ipv4_hdr;
  eth_hdr_t eth_hdr;
} ipv4_pkt_t;

// ARP Packet - 28 + 10 padding bytes.
typedef struct packed {
  logic [79:0] pad;
  logic [31:0] tpa;
  logic [47:0] tha;
  logic [31:0] spa;
  logic [47:0] sha;
  logic [15:0] oper;
  logic [7:0] plen;
  logic [7:0] hlen;
  logic [15:0] ptype;
  logic [15:0] htype;
} arp_t;

typedef struct packed {
  arp_t arp;
  eth_hdr_t eth_hdr;
} arp_pkt_t;

////////////////////////
// Transport layer
////////////////////////

// UDP Datagram
typedef struct packed {
  logic [15:0] chksum;
  logic [15:0] leng;
  logic [15:0] dest_port;
  logic [15:0] src_port;
} udp_t;

// TCP Flags
typedef struct packed {
  logic fin;
  logic syn;
  logic rst;
  logic psh;
  logic ack;
  logic urg;
  logic ece;
  logic cwr;
} tcp_flags_t;

// TCP Datagram
typedef struct packed {
  logic [15:0] urg_ptr;
  logic [15:0] chksum;
  logic [15:0] win_size;
  tcp_flags_t flags;
  logic [3:0] rsvd;
  logic [3:0] offset;
  logic [31:0] ack_num;
  logic [31:0] sequ_num;
  logic [15:0] dest_port;
  logic [15:0] src_port;
} tcp_t;


endpackage
