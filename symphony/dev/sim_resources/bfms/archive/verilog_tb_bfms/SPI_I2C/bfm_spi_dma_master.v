//------------------------------------------------------------------------   
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//------------------------------------------------------------------------   
//File name   : bfm_spi_dma_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : July 31st, 2012
//------------------------------------------------------------------------   
//Description : BFM for Sharc SPI bus DMA master
//
// Available user tasks:
//    - Spi_Clear_Buffers()               - clear read/write buffer arrays
//    - Spi_Write(address, value)         - single word write
//    - Spi_Read(address, value)          - single word read
//    - Spi_DMA_Write(base_addr, length)  - full N-word DMA write
//    - Spi_DMA_Read(base_addr, length)   - full N-word DMA read
//
//------------------------------------------------------------------------   
//    Note: THE "SPI ENGINE" IN SHARC IS HALF-DUPLEX:
//    
//    ---- SPI TRANSFER PARAMETERS: -----
//    CP = 1 (clock polarity; clock idles HI)
//    CPHASE = 1 (edge aligned clock data phase relationship mode)
//    Master (DSP) presents data on clk NEGEDGE
//    Master (DSP) samples  data on clk POSEDGE
//    Data is transferred MSB first, in both directions.
//    SPI CLOCK --> 28.125MHz (global clock driven by DSP)
//    SPI CLOCK IS INACTIVE (IDLE HI) BETWEEN TRANSFERS (while slave select de-asserted)
//    
//    ---- Data trasnsfer request header command frame (32-bit word) -----
//    (format version as of January 23, 2014)
//    
//     Bitfield                Value (Min - Max)        field size  Description
//     [31   ]   ACCESS_TYPE   0x0 - 0x1                     1      0 = Read / 1 = Write
//     [30:29]   RESERVED      0x0                           2      Set to 0
//     [28:20]   START_ADD     0x000 (0) - 0x1FF (511)       9      Index of the first data word to transfer
//     [19:16]   VERSION       0x0 - 0xF                     4      Set to 0
//     [15:13]   RESERVED      0x0                           3      Set to 0
//     [12: 4]   SIZE          0x000 (0) - 0x1FF (511)       9      Size of data transfer (Number of data words - 1)
//     [ 3: 0]   RESERVED      0x0                           4      Set to 0
//
// Datasheet: 
//------------------------------------------------------------------------   
// $Author: Arnold.Balisch $     $Revision: 1.4 $    $Date: 2014-06-05 15:25:14 $
//------------------------------------------------------------------------   


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`ifndef SIM
   `define SIM tb.sim_management_inst
`endif

  module bfm_spi_dma_master
   #( parameter BFM_NAME             = "bfm_spi_dma_master",
      parameter SPI_CLK_PERIOD       = 40.0,                // SPI SCL period (ns)
      parameter MAX_WORDS            = 512,                // if true, suppress `SIM.printMessage outputs
      parameter HEADER_WIDTH         = 32,                 // # bits in Header (includes all fields)  
      parameter SILENT               = 0                   // if true, suppress `SIM.printMessage outputs
   )
   (  //<> DUT interfaces
      output reg o_srst,               // active high start of transaction 
      output reg o_scl ,               // clock output 
      output reg o_sel ,               // enable out
      input wire i_miso,               // data in wire
      output reg o_mosi,               // data out wire
      input wire i_stat,               // bus transaction status                  << currently unused >>
      //<> testbench hooks
      output reg [HEADER_WIDTH-1:0] o_ack_frame
   );
   
