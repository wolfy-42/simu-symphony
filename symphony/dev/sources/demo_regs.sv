//--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename    : demo_regs.sv
// Project     : RIPL/SIMU
// Author      : Paul Roukema
// Created     : May 27, 2021
// Description : Simple demo register map
//
//--------------------------------------------------------------------//

module demo_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [31:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    output reg         s_axi_bvalid,
    output reg  [ 1:0] s_axi_bresp,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    output reg         s_axi_rvalid,
    output reg  [31:0] s_axi_rdata,
    output reg  [ 1:0] s_axi_rresp,
    input  wire        s_axi_rready
);

    localparam REG_INDEX_WIDTH = 4;
    localparam ADDR_SCRATCH    = 0;
    localparam ADDR_FLAG       = 1;


    wire                       rd_en;
    wire [REG_INDEX_WIDTH-1:0] rd_idx;
    reg  [               31:0] rd_data;

    wire                       wr_en;
    wire [REG_INDEX_WIDTH-1:0] wr_idx;
    wire [               31:0] wr_data;
    wire [                3:0] wr_strb;

    reg [31:0] reg_scratch;
    reg        reg_flag;

    axilite_reg_if #(.REG_INDEX_WIDTH(REG_INDEX_WIDTH), .RD_LATENCY(1)) reg_if_inst (
        .s_axi_aclk   (s_axi_aclk   ),
        .s_axi_aresetn(s_axi_aresetn),
        .s_axi_awaddr (s_axi_awaddr ),
        .s_axi_awprot (s_axi_awprot ),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata  (s_axi_wdata  ),
        .s_axi_wstrb  (s_axi_wstrb  ),
        .s_axi_wvalid (s_axi_wvalid ),
        .s_axi_wready (s_axi_wready ),
        .s_axi_bvalid (s_axi_bvalid ),
        .s_axi_bresp  (s_axi_bresp  ),
        .s_axi_bready (s_axi_bready ),
        .s_axi_araddr (s_axi_araddr ),
        .s_axi_arprot (s_axi_arprot ),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rvalid (s_axi_rvalid ),
        .s_axi_rdata  (s_axi_rdata  ),
        .s_axi_rresp  (s_axi_rresp  ),
        .s_axi_rready (s_axi_rready ),

        .wr_en        (wr_en        ),
        .wr_idx       (wr_idx       ),
        .wr_data      (wr_data      ),
        .wr_strb      (wr_strb      ),

        .rd_en        (rd_en        ),
        .rd_idx       (rd_idx       ),
        .rd_data      (rd_data      )
    );

    always_ff @( posedge s_axi_aclk )
        begin : p_reg_write
            if(!s_axi_aresetn)
                begin
                    reg_flag    <= 1'b0;
                    reg_scratch <= 32'h12345678;
                end
            else
                begin
                    case(wr_idx)
                        ADDR_SCRATCH :
                            reg_scratch <= wr_data;
                        ADDR_FLAG :
                            begin
                                if (wr_data[0])
                                    reg_flag <= 1'b1;
                                if (wr_data[1])
                                    reg_flag <= 1'b0;
                            end
                    endcase
                end
        end

    always_comb
        begin
            case(rd_idx)
                ADDR_SCRATCH :
                    rd_data = reg_scratch;
                ADDR_FLAG :
                    begin
                        rd_data    = '0;
                        rd_data[0] = reg_flag;
                    end
                default :
                    rd_data = '0;
            endcase
        end

endmodule

