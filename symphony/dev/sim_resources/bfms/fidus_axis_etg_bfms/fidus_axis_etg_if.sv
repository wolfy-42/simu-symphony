/*------------------------------------------------------------------------------
// Title         : Ethernet packet generator 
// Project       : Ethernet packet generator BFM 
//------------------------------------------------------------------------------
// File          : fidus_axis_etg_if.sv
// Author        : Bassem Sleiman 
// Created       : 22/04/2020
//------------------------------------------------------------------------------
// Description   : This module is an interface of AXI4-stream Ethernet Traffic
//                 Generator.
//----------------------------------------------------------------------------*/

interface fidus_axis_etg_if #(
        parameter TDATA_WIDTH = 32,
        parameter TUSER_WIDTH = 8,
        parameter TKEEP_WIDTH = TDATA_WIDTH/8
    )(
        input logic         aclk,
        input logic         aresetn
    );
    logic                   tready;
    logic                   tvalid;
    logic [TDATA_WIDTH-1:0] tdata;
    logic [TUSER_WIDTH-1:0] tuser;
    logic                   tlast;
    logic [TKEEP_WIDTH-1:0] tkeep;

    modport ETG (
        output tvalid, tdata, tuser, tlast,
        input  tready, aclk, aresetn
    );
endinterface: fidus_axis_etg_if
