//===================================================================
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename : eth_bfm_axi_pkg.sv
//
// Project : Ethernet BFM
// Author : Bryan Piotto
// Created : 15/05/2023
//
// Description : AXI package file for Ethernet BFM.
//
//===================================================================

package eth_bfm_axi_pkg;

parameter DATA_WIDTH = 512;
parameter ADDR_WIDTH = 64;

typedef logic [31:0] bus32_t;

// typedef enum logic [3:0] {ADD, SUB, ...} opcode_t;

///////////////////////////////////
// ATG Interface Specifics
///////////////////////////////////
typedef logic [4:0] opcode_t;

typedef struct packed {
  opcode_t opcode;
} axi4_user_t;

///////////////////////////////////
// AXI4 Interface
///////////////////////////////////

// Global Inputs
typedef struct packed {
  logic aclk;
  logic areset_n;
} axi4_global_t;

// Inputs for responder. Outputs for initiator.
typedef struct packed {
  logic awvalid;
  logic [ADDR_WIDTH-1:0] awaddr;
  logic [7:0] awid;
  logic [7:0] awlen;
  logic [2:0] awsize;
  logic [1:0] awburst;
  logic awlock;
  logic [3:0] awcache;
  logic [2:0] awprot;
  logic [3:0] awqos;
  logic wvalid;
  logic [DATA_WIDTH-1:0] wdata;
  logic [DATA_WIDTH/8-1:0] wstrb;
  logic wlast;
  logic bready;
  logic arvalid;
  logic [ADDR_WIDTH-1:0] araddr;
  logic [7:0] arid;
  logic [7:0] arlen;
  logic [2:0] arsize;
  logic [1:0] arburst;
  logic arlock;
  logic [3:0] arcache;
  logic [2:0] arprot;
  logic [3:0] arqos;  // not used by noc
  logic rready;
} axi4_rin_iout_t;

// Outputs for responder. Inputs for initiator.
typedef struct packed {
  logic awready;
  logic wready;
  logic bvalid;
  logic [7:0] bid;
  logic [1:0] bresp;
  logic arready;
  logic rvalid;
  logic [7:0] rid;
  logic [DATA_WIDTH-1:0] rdata;
  logic [1:0] rresp;
  logic rlast;
} axi4_rout_iin_t;

// Add user bits for ATG interface.
// Inputs for responder. Outputs for initiator.
typedef struct packed {
  axi4_rin_iout_t axi4_rin_iout;
  axi4_user_t axi4_awuser;
  axi4_user_t axi4_aruser;
} axi4_atg_rin_iout_t;

///////////////////////////////////
// AXI4-Lite Interface
// 32-bit address, 32-bit data
///////////////////////////////////
parameter AXILITE_DATA_WIDTH = 64;
parameter AXILITE_ADDR_WIDTH = 32;

// Global Inputs
typedef struct packed {
  logic aclk;
  logic areset;
} axi4lite_global_t;

// Inputs for responder. Outputs for initiator.
typedef struct packed {
  logic [0:0] awid;
  logic [AXILITE_ADDR_WIDTH-1:0] awaddr;
  logic [2:0] awprot;
  logic [3:0] awqos;
  logic awvalid;
  logic [AXILITE_DATA_WIDTH-1:0] wdata;
  logic [AXILITE_DATA_WIDTH/8-1:0] wstrb;
  logic wvalid;
  logic bready;
  logic [0:0] arid;
  logic [AXILITE_ADDR_WIDTH-1:0] araddr;
  logic [2:0] arprot;
  logic [3:0] arqos;
  logic arvalid;
  logic rready;
} axi4lite_rin_iout_t;

// Outputs for responder. Inputs for initiator.
typedef struct packed {
  logic awready;
  logic wready;
  logic [0:0] bid;
  logic [1:0] bresp;
  logic bvalid;
  logic arready;
  logic [0:0] rid;
  logic [AXILITE_DATA_WIDTH-1:0] rdata;
  logic [1:0] rresp;
  logic rvalid;
} axi4lite_rout_iin_t;

// BRESP values
typedef enum logic [1:0] {
  OKAY_E = 2'b00,
  EXOKAY_E = 2'b01,
  SLVERR_E = 2'b10,
  DECERR_E = 2'b11
} bresp_e;

///////////////////////////////////
// AXI4 Streaming Interface
///////////////////////////////////

parameter AXIS_DATA_WIDTH = 8;

// Global Inputs
typedef struct packed {
  logic clk;
  logic reset;
} axis_global_t;

typedef struct packed {
  logic sop;
} axis_user_t;

// Inputs for responder. Outputs for initiator.
typedef struct packed {
  logic tvalid;
  logic [AXIS_DATA_WIDTH-1:0] tdata;
  logic [AXIS_DATA_WIDTH/8-1:0] tkeep;
  logic tlast;
  logic tuser;
} axis_std_rin_iout_t;

typedef struct packed {
  axis_std_rin_iout_t std;
  axis_user_t tuser;
} axis_rin_iout_t;

// Outputs for responder. Inputs for initiator.
typedef struct packed {
  logic tready;
} axis_rout_iin_t;

endpackage
