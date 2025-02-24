//--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Paul Roukema
// Created       : 2021-05-17
//--------------------------------------------------------------------//


module dut (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [31:0] s_axi_awaddr,
    input  wire [ 7:0] s_axi_awlen,
    input  wire [ 2:0] s_axi_awsize,
    input  wire [ 1:0] s_axi_awburst,
    input  wire [ 1:0] s_axi_awlock,
    input  wire [ 3:0] s_axi_awcache,
    input  wire [ 2:0] s_axi_awprot,
    input  wire [ 3:0] s_axi_awregion,
    input  wire [ 3:0] s_axi_awqos,
    input  wire        s_axi_awvalid,

    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wlast,
    input  wire        s_axi_wvalid,

    input  wire        s_axi_bready,

    input  wire [31:0] s_axi_araddr,
    input  wire [ 7:0] s_axi_arlen,
    input  wire [ 2:0] s_axi_arsize,
    input  wire [ 1:0] s_axi_arburst,
    input  wire [ 1:0] s_axi_arlock,
    input  wire [ 3:0] s_axi_arcache,
    input  wire [ 2:0] s_axi_arprot,
    input  wire [ 3:0] s_axi_arregion,
    input  wire [ 3:0] s_axi_arqos,
    input  wire        s_axi_arvalid,

    input  wire        s_axi_rready,

    output reg         s_axi_awready,
    output reg         s_axi_wready,
    output reg         s_axi_arready,

    output reg         s_axi_rlast,
    output reg         s_axi_rvalid,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,

    output reg         s_axi_bvalid,
    output reg  [1:0] s_axi_bresp
);

    reg [7:0] b_count;

    // Ready signal gen.
    always @(posedge s_axi_aclk)
        begin
            if (~s_axi_aresetn)
                begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b0;
                    s_axi_arready <= 1'b0;
                end
            else
                begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    s_axi_arready <= 1'b1;
                end;
        end

    // Rvalid signal generation.
    always @(posedge s_axi_aclk)
        begin
            if (~s_axi_aresetn)
                begin
                    s_axi_rvalid <= 1'b0;
                    s_axi_rlast  <= 1'b0;
                    s_axi_rresp  <= 2'b0;
                    s_axi_rdata  <=32'h12345678;
                    b_count      <= 3'b000;
                end
            else
                begin
                    if (s_axi_arvalid && ~s_axi_rvalid)
                        begin
                            s_axi_rvalid <= 1'b1;
                            s_axi_rlast  <= 1'b0;
                            b_count      <= 3'b000;
                        end
                    else if (s_axi_rready && s_axi_rvalid && b_count < 3'h6)
                        begin
                            s_axi_rvalid <= 1'b1;
                            s_axi_rlast  <= 1'b0;
                            s_axi_rdata  <= s_axi_rdata+1;
                            b_count      <= b_count + 1'b1;
                        end
                    else if (s_axi_rready && s_axi_rvalid && b_count == 3'h6)
                        begin
                            s_axi_rvalid <= 1'b1;
                            s_axi_rlast  <= 1'b1;
                            s_axi_rdata  <= s_axi_rdata+1;
                            b_count      <= b_count + 1'b1;
                        end
                    else if (s_axi_rready && s_axi_rvalid && s_axi_rlast)
                        begin
                            s_axi_rvalid <= 1'b0;
                            s_axi_rlast  <= 1'b0;
                            b_count      <= 3'b000;
                        end
                end
        end

    // Bvalid signal generation.
    always @(posedge s_axi_aclk)
        begin
            if (~s_axi_aresetn)
                begin
                    s_axi_bvalid <= 1'b0;
                    s_axi_bresp  <= 2'b00;
                end
            else
                begin
                    if (s_axi_wvalid && ~s_axi_bvalid && s_axi_wlast)
                        begin
                            s_axi_bvalid <= 1'b1;
                        end
                    else if (s_axi_bready && s_axi_bvalid)
                        begin
                            s_axi_bvalid <= 1'b0;
                        end
                    else
                        begin
                            s_axi_bvalid <= s_axi_bvalid;
                        end
                end
        end

endmodule
