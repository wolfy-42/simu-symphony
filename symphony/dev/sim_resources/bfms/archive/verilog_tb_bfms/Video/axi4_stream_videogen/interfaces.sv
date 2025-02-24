//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project     : SIMU
// Author      : Jacob von Chorus
// Created     : June 26, 2018
// Description : SystemVerilog Interfaces for AXI4-Stream Video
//---------------------------------------------------------------------------//

interface axi4s_if #(
        parameter TDATA_WIDTH = 32
    )(
        input logic         aclk,
        input logic         aresetn
    );
    logic                   tready;
    logic                   tvalid;
    logic [TDATA_WIDTH-1:0] tdata;
    logic [            0:0] tuser;   // sof (start of frame)
    logic                   tlast;   // eol (end of line)

    modport sink (
        input tvalid, tdata, tuser, tlast, aclk, aresetn,
        output tready
    );
    modport source (
        output tvalid, tdata, tuser, tlast,
        input  tready, aclk, aresetn
    );
endinterface: axi4s_if

