//--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename    : axilite_reg_if.sv
// Project     : RIPL/SIMU
// Author      : Paul Roukema
// Created     : May 27, 2021
// Description : AXILITE to register block converter
//
//--------------------------------------------------------------------//


module axilite_reg_if #(
    parameter REG_INDEX_WIDTH = 16,
    parameter RD_LATENCY      = 1
) (
    input  wire                        s_axi_aclk,
    input  wire                        s_axi_aresetn,

    input  wire  [               31:0] s_axi_awaddr,
    input  wire  [                2:0] s_axi_awprot,
    input  wire                        s_axi_awvalid,
    output reg                         s_axi_awready,

    input  wire  [               31:0] s_axi_wdata,
    input  wire  [                3:0] s_axi_wstrb,
    input  wire                        s_axi_wvalid,
    output reg                         s_axi_wready,

    output reg                         s_axi_bvalid,
    output reg   [                1:0] s_axi_bresp,
    input  wire                        s_axi_bready,
    input  wire  [               31:0] s_axi_araddr,
    input  wire  [                2:0] s_axi_arprot,
    input  wire                        s_axi_arvalid,
    output reg                         s_axi_arready,

    output reg                         s_axi_rvalid,
    output reg   [               31:0] s_axi_rdata,
    output reg   [                1:0] s_axi_rresp,
    input  wire                        s_axi_rready,

    output logic                       wr_en,
    output logic [REG_INDEX_WIDTH-1:0] wr_idx,
    output logic [               31:0] wr_data,
    output logic [                3:0] wr_strb,

    output logic                       rd_en,
    output logic [REG_INDEX_WIDTH-1:0] rd_idx,
    input  logic [               31:0] rd_data
);

    localparam [1:0] RESP_OKAY = 2'b00;

    logic [RD_LATENCY-1:0] rd_dly;
    logic                  aw_pending;
    logic                  w_pending;

    always_ff @( posedge s_axi_aclk )
        begin : ar_channel
            if (!s_axi_aresetn)
                begin
                    rd_en         <= 1'b0;
                    rd_idx        <= '0;
                    s_axi_arready <= 1'b0;
                end
            else
                begin
                    rd_en     <= 1'b0;
                    rd_dly[0] <= 1'b0;

                    s_axi_arready <= 1'b1;
                    if( |rd_dly || (s_axi_rvalid && ~s_axi_rready))
                        s_axi_arready <= 1'b0;

                    if (RD_LATENCY > 1)
                        rd_dly[RD_LATENCY-1:1] <= rd_dly[RD_LATENCY-2 : 0];

                    if (s_axi_arvalid  && s_axi_arready)
                        begin
                            rd_en         <= 1'b1;
                            rd_idx        <= s_axi_araddr[REG_INDEX_WIDTH-1+2 : 2];
                            rd_dly[0]     <= 1'b1;
                            s_axi_arready <= 1'b0;
                        end
                end
        end

    always_ff @(posedge s_axi_aclk )
        begin : r_channel
            s_axi_rresp <= RESP_OKAY;
            if (!s_axi_aresetn)
                begin
                    s_axi_rvalid <= 1'b0;
                end
            else
                begin
                    if(s_axi_rready)
                        s_axi_rvalid <= 1'b0;

                    if(rd_dly[RD_LATENCY-1])
                        begin
                            s_axi_rdata  <= rd_data;
                            s_axi_rvalid <= 1'b1;
                        end
                end
        end


    always_ff @( posedge s_axi_aclk )
        begin : aw_channel
            if (!s_axi_aresetn)
                begin
                    aw_pending    <= 1'b0;
                    s_axi_awready <= 1'b0;
                end
            else
                begin
                    if (s_axi_bvalid && s_axi_bready)
                        aw_pending <= 1'b0;
                    if (~aw_pending)
                        s_axi_awready <= 1'b1;

                    if (s_axi_awvalid && s_axi_awready)
                        begin
                            wr_idx        <= s_axi_awaddr[REG_INDEX_WIDTH-1+2 : 2];
                            aw_pending    <= 1'b1;
                            s_axi_awready <= 1'b0;
                        end
                end
        end

    always_ff @( posedge s_axi_aclk )
        begin : w_channel
            if (!s_axi_aresetn)
                begin
                    w_pending    <= 1'b0;
                    s_axi_wready <= 1'b0;
                end
            else
                begin
                    if (s_axi_bvalid && s_axi_bready)
                        w_pending <= 1'b0;
                    if (~w_pending)
                        s_axi_wready <= 1'b1;

                    if (s_axi_wvalid && s_axi_wready)
                        begin
                            wr_data      <= s_axi_wdata;
                            wr_strb      <= s_axi_wstrb;
                            w_pending    <= 1'b1;
                            s_axi_wready <= 1'b0;
                        end
                end
        end

    always_ff @( posedge s_axi_aclk )
        begin : b_channel
            s_axi_bresp <= RESP_OKAY;
            if (!s_axi_aresetn)
                begin
                    s_axi_bvalid <= 1'b0;
                end
            else
                begin
                    wr_en <= 1'b0;
                    if (s_axi_bvalid && s_axi_bready)
                        s_axi_bvalid <= 1'b0;

                    if ( ~s_axi_bvalid && aw_pending && w_pending)
                        begin
                            wr_en        <= 1'b1;
                            s_axi_bvalid <= 1'b1;
                        end
                end
        end

endmodule