//<> ------------------------------------------------------------------------   
//<> MODULE LOCAL PARAMETERS
//<> ------------------------------------------------------------------------   
   parameter DEBUG                = 0;                 // if true, print additional debug messages to logfile
   parameter SPI_VERSION          = 4'h0;              // SPI Protocol version (future use)
   parameter DATA_WORD_WIDTH      = 16;                // # bits in payload section (read/write)
   parameter ADDR_FIELD_WIDTH     = 9;                 // # bits in Header (includes all fields)
   parameter BURST_FIELD_WIDTH    = 9;                 // # bits in Header (includes all fields)
   parameter FREERUN_SCL_EN       = 1'b0;              // 0=gated, 1=freerunning o_SCL
   parameter SPI_WR_POL           = 1'b0;              // polarity of write bit in SPI transaction
   parameter ts_TA                = (SPI_CLK_PERIOD*8); // turnaround between SPI bus Transactions (~200ns)
   parameter ts_RST2CSn           = (SPI_CLK_PERIOD*2); // delay from spi_rst deassert to CSn assert
   parameter SCL_IDLE_LVL         = 1'b1;              // default logic level if clock is gated (CLKPL=1, CPHASE=1)
   parameter MOSI_IDLE_LVL        = 1'b1;              // default logic level if clock is gated (CLKPL=1, CPHASE=1)
   parameter RD_FLAG              = 1'b0;
   parameter WR_FLAG              = 1'b1;
   
  
//<> ------------------------------------------------------------------------   
//<> TYPE AND SIGNAL DECLARATIONS
//<> ------------------------------------------------------------------------   
   reg spi_clk_en;                     // gated clock control
   reg read_en, write_en;              // flags for transaction read return capture.
   reg read_cycle, write_cycle;        // flags for testbench waveform readability enhancement
   
   //<> following arrays are to be preloaded by the testcase prior to issueing a read/write transaction request.
   reg [DATA_WORD_WIDTH-1:0] wr_burst_array [MAX_WORDS-1:0];   // 2D array for testcase preload of write frame data
   reg [DATA_WORD_WIDTH-1:0] rd_burst_array [MAX_WORDS-1:0];   // 2D array for testcase preload of read frame data
   reg [HEADER_WIDTH-1:0] req_header_ack ;
   reg [HEADER_WIDTH-1:0] req_header ;

   integer clk_cntr; // track the number of clock pulses output during frame 
   integer x,y;      // loop pointers
   integer init;     // initialization loop pointer
   
   //<> initialize internal BFM variables
   initial begin
      o_scl          = SCL_IDLE_LVL;
      o_mosi         = 1'b1;
      o_srst         = 1'b0;
      o_sel          = 1'b1;
      o_ack_frame    = 'h0;
      spi_clk_en     = 1'b0;
      write_en       = 0;
      read_en        = 0;
      req_header     = 'h0;
      req_header_ack = 'h0;
      read_cycle      = 1'b0;
      write_cycle     = 1'b0;
      for (init=0;init<MAX_WORDS;init=init+1) begin
         wr_burst_array[init] = 'h0;
         rd_burst_array[init] = 'h0;
      end
   end

//<> ---------------------------------------------------------------------------
//<> USER TASKS
//<> ---------------------------------------------------------------------------
   
   //<> ---------------------------------------------------------------------------
   //<> SPI Write (single word) Transfer task call
   //<> ---------------------------------------------------------------------------
   task Spi_Write( input  [ADDR_FIELD_WIDTH-1:0]  address,
                   input   [DATA_WORD_WIDTH-1:0]  value );
   begin
      if (!SILENT) `SIM.printMessage (BFM_NAME, {"SPI single transaction write: Address=", `V2HEXSTR(address), ", value =", `V2HEXSTR(value)});
      wr_burst_array[0] = value;
      Spi_DMA_Write(address,1);
   end
   endtask
   
   //<> ---------------------------------------------------------------------------
   //<> SPI Read (single word) Transfer task call
   //<> ---------------------------------------------------------------------------
   task Spi_Read ( input  [ADDR_FIELD_WIDTH-1:0]  address,
                   output [DATA_WORD_WIDTH-1:0]   value );
   begin
      Spi_DMA_Read(address,1);
      value = rd_burst_array[0] ;
      if (!SILENT) `SIM.printMessage (BFM_NAME, {"SPI single read: Address=", `V2HEXSTR(address), ", value =", `V2HEXSTR(value)});
   end
   endtask

   

