//------------------------------------------------------------------------   
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//------------------------------------------------------------------------   
//File name   : bfm_spi_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : July 31st, 2012
//------------------------------------------------------------------------   
//Description : BFM for generic SPI bus master
//
// Datasheet: 
//------------------------------------------------------------------------   
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2012-08-21 10:31:19 $
//------------------------------------------------------------------------   


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`ifndef SIM
   `define SIM tb.sim_management_inst
`endif

  module bfm_spi_master
   #( parameter BFM_NAME             = "bfm_spi_master",
      parameter SPI_CLK_PERIOD       = 100,               // SPI SCL period (ns)
      parameter PAYLOAD_WIDTH        = 8,                 // # bits in payload section (read/write)
      parameter HEADER_WIDTH         = 8,                 // # bits in Header (includes all fields)
      parameter SPI_WR_POL           = 1'b0,              // polarity of write bit in SPI transaction
      parameter FREERUN_SCL_EN       = 1'b0,              // 0=gated, 1=freerunning o_SCL
      parameter SCL_IDLE_LVL         = 1'b1,              // default logic level if clock is gated
      parameter SILENT               = 0                  // if true, suppress `SIM.printMessage outputs
   )
   (
      output reg        o_scl = SCL_IDLE_LVL,             // clock output (
      input wire        i_sdi,                            // data in wire
      output reg        o_sdo = 1'b1,                     // data out wire
      output reg        o_sden = 1'b1                     // enable out (optional)
   );
   
//<> ------------------------------------------------------------------------   
//<> Module local parameters
//<> ------------------------------------------------------------------------   
   localparam FRAME_LEN   = (HEADER_WIDTH + PAYLOAD_WIDTH);   // 

//<> ------------------------------------------------------------------------   
//<> TYPE AND SIGNAL DECLARATIONS
//<> ------------------------------------------------------------------------   
   reg spi_clk_en = FREERUN_SCL_EN;     // gated clock control
   integer x;  // loop pointer

   //<> ---------------------------------------------------------------------------
   //<> Generic SPI bus Master (interface independant operation)
   //<>  - scalable input based on length of w_dat vector passed.
   //<>  - assumes gated clock controlled by f_*_spi_msg_xfer
   //<>  - MSbit out first
   //<> ---------------------------------------------------------------------------
   task spi_msg(  input  w_rn,
                  input  [HEADER_WIDTH-1:0] header,
                  input  [PAYLOAD_WIDTH-1:0]w_dat,
                  output [PAYLOAD_WIDTH-1:0]r_dat );
   begin
      if (w_rn > 1) begin              // user-input fault avoidance 
         `SIM.printError (BFM_NAME, "spi_msg() - read/write input OOB");
      end
      else begin
         if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI sending header =", `V2HEXSTR(header)});
         spi_clk_en = 1'b1;            // indicate spi transaction underway (start clock)
         o_sden   = 1'b0;              // Active LOW enable o_sdenects 
         //<>output write/read_n
         if (w_rn == SPI_WR_POL) begin  // write/read_n flag output
            o_sdo  = 1'b0;             // drive write onto global net
            @(negedge o_scl);          // pause for falling edge of clock...
         end
         else begin
            o_sdo = 1'b1;              // drive data onto global net
            @(negedge o_scl);          // pause for falling edge of clock...
         end
         //<>output header
         for (x=HEADER_WIDTH; x>0; x=x-1) begin  // output header data
            o_sdo  = header[x-1];                // drive data onto global net  (offset for vector index range)
            @(negedge o_scl);                    // pause for falling edge of clock...
         end 
         //<>write/read payload
         if (w_rn == SPI_WR_POL) begin               // write cycle 
            if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI Writting payload value = ", `V2HEXSTR(w_dat)});
            for (x=PAYLOAD_WIDTH; x>0; x=x-1) begin
               o_sdo  = w_dat[x-1];                  // drive data onto global net  (offset for vector index range)
               @(negedge o_scl);                     // pause for falling edge of clock...
            end
         end
         else begin                                  // read-cycle
            for (x=PAYLOAD_WIDTH; x>0; x=x-1) begin  // output header data
               @(posedge o_scl);                     // read on rising edge of clock...
               r_dat[x-1] = i_sdi;                   // capture input from global net (offset for vector index range)
               @(negedge o_scl);                     // pause for falling edge of clock...
            end
            if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI Read returned payload = ", `V2HEXSTR(r_dat)});
         end
      end
      o_sden      = 1'b1;              // halt bus transaction
      o_sdo       = 1'b0;              // return to default rest
      spi_clk_en  = FREERUN_SCL_EN;    // stop clock at end of transaction if not Enabled      
   end
   endtask

   

   //<> ---------------------------------------------------------------------------
   //<> gated clock driver for USB SPI interface clock
   always
   begin
      if (spi_clk_en == 1'b1) begin    // wait on gating control flag
         #(SPI_CLK_PERIOD/2);          // period delay
         o_scl = ~o_scl;               // initiate clock operation
      end
      else begin
         o_scl = SCL_IDLE_LVL;         // when gated, set to default idle level
         wait (spi_clk_en == 1'b1);    // suspend process until next transaction
      end
   end  
   
endmodule 

//<> COMPONENT INSTANCE TEMPLATE

   // //<>--------------------------------------------------------------------
   // //<> SPI Master BFM 
   // //<>
   // bfm_spi_master
      // #( .BFM_NAME             ("bfm_spi_master"),
         // .SPI_CLK_PERIOD       (100),               // SPI SCL period (ns)
         // .PAYLOAD_WIDTH        (8),                 // # bits in payload section (read/write)
         // .HEADER_WIDTH         (8),                 // # bits in Header (includes all fields)
         // .SPI_WR_POL           (1'b0),              // polarity of write bit in SPI transaction
         // .FREERUN_SCL_EN       (1'b0),              // 0=gated, 1=freerunning o_SCL
         // .SCL_IDLE_LVL         (1'b1),              // default logic level if clock is gated
         // .SILENT               (0)                  // if true, suppress `SIM.printMessage outputs
      // ) bfm_spi_master_inst
      // (
         // .o_scl  (),                            // clock output 
         // .i_sdi  (),                            // data in wire
         // .o_sdo  (),                            // data out wire
         // .o_sden ()                             // enable out (optional)
      // );