//------------------------------------------------------------------------   
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//------------------------------------------------------------------------   
//File name   : bfm_spi_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : June 1, 2015
//------------------------------------------------------------------------   
//Description : BFM for FlexDCR SPI-B bus master
//
// two modes of operation: single dataword and burst (w/ address auto-increment)
//    Spi_Write()
//    Spi_Read()
//
//    Spi_Burst_Write()
//          + "wr_payload" 2D array
//    Spi_Burst_Read()
//          + "rd_payload" 2D array
//
// Datasheet: 
//------------------------------------------------------------------------   
// $Author: Arnold.Balisch $     $Revision: 1.6 $    $Date: 2015-07-07 19:40:11 $
//------------------------------------------------------------------------   


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`ifndef SIM
   `define SIM tb.sim_management_inst
`endif

//<>------------------------------------
//<> pre-compiler define substitutions:
//<>------------------------------------

//<> logic high vs low (single-bit...improves code readability)
`define HIGH 1'b1
`define LOW  1'b0

//<> define read/write bit logic level/direction
`define WR_DIR `HIGH
`define RD_DIR `LOW

//<> define rising/falling edge of clock for drive/latch activity
`define DRIVE_EDGE posedge
`define LATCH_EDGE negedge

module bfm_spi_B_master
   #( parameter BFM_NAME         = "bfm_spi_B_master",
      parameter SPI_CLK_PERIOD   = 50ns,              // SPI SCL period (ns)
      parameter SPI_CLK_GAP      = 150ns,             // SCL clock-hold/gapping between 16bit words (ns) in same transaction
      parameter IDLE_LVL         = 1'bZ,              // default logic level if clock is stopped
      parameter MAX_BURST_CNT    = 'h1000,            // # 16bit words permitted in autoincrement burst mode
      parameter SILENT           = 0                  // if true, suppress `SIM.printMessage outputs
   )
   (
      output wire       o_SCL ,                       // clock output 
      input wire        i_MISO,                       // data in wire
      output reg        o_MOSI = IDLE_LVL,            // data out wire
      output reg        o_EN = `HIGH                  // enable out (optional)
   );
   
//<> ------------------------------------------------------------------------   
//<> MODULE LOCAL PARAMETERS
//<> ------------------------------------------------------------------------   

   //<> timing constants
   localparam ts_CLK_preHLD        = SPI_CLK_PERIOD*3;   // start of transaction clk level hold delay
   localparam ts_CLK_postHLD       = SPI_CLK_PERIOD*3;   // end of transaction clk level hold delay
   localparam ts_CLK2EN_DLY        = SPI_CLK_PERIOD;   // delay from clk ground to enable assert
   localparam ts_MISO_Dsu          = 5ns;    // (revised by Feng July 6, 2015 via email)
   localparam ts_MISO_Dhld         = 6ns;    // (revised by Feng July 6, 2015 via email)
   localparam ts_TA                = (SPI_CLK_PERIOD*4);   // turnaround time between transactions
   
   //<> local parameters
   localparam PAYLOAD_WIDTH        = 16;                 // # bits in payload section (read/write)
   localparam HEADER_WIDTH         = 14;                 // # bits in Header (includes all fields)
   
   //<> define header mode-control bit between single word vs multi-word burst transfers! 
   localparam SINGLE_WORD          = `HIGH;
   localparam AUTO_ADDR_INC        = `LOW;
   
//<> ------------------------------------------------------------------------   
//<> TYPE AND SIGNAL DECLARATIONS
//<> ------------------------------------------------------------------------   
   reg [PAYLOAD_WIDTH-1:0] wr_payload [0:MAX_BURST_CNT-1]; // MOSI payload output data byte arrays (to Slave)
   reg [PAYLOAD_WIDTH-1:0] rd_payload [0:MAX_BURST_CNT-1]; // MISO payload input data byte arrays (from Slave)
   reg freeze_clk = `LOW;
   reg sclk;
   reg spi_clk_en = `LOW;     // gated clock control
   reg d_su_flag, d_hld_flag;
   integer x, word;  // loop pointer
   event clk_start_evnt, clk_stopped_evnt;
   string stage = "idle";     // waveform engine stage tracking (info only)

//<> ------------------------------------------------------------------------   
//<> USER TASKS/FUNCTION CALLS
//<> ------------------------------------------------------------------------   

   //<> ------------------------------------------------------------------------   
   //<> simplified read request call
   task Spi_Read( input  [HEADER_WIDTH-1:0]  r_header,     // 14bit header/address
                  output [PAYLOAD_WIDTH-1:0] r_dat       // data returned from Read transaction (zero during write)
                  );
   begin
      spi_B_msg(`RD_DIR, r_header, 0, r_dat);
   end
   endtask
   
   //<> ------------------------------------------------------------------------   
   //<> simplified write request call
   task Spi_Write( input [HEADER_WIDTH-1:0]  w_header,     // 14bit header/address
                   input [PAYLOAD_WIDTH-1:0] w_dat       // data returned from Read transaction (zero during write)
                  );
      reg [PAYLOAD_WIDTH-1:0] dummy;
   begin
      spi_B_msg(`WR_DIR, w_header, w_dat, dummy);
   end
   endtask
   
   
      
   //<> ------------------------------------------------------------------------   
   //<> simplified write request call
   task Spi_Burst_Write( input [HEADER_WIDTH-1:0]  w_header,     // 14bit header/address
                   input integer w_cnt      // number of 16bit words in burst
                  );
   begin
      Spi_Burst(`WR_DIR, w_header, w_cnt);
   end
   endtask
   
   //<> ------------------------------------------------------------------------   
   task Spi_Burst_Read( input [HEADER_WIDTH-1:0]  r_header,     // 14bit header/address
                   input integer r_cnt      // number of 16bit words in burst
                  );
   begin
      Spi_Burst(`RD_DIR, r_header, r_cnt);
   end
   endtask

   
//<> ------------------------------------------------------------------------   
//<> INTERNALS BFM TASKS/FUNCTION CALLS
//<> ------------------------------------------------------------------------   
   
   //<> ------------------------------------------------------------------------   
   //<> Burst transaction
   //<> ------------------------------------------------------------------------   
   task Spi_Burst( input reg                 w_rn,       // read/write direction (0=write, 1=read)
                   input [HEADER_WIDTH-1:0]  address,     // 14bit header/address
                   input integer             burst_len      // number of 16bit words in burst
   );
   begin
      stage="start";
      if (~SILENT) `SIM.printMessage (BFM_NAME, {"initiating SPI burst transaction @ address: ", `V2HEXSTR(address)});
      spi_clk_en = `HIGH;                              // indicate spi transaction underway (start clock)
      #(ts_CLK2EN_DLY);                                // delay the assertion of hte external Enable until clk has gone stable LOW
      o_EN = `LOW;                                     // Active LOW enable o_ENects 
      @(clk_start_evnt);
      //<> ------ output header ------ 
      for (x=HEADER_WIDTH; x>0; x=x-1) begin           // output header data
         @(`DRIVE_EDGE sclk);                          // pause for driving edge of clock...
         stage="header";
         o_MOSI = address[x-1];                         // drive data onto global net  (offset for vector index range)
      end 
      //<> ------ assert read/write direction bit (1=write, 0=read) ------ 
      @(`DRIVE_EDGE sclk);                             // pause for driving edge of clock...
      stage="WRn";
      o_MOSI = w_rn;                                   // drive write onto global net
      //<> ------ assert Mode bit (0=singleData, 1=auto_increment burst) ------ 
      @(`DRIVE_EDGE sclk);                             // pause for driving edge of clock...
      stage="mode";
      o_MOSI = AUTO_ADDR_INC;                            // single word transaction (no autoincrement)
      //<> write/read payload
      if (w_rn == `WR_DIR) begin                    // what type of operation are we in?            
         //<> -------------------- WRITE CYCLE ---------------------
         for (word=0; word<burst_len; word++) begin
            Clk_Suspend();                                // insert gap every 16bit word
            if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI Writting burst payload word #(", `V2INTSTR(word),") = ", `V2HEXSTR(wr_payload[word])});
            for (x=PAYLOAD_WIDTH; x>0; x=x-1) begin
               @(`DRIVE_EDGE sclk);                       // pause for driving edge of clock...
               stage="Write";
               o_MOSI  = wr_payload[word][x-1];                      // drive data onto global net  (offset for vector index range)
            end
         end
         //<> ------------------------------------------------------
      end
      else begin                                  
         //<> -------------------- READ-CYCLE ---------------------
         for (word=0; word<burst_len; word++) begin
            Clk_Suspend();                                // insert gap every 16bit word
            @(`DRIVE_EDGE sclk);                          // pause for driving edge of clock to align with slave's first databit output assertion
            for (x=PAYLOAD_WIDTH; x>0; x=x-1) begin       // for all bits in output data payload
               @(`LATCH_EDGE sclk);                       //  MISO read on latching edge of clock...
               stage="Read";
               rd_payload[word][x-1] = i_MISO;                       // capture input from global net (offset for vector index range)
            end
            if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI Read returned burst payload word #(", `V2INTSTR(word),") = ", `V2HEXSTR(rd_payload[word])});
         end
         //<> ------------------------------------------------------
      end
      //<> ------ close transaction -------------
      spi_clk_en  = `LOW;                    // kick stop clock process
      stage="stop";
      @(clk_stopped_evnt);
      #(SPI_CLK_PERIOD/2);                             // allow valid low period to elapse
      o_EN        = `HIGH;                             // halt bus transaction
      o_MOSI      = IDLE_LVL;                          // return to default rest
      #(ts_TA);
      stage="idle";
   end
   endtask

   
//<> ------------------------------------------------------------------------   
//<> INTERNAL TASKS/FUNCTION CALLS
//<> ------------------------------------------------------------------------   
   task Clk_Suspend();
   begin
      stage = "freeze";
      freeze_clk = 1;
      #(SPI_CLK_GAP);
      freeze_clk = 0;
   end
   endtask
   
   
   //<> ------------------------------------------------------------------------   
   //<> SPI-B bus Master 
   //<>  - MSbit out first
   //<>  - only single data transaction currently supported
   //<> ------------------------------------------------------------------------   
   task spi_B_msg(input  reg                 w_rn,       // read/write direction (0=write, 1=read)
                  input  [HEADER_WIDTH-1:0]  header,     // 14bit header/address
                  input  [PAYLOAD_WIDTH-1:0] w_dat,      // data for write transaction (ignored during read)
                  output [PAYLOAD_WIDTH-1:0] r_dat       // data returned from Read transaction (zero during write)
                  );
   begin
      stage="start";
      if (~SILENT) `SIM.printMessage (BFM_NAME, {"initiating SPI transaction @ address: ", `V2HEXSTR(header)});
      r_dat = 0;                                       // initialize read data return (in event of write transaction)
      spi_clk_en = `HIGH;                              // indicate spi transaction underway (start clock)
      #(ts_CLK2EN_DLY);                                // delay the assertion of hte external Enable until clk has gone stable LOW
      o_EN = `LOW;                                     // Active LOW enable o_ENects 
      @(clk_start_evnt);
      //<> ------ output header ------ 
      for (x=HEADER_WIDTH; x>0; x=x-1) begin           // output header data
         @(`DRIVE_EDGE sclk);                          // pause for driving edge of clock...
         stage="header";
         o_MOSI = header[x-1];                         // drive data onto global net  (offset for vector index range)
      end 
      //<> ------ assert read/write direction bit (1=write, 0=read) ------ 
      @(`DRIVE_EDGE sclk);                             // pause for driving edge of clock...
      stage="WRn";
      o_MOSI = w_rn;                                   // drive write onto global net
      //<> ------ assert Mode bit (0=singleData, 1=auto_increment burst) ------ 
      @(`DRIVE_EDGE sclk);                             // pause for driving edge of clock...
      stage="mode";
      o_MOSI = SINGLE_WORD;                            // single word transaction (no autoincrement)
      //<> write/read payload
      if (w_rn == `WR_DIR) begin                    // what type of operation are we in?            
         Clk_Suspend();                                // insert gap every 16bit word
         //<> -------------------- WRITE CYCLE ---------------------
         if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI Writting payload value = ", `V2HEXSTR(w_dat)});
         for (x=PAYLOAD_WIDTH; x>0; x=x-1) begin
            @(`DRIVE_EDGE sclk);                       // pause for driving edge of clock...
            stage="Write";
            o_MOSI  = w_dat[x-1];                      // drive data onto global net  (offset for vector index range)
         end
         //<> ------------------------------------------------------
      end
      else begin                                  
         //<> -------------------- READ-CYCLE ---------------------
         Clk_Suspend();                                // insert gap every 16bit word
         @(`DRIVE_EDGE sclk);                          // pause for driving edge of clock to align with slave's first databit output assertion
         for (x=PAYLOAD_WIDTH; x>0; x=x-1) begin       // for all bits in output data payload
            @(`LATCH_EDGE sclk);                       //  MISO read on latching edge of clock...
            stage="Read";
            r_dat[x-1] = i_MISO;                       // capture input from global net (offset for vector index range)
         end
         if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI Read returned payload = ", `V2HEXSTR(r_dat)});
         //<> ------------------------------------------------------
      end
      //<> ------ close transaction -------------
      spi_clk_en  = `LOW;                    // kick stop clock process
      stage="stop";
      @(clk_stopped_evnt);
      #(SPI_CLK_PERIOD/2);                             // allow valid low period to elapse
      o_EN        = `HIGH;                             // halt bus transaction
      o_MOSI      = IDLE_LVL;                          // return to default rest
      #(ts_TA);
      stage="idle";
   end
   endtask


//<> ------------------------------------------------------------------------   
//<> PROCESSES
//<> ------------------------------------------------------------------------   

   //<> ------------------------------------------------------------------------   
   //<> gated clock driver for USB SPI interface clock
   //<> ------------------------------------------------------------------------   
   initial
   begin : SerialAClk_driver
      sclk = IDLE_LVL;                                                // while inactive, clock output is tristated
      #(10);                                                          // offset from start of simulation
      while (1) begin                                                 // ...then loop until end of sim
         sclk = IDLE_LVL;                                             // while inactive, clock output is set to idle level
         wait (spi_clk_en == `HIGH);                                  // suspend until gating control flag is set
         sclk = `LOW;                                                 // ground clock to prep Slave interface
         #(ts_CLK_preHLD);                                            // hold SCL output low while Enable transitioning to active LOW
         ->clk_start_evnt;
         while (spi_clk_en == `HIGH) begin                            // while transaction is in progress....
            #(SPI_CLK_PERIOD/2);                                      // pause for 1/2 duty-cycle of clock
            if (freeze_clk == `HIGH) begin                            // check if clock freeze requested
               if (sclk == `LOW) begin                                // check if clock currently low
                  @(negedge freeze_clk);                              // suspend clock routine until released
               end
               else begin                                             // - clock is currently high
                  sclk = ~sclk;                                       // finish high cycle before freezing in low state
                  @(negedge freeze_clk);                              // and then suspend clock routine until released          
               end
            end
            else begin                                                // freeeze not set, so run normally
               sclk = ~sclk;                                          // toggle clock every half period
            end
         end
         ->clk_stopped_evnt;
         #(ts_CLK_postHLD);                                           // hold SCL output low while Enable transitioning to inactive HIGH
      end
   end  
   
   assign o_SCL = sclk;  //<> map internal clock to output port
   
//<>----------------------------------------------------------------
//<> TIMING MONITORS
//<>----------------------------------------------------------------
   
   //<>----------------------------------------------------------------
   //<> Monitor the CLK/DATA transaction setup/hold timing    
   //<>----------------------------------------------------------------
   specify
      // <> MISO clk/data setup/hold
      $setup(i_MISO           , `LATCH_EDGE o_SCL, ts_MISO_Dsu , d_su_flag );
      $hold(`LATCH_EDGE o_SCL , i_MISO           , ts_MISO_Dhld, d_hld_flag);
   endspecify
      
      // <> Fault output monitors for above specify triggers
      always @(d_su_flag)    `SIM.printError(BFM_NAME, "SPI MISO setup timing violation detected. " );
      always @(d_hld_flag)   `SIM.printError(BFM_NAME, "SPI MISO hold timing violation detected. " );
   
endmodule 

//<> COMPONENT INSTANCE TEMPLATE

   // //<>--------------------------------------------------------------------
   // //<> SPI_B Master BFM 
   // //<>
   // bfm_spi_B_master
      // #( .BFM_NAME             ("bfm_spi_B_master"),
         // .SPI_CLK_PERIOD       (100),               // SPI SCL period (ns)
         // .IDLE_LVL             (1'bZ),              // default logic level if clock is gated
         // .SILENT               (0)                  // if true, suppress `SIM.printMessage outputs
      // ) bfm_spi_B_master_inst
      // (
         // .o_SCL   (),     // clock output 
         // .i_MISO  (),     // data in wire
         // .o_MOSI  (),     // data out wire
         // .o_EN    ()      // enable out (optional)
      // );