//<> ---------------------------------------------------------------------------
//<> BFM TASKS
//<> ---------------------------------------------------------------------------
   
   //<> ---------------------------------------------------------------------------
   //<> SPI Write (DMA Burst) Transfer task call
   //<> ---------------------------------------------------------------------------
   task Spi_DMA_Write( input  [ADDR_FIELD_WIDTH-1:0]  base_addr,
                       input  [BURST_FIELD_WIDTH-1:0] length
   );
      // integer x,y;
   begin
      write_cycle = 1'b1;
      if (DEBUG) `SIM.printMessage (BFM_NAME, {" <DEBUG> SPI write to base Address =", `V2HEXSTR(base_addr), " : Burst size =", `V2INTSTR(length)});
      spi_clk_en = 1'b0;
      req_header = Make_Header(base_addr, WR_FLAG, length );  // build header 
      req_header_ack = 'bz;   // render return bogus...highlight alignment issues
   //<> commence write transaction --------------------------
      write_en = 1'b1;        // indicate write request
      read_en = 1'b0;         // (ensrure read flag inactive)
   //<> signal transaction start --------------------------
      o_srst = 1'b1;          //assert reset at start of new transaction
      #(SPI_CLK_PERIOD);          // pause for falling edge of clock...
      o_srst = 1'b0;
      #(ts_RST2CSn);    // delay for target reset recovery
   //<> output Header --------------------------
      o_sel   = 1'b0;            // Active LOW enable o_selects 
      o_mosi = 1'b1;              // indicate write transaction underway
      for (x=HEADER_WIDTH; x>0; x=x-1) begin  // output request header
         if (spi_clk_en == 1'b0) 
            #(SPI_CLK_PERIOD/2) spi_clk_en = 1'b1;    // start clock after half clock cycle for MSBit of header
         @(negedge o_scl);                    // pause for falling edge of clock...
         o_mosi  = req_header[x-1];                // output MSbit first
      end
      @(posedge o_scl); 
   //<> strobe select between phases --------------------------
      spi_clk_en = 1'b0;            // halt spi clock
      #(SPI_CLK_PERIOD/2);
      o_sel   = 1'b1;   
      o_mosi = MOSI_IDLE_LVL;                      // Tristate during select inactive
      #(SPI_CLK_PERIOD);
      o_sel   = 1'b0;   
      spi_clk_en = 1'b1;            // start spi clock
   //<> request acknowledge return --------------------------
      for (x=HEADER_WIDTH; x>0; x=x-1) begin  // capture header acknowledge
         @(posedge o_scl);                    // capture on rising clock edge
         req_header_ack[x-1] = i_miso;
      end 
   //<> strobe select between phases --------------------------
      spi_clk_en = 1'b0;            // halt spi clock
      #(SPI_CLK_PERIOD/2);
      o_sel   = 1'b1;   
      o_mosi = MOSI_IDLE_LVL;                      // Tristate during select inactive
      // if (CheckAcknowledge) begin   // verify acknowledge
         #(SPI_CLK_PERIOD)
         o_sel   = 1'b0;   
         spi_clk_en = 1'b1;            // start spi clock
      //<> output Payload --------------------------
         for (x=0; x<length; x=x+1) begin  // output lowest data word first
            if (DEBUG) `SIM.printMessage (BFM_NAME, {"<DEBUG>   ----> SPI write: array index[", `V2HEXSTR(length), "] =", `V2INTSTR(wr_burst_array[x])});
            for (y=DATA_WORD_WIDTH; y>0; y=y-1) begin  // output each data word MSbit first
               @(negedge o_scl);                    // pause for falling edge of clock...
               o_mosi  = wr_burst_array[x][y-1];                // drive data onto global net  (offset for vector index range)
            end 
         end 
      // end
      // else begin  // abort if acknowledge fails
      // end
   //<> terminate transaction --------------------------
      @(posedge o_scl);       // finish current cycle and end
      spi_clk_en  = 1'b0;    // stop clock at end of transaction if not Enabled        
      #(SPI_CLK_PERIOD/2);
      o_sel       = 1'b1;              // halt bus transaction
      o_mosi      = 1'b0;              // return to default rest
      write_en    = 1'b0;
      #(ts_TA);  // ensure minimum transaction gap
      write_cycle = 1'b0;
   end 
   endtask

   
   //<> ---------------------------------------------------------------------------
   //<> SPI Read (DMA Burst) Transfer task call
   //<> ---------------------------------------------------------------------------
   task Spi_DMA_Read( input  [ADDR_FIELD_WIDTH-1:0]  base_addr,
                      input  [BURST_FIELD_WIDTH-1:0] length
   );
      // integer x,y;
   begin
      read_cycle = 1'b1;
      if (DEBUG) `SIM.printMessage (BFM_NAME, {"<DEBUG> SPI Read to base Address =", `V2HEXSTR(base_addr), " : Burst size =", `V2INTSTR(length)});
      req_header = Make_Header(base_addr, RD_FLAG, length );  // build header 
      req_header_ack = 'bz;   // render return bogus...highlight alignment issues
   //<> commence write transaction --------------------------
      write_en = 1'b0;        // (ensrure write flag inactive)
      read_en = 1'b0;         //  ensure flag unset until proper location in transaction
   //<> signal transaction start --------------------------
      o_srst = 1'b1;          //assert reset at start of new transaction
      #(SPI_CLK_PERIOD);          // pause for falling edge of clock...
      o_srst = 1'b0;
      #(ts_RST2CSn);    // delay for target reset recovery
   //<> output Header --------------------------
      o_sel   = 1'b0;         // Active LOW enable o_selects 
      o_mosi = 1'b0;              // indicate read transaction underway
      for (x=HEADER_WIDTH; x>0; x=x-1) begin  // output request header
         if (spi_clk_en == 1'b0) 
            #(SPI_CLK_PERIOD/2) spi_clk_en = 1'b1;            // start clock after half clock cycle for MSBit of header
         @(negedge o_scl);                    // pause for falling edge of clock...
         o_mosi  = req_header[x-1];                // output MSbit first
      end
   //<> strobe select between phases --------------------------
      @(posedge o_scl); 
      spi_clk_en = 1'b0;            // halt spi clock
      #(SPI_CLK_PERIOD/2);
      o_sel   = 1'b1;   
      o_mosi = MOSI_IDLE_LVL;                      // Tristate during select inactive
      #(SPI_CLK_PERIOD);
      o_sel   = 1'b0;   
      spi_clk_en = 1'b1;            // start spi clock
   //<> request acknowledge return --------------------------
      for (x=HEADER_WIDTH; x>0; x=x-1) begin  // capture header acknowledge
         @(posedge o_scl);                    // capture on rising clock edge
         req_header_ack[x-1] = i_miso;
      end 
   //<> strobe select between phases --------------------------
      spi_clk_en = 1'b0;            // halt spi clock
      #(SPI_CLK_PERIOD/2);
      o_sel   = 1'b1;   
      o_mosi = MOSI_IDLE_LVL;                      // Tristate during select inactive
      // if (CheckAcknowledge) begin   // verify acknowledge
         #(SPI_CLK_PERIOD);
         o_sel   = 1'b0;   
         spi_clk_en = 1'b1;            // start spi clock
      //<> read Payload --------------------------
         read_en = 1'b1;
         for (x=0; x<length; x=x+1) begin  // load lowest data word first
            for (y=DATA_WORD_WIDTH; y>0; y=y-1) begin  // output each data word MSbit first
               @(posedge o_scl);                    // capture on rising clock edge
               rd_burst_array[x][y-1] = i_miso;  // capture data
            end 
            if (DEBUG) `SIM.printMessage (BFM_NAME, {"<DEBUG>   ----> SPI Read: array index[", `V2HEXSTR(length), "] =", `V2INTSTR(rd_burst_array[x])});
         end 
         read_en = 1'b0;
      // end
   //<> terminate transaction --------------------------
      // @(negedge o_scl);    // finish current clock cycle
      spi_clk_en  = 1'b0;              // stop clock at end of transaction if not Enabled        
      #(SPI_CLK_PERIOD/2);
      o_sel       = 1'b1;              // halt bus transaction
      o_mosi      = MOSI_IDLE_LVL;              // return to default rest
      read_en     = 1'b0;
      #(ts_TA);  // ensure minimum transaction gap
      read_cycle = 1'b0;
   end 
   endtask
   

   //<> ---------------------------------------------------------------------------
   //<> Clear both read and write array buffers on testcase request
   //<> ---------------------------------------------------------------------------
   task Spi_Clear_Buffers;
      integer x;
   begin
      for (x=0;x<MAX_WORDS; x=x+1) begin
         wr_burst_array[x] = 0;
         rd_burst_array[x] = 0;
      end
   end
   endtask
   
   //<> ---------------------------------------------------------------------------
   //<> Build Request Header
   //     BITFIELD                RANGE (MIN - MAX)        FIELD SIZE  DESCRIPTION
   //     [31   ]   ACCESS_TYPE   0x0 - 0x1                     1      0 = Read / 1 = Write
   //     [30:29]   RESERVED      0x0                           2      Set to 0
   //     [28:20]   START_ADD     0x000 (0) - 0x1FF (511)       9      Index of the first data word to transfer
   //     [19:16]   VERSION       0x0 - 0xF                     4      Set to 0
   //     [15:13]   RESERVED      0x0                           3      Set to 0
   //     [12: 4]   SIZE          0x000 (0) - 0x1FF (511)       9      Size of data transfer (Number of data words - 1)
   //     [ 3: 0]   RESERVED      0x0             
   //<> ---------------------------------------------------------------------------
   function [HEADER_WIDTH-1:0] Make_Header 
      (input  [ADDR_FIELD_WIDTH-1:0]  addr,        // starting address
       input                          WRn ,        // 1= write, 0=read transacion
       input  [BURST_FIELD_WIDTH-1:0] length );    // burst size (0=one 16bit word, 1= two words, etc)
   begin
      Make_Header[31]      = WRn;                  // 1= write, 0=read transacion
      Make_Header[30:29]   = 2'h0;                 // reserved
      Make_Header[28:20]   = (9'b0 + addr);        // address (ensure surplus upper bits set to zero)
      Make_Header[19:16]   = SPI_VERSION;                 // Version (tie low)
      Make_Header[15:13]   = 3'h0;                 // reserved
      Make_Header[12: 4]   = (19'b0 + (length-1)); // burst size (0=one 16bit word; 1= two words; etc)
      Make_Header[ 3: 0]   = 4'h0;                 // version (tied low)
   end
   endfunction

   
   //--------------------------------------------------------------------
   //<> GATED CLOCK DRIVER for USB SPI interface clock
   //--------------------------------------------------------------------
   always
   begin
      if (spi_clk_en == 1'b1) begin    // wait on gating control flag
         #(SPI_CLK_PERIOD/2);          // period delay
         o_scl = ~o_scl;               // initiate clock operation
         if (o_scl == !SCL_IDLE_LVL) clk_cntr = clk_cntr-1;        // counter for waveform debug high only
      end
      else begin
         o_scl = SCL_IDLE_LVL;         // when gated, set to default idle level
         clk_cntr = 32;                 // reset clk_cntr for next frame
         @(spi_clk_en);    // suspend process until next transaction
      end
   end  
   
   //--------------------------------------------------------------------
   //<> Internal BFM function to verify returned vs expected acknowledge 
   //--------------------------------------------------------------------
   function CheckAcknowledge;
   begin
      o_ack_frame = req_header_ack;  // output frame captured 
      if (req_header_ack !== req_header) begin
         `SIM.printError(BFM_NAME, {"Sharc SPI transaction acknowledge failed. expected=",`V2HEXSTR(req_header), ", return=",`V2HEXSTR(req_header_ack)});
         CheckAcknowledge = 0;   // acknowledge check failed...abort transaction
      end 
      else begin
         CheckAcknowledge = 1;   // acknowledge check confirmed
      end
   end
   endfunction

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
         // .i_miso  (),                            // data in wire
         // .o_mosi  (),                            // data out wire
         // .o_sel ()                             // enable out (optional)
      // );