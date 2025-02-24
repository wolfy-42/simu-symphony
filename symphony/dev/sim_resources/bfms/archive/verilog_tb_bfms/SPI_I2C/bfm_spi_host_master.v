//------------------------------------------------------------------------   
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//------------------------------------------------------------------------   
//File name   : bfm_spi_host_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : June 1, 2015
//------------------------------------------------------------------------   
//Description : BFM for  SPI-Host I/F (master)
//    - interface writes and reads sequential data words to/from an external SPI FIFO slave
//    - user loads BFM model wr_payload byte array with test data prior to calling Spi_Write() task
//    - user calls Spi_Read() task to fetch data waiting in fifo and then reads the return_value number of bytes from the rd_payload byte array.
//       - Note: read task will return a non-zero status if remote slave has no data ready to be read.
//       - data ready query operation is automatically performed by read task...no need for user to call.
//       - number of query retries defined by parameter
//
// User callable tasks
// -----------------------------
//    task Spi_Write( num_bytes, status ); 
//    task Spi_Read ( num_bytes, status ); 
//
// User data arrays (write before, read after task calls)
// -----------------------------
//    wr_payload    // MOSI payload output data byte arrays (to DUT/Slave)
//    rd_payload    // MISO payload input data byte arrays (from DUT/Slave)
//
//
//
//------------------------------------------------------------------------   
// $Author: Arnold.Balisch $     $Revision: 1.4 $    $Date: 2015-07-07 19:41:51 $
//------------------------------------------------------------------------   


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines
`ifndef SIM
   `define SIM tb.sim_management_inst
`endif

`define HIGH 1'b1
`define LOW  1'b0


module bfm_spi_host_master
   #( parameter BFM_NAME            = "bfm_spi_host_master",
      parameter SPI_CLK_PERIOD      = 100ns,    // SPI SCL period (ns)
      parameter QUERY_RETRY_LIMIT   = 8,        // maximum number of SPI query requests to retry before failing
      parameter SILENT              = 0,        // if true, suppress `SIM.printMessage outputs
      parameter IDLE_LVL            = 1'bz      // default logic level (not user adjustable)
   )
   (
      output wire  o_SCL,                        // clock output 
      input  wire  i_SCL,                        // clock output 
      output reg   o_MOSI   = IDLE_LVL,          // data out wire
      input  wire  i_MISO,                       // data in wire
      output reg   o_EN     = 1'b1               // enable out (optional)
   );
   
//<> ------------------------------------------------------------------------   
//<> MODULE LOCAL PARAMETERS
//<> ------------------------------------------------------------------------   
//<> define rising/falling edge of clock for drive/latch activity
`define DRIVE_EDGE negedge
`define LATCH_EDGE posedge

   //<> -- timing constants (from DS)
   localparam ts_MIN_PERIOD        = 50ns;  // delay from assert of CS-N to first falling edge clock
   localparam ts_CS2CLK            = 50ns;  // delay from assert of CS-N to first falling edge clock
   localparam ts_CLK2CS            = 40ns;
   localparam ts_MISO_Dsu          = 20ns;
   localparam ts_MISO_Dhld         = 5ns;       // (set by Feng in email 7july 6,2015)
   localparam ts_MOSI_Dsu          = 10ns;
   localparam ts_MOSI_Dhld         = 10ns;
   localparam ts_CS_CS             = 200ns;     // turnaround time between any two SPI transactions (write/query/read)
   
   //<> -- local parameters
   localparam SPI_WR_POL           = 1'b0;               // polarity of write bit in SPI transaction
   localparam DATA_WIDTH           = 8;                  // # bits in Header (includes all fields)
   localparam HEADER_WIDTH         = 8;                  // # bits in Header (includes all fields)
   localparam MIN_BYTE_PAYLOAD     = 3;                  // Minumum number of bytes in a payload (incl header)
   localparam MAX_BYTE_PAYLOAD     = 1050;               // Maximum number of bytes in a payload (incl header)
   localparam SCL_RUN              = `HIGH;              // serial clock operation mode; (0=gated/halted, 1=running)
   
   localparam HDR_MODE_WRITE       = 3'b100;
   localparam HDR_MODE_QUERY       = 3'b000;
   localparam HDR_MODE_READ        = 3'b010;
   

//<> ------------------------------------------------------------------------   
//<> SPECIAL USER ACCESSABLE SIGNAL DECLARATIONS
//<> ------------------------------------------------------------------------   

   reg [7:0] wr_payload [0:MAX_BYTE_PAYLOAD-1]; // MOSI payload output data byte arrays (to Slave)
   reg [7:0] rd_payload [0:MAX_BYTE_PAYLOAD-1]; // MISO payload input data byte arrays (from Slave)
   string stage = "idle";                       // used only for waveform display clarity (not a control structure)
   
//<> ------------------------------------------------------------------------   
//<> INTERNAL BFM TYPE AND SIGNAL DECLARATIONS
//<> ------------------------------------------------------------------------   
  
   //<> defind packed structure for headers
   typedef struct packed { reg [2:0] mode ;  // 3bits
                           reg [4:0] info ;  // 5bits
                         } t_spi_header;
                         
   t_spi_header m_header = 0;                // declare and init master headers (packed)
   t_spi_header s_header = 0;                // declare and init slave headers (packed)

   reg sclk;                                 // internal serial clock source
   reg spi_clk_en = !SCL_RUN;                // gated clock control

   integer x;                                // loop pointer
   integer rd_bitcntr;
   integer last_rd_byte_ptr;
   integer rd_byte_ptr;
   integer wr_bitcntr;
   integer wr_byte_ptr;
   integer last_wr_byte_ptr;
      
   event sclk_started_evnt;
   event sclk_stopped_evnt;
   
//<> ------------------------------------------------------------------------   
//<> User Tasks/Function Calls
//<> ------------------------------------------------------------------------   
   
   //<> ------------------------------------------------------------------------   
   //<> Write transaction Testcase call
   //<>  - MSbit out first
   //<> ------------------------------------------------------------------------   
   task Spi_Write( input  integer num_bytes,                     // number of bytes (NOT incl header) to output during CS_N active  (min=2)
                   output integer status  );                     // transaction status (0=completed normally; 1=transaction error/timeout)
         integer byte_cnt;
         integer bit_cnt;
      begin
         if (~SILENT) `SIM.printMessage (BFM_NAME, {"initiating SPI-B Write transaction with ", `V2INTSTR(num_bytes)," data bytes"});
         //<> initialize internal task variables  
         status = 0;                                              // initialize to normal operation result
         //<> start transaction
         o_EN   = `LOW;                                           // Active LOW enable o_ENects 
         stage = "w_start";
         #(ts_CS2CLK);                                            // delay the assertion of hte external Enable until clk has gone stable LOW
         spi_clk_en = SCL_RUN;                                    // start clock
         //<> send header byte
         m_header.mode = HDR_MODE_WRITE;
         for (bit_cnt=0; bit_cnt < 8; bit_cnt++) begin
            @(`DRIVE_EDGE sclk);
            stage = "w_header";
            o_MOSI = m_header[7-bit_cnt];
         end
         //<> send payload bytes
         for (byte_cnt=0; byte_cnt < num_bytes; byte_cnt++) begin // count off the bytes to be output
            @(`LATCH_EDGE sclk);                                  // pad to opposite edge before setting stage just for waveform debug
            stage = "mark";
            for (bit_cnt=0; bit_cnt < 8; bit_cnt++) begin         // output a full byte (8bits) of data
               @(`DRIVE_EDGE sclk);                               // data is driven out on falling clock edge
               stage = "w_payload";
               o_MOSI = wr_payload[byte_cnt][(7-bit_cnt)];
            end
         end
         //<> terminate transaction
         @(`LATCH_EDGE sclk);                                     // ensure last slave latching edge issued 
         stage = "w_stop";
         spi_clk_en  = !SCL_RUN;                                  // stop clock ?
         #(ts_CLK2CS);                                            // required protocol timing delay
         o_EN        = `HIGH;                                     // halt bus transaction
         o_MOSI      = IDLE_LVL;                                  // return to default rest
         stage = "idle";
      end
   endtask

   //<> ------------------------------------------------------------------------   
   //<> Read Transaction testcase call
   //<>  - MSbit in first
   //<> ------------------------------------------------------------------------   
   task Spi_Read( output integer rtn_bytes,                                         // num bytes (NOT incl header) returned (min=2)
                  output integer status                                             // transaction status (0=completed normally; 1=transaction error/timeout)
                );
         integer q_stat;      //<> query status reply
         integer query_retry_cnt;      //<> query status reply
         integer byte_cnt;
         integer bit_cnt;
      begin
         //<> initialize internal task variables  
         status = 0;                                                                // 0 = normal
         q_stat = 0;                                                                // 0 = not-ready
         query_retry_cnt = 0;                                                       // clear
         //<> perform query transactions until valid return or retry limit reached
         while ((q_stat == 0) && (query_retry_cnt < QUERY_RETRY_LIMIT)) begin       // repeat as long as query returns no data ready or retry limit is reached
            Slave_Query(rtn_bytes, q_stat);                                         // check query responce
            query_retry_cnt++;                                                      // increment count of # query requests sent
         end
                                                                                    // if (query_retry_cnt != QUERY_RETRY_LIMIT) begin   //<> ---read requested return data bytes
         if (q_stat !== 0) begin                                                    // -- query returned with data waiting.  read requested return data bytes
            stage = "idle";
            #(ts_CS_CS);                                                            // delay for inter-transaction gap
            //<> start transaction
            stage = "r_start";
            o_EN   = `LOW;                                                          // Active LOW enable o_ENects 
            #(ts_CS2CLK);                                                           // delay the assertion of hte external Enable until clk has gone stable LOW
            spi_clk_en = SCL_RUN;              
            m_header.mode = HDR_MODE_READ;
            for (bit_cnt=0; bit_cnt < 8; bit_cnt++) begin                           // send/recieve MOSI and MISO header bytes
               @(`DRIVE_EDGE sclk);
               stage = "r_header";
               o_MOSI = m_header[7-bit_cnt];                                        // output header from HOST (index from 7 due to range 7:0, MSbit first)
               @(`LATCH_EDGE sclk);
               s_header[7-bit_cnt] = i_MISO;                                        // return header from FPGA 
            end
            //<> fetch number of bytes waiting as indicated by finial query
            for (byte_cnt=0; (byte_cnt < rtn_bytes); byte_cnt++) begin
               @(`DRIVE_EDGE sclk);                                                 // start of first data bit output from slave - drive MOSI low
               stage = "mark";
               o_MOSI = `LOW;                 
               for (bit_cnt=0; bit_cnt < 8; bit_cnt++) begin
                  @(`LATCH_EDGE sclk);                                              // Clock edge that Host latches data 
                  stage = "r_payload";
                  rd_payload[byte_cnt][(7-bit_cnt)] = i_MISO;                       // index from 7 due to range 7:0, MSbit first
               end
            end         
            if (~SILENT) `SIM.printMessage (BFM_NAME, {"SPI-B Read transaction returned ", `V2INTSTR(rtn_bytes)," data bytes"});         
         end         
         else begin                                                                 // -- query retry limit reached...no data waiting
            if (~SILENT) `SIM.printWarning (BFM_NAME, {"SPI-B Read attempt exceeded query retry limit - no data ready"});                  
            status = 1;                                                             // indicate fault
            rtn_bytes = 0;                                                          // indicate no data waiting
         end
         //<> terminate transaction
         stage = "r_stop";
         spi_clk_en  = !SCL_RUN;                                                    // stop clock ?
         #(ts_CLK2CS);                                                              // wait for low-portion of output clock dutycycle
         o_EN        = `HIGH;                                                       // halt bus transaction
         o_MOSI      = IDLE_LVL;                                                    // return to default rest
         stage = "idle";
      end
   endtask
   
//<> ------------------------------------------------------------------------   
//<> Internals BFM Tasks/Function Calls
//<> ------------------------------------------------------------------------   

   //<> ------------------------------------------------------------------------   
   //<> query Transaction call  (internal)
   //<>  - poll SPI bus to detect data acknowledge that read-data is ready
   //<>  - MSbit in first
   //<> ------------------------------------------------------------------------   
   task Slave_Query( output [15:0] rtn_bytes,              // 16bit integer value of last two bytes of MISO query
                     output status);                       // read/write direction (0=write, 1=read)
         integer byte_cnt;
         integer bit_cnt;
         reg [15:0] rtn_word;
      begin
         //<> initialize internal task variables  
         status = 0;                                       // initialize to normal operation result
         //<> start transaction
         stage = "q_start";
         o_EN   = `LOW;                                    // Active LOW enable o_ENects 
         #(ts_CS2CLK);                                     // delay the assertion of hte external Enable until clk has gone stable LOW
         spi_clk_en = SCL_RUN;                             // start clock
         m_header.mode = HDR_MODE_QUERY;                   // define header byte as query transaction
         //<> - QUERY HEADER (one byte)
         for (bit_cnt=0; bit_cnt < 8; bit_cnt++) begin     
            @(`DRIVE_EDGE sclk);
            stage = "q_header";
            o_MOSI = m_header[7-bit_cnt];
            @(`LATCH_EDGE sclk);
            s_header[7-bit_cnt] = i_MISO;                  // return header from FPGA 
         end
         //<>  - PAYLOAD (two bytes)
         for (bit_cnt=0; bit_cnt < 16; bit_cnt++) begin    
            @(`DRIVE_EDGE sclk);                           // data is driven out on falling clock edge
            stage = "q_payload";
            o_MOSI = `LOW;                                 // hold MOSI at zero for query payload
            @(`LATCH_EDGE sclk);                           // wait for latching edge  
            rtn_word[15-bit_cnt] = i_MISO;                 // capture slave's return values (MSbit first)
         end
         //<> terminate transaction
         rtn_bytes = rtn_word;                             // copy register to integer output
         if (rtn_bytes == 0)
            status = 0;                                    // normal completion (data waiting)
         else
            status = 1;                                    // no data available 
         stage = "q_stop";
         spi_clk_en  = !SCL_RUN;                           // stop clock 
         #(ts_CLK2CS);                                     // required protocol timing delay
         o_EN        = `HIGH;                              // halt bus transaction
         o_MOSI      = IDLE_LVL;                           // return to default rest
         stage = "idle";
      end
   endtask


   

   

   //<> ------------------------------------------------------------------------   
   //<> gated clock driver for USB SPI interface clock
   //<> ------------------------------------------------------------------------   
   initial begin : SerialSCLK_driver
      sclk = `HIGH;                             // while inactive, clock output is idled
      #(10);                                    // offset from start of simulation
      //<> loop until end of sim
      while (1) begin                           
         sclk = `HIGH;                          // while inactive, clock output is set to idle level
         wait (spi_clk_en == SCL_RUN);          // suspend until gating control flag is set
         ->sclk_started_evnt;                   // flag that sclk now running
         sclk = 1'b0;                           // ground clock to prep Slave interface
         //<> while transaction is in progress (enabled)....
         #(SPI_CLK_PERIOD/2);                   // delay for half-period of clock
         while (spi_clk_en == SCL_RUN)  begin 
            sclk = ~sclk;                       // toggle clock
            #(SPI_CLK_PERIOD/2);                // delay for half-period of clock
         end
         //<> check if end of cycle occured in LOW portion of CLK before stopping
         if (sclk == `LOW) begin                     
            sclk = ~sclk;                       // ensure we cleanly finish last clk low dutycycle and go high
            #(SPI_CLK_PERIOD/2);                // delay for half-period of clock
         end
         ->sclk_stopped_evnt;                   // flag that sclk now stopped
      end
   end  
   
   //<> map internal clock to output port
   assign o_SCL = sclk;  
   
//<>----------------------------------------------------------------
//<> TIMING MONITORS
//<>----------------------------------------------------------------
   
   //<>----------------------------------------------------------------
   //<> Monitor the CLK/DATA transaction setup/hold timing    
   //<>----------------------------------------------------------------
   reg d_su_flag, d_hld_flag;

   specify
      // <> MISO clk/data setup/hold
      $setup(i_MISO           , `LATCH_EDGE o_SCL, ts_MISO_Dsu , d_su_flag );
      $hold(`LATCH_EDGE o_SCL  , i_MISO          , ts_MISO_Dhld, d_hld_flag);
   endspecify
      
      // <> Fault output monitors for above specify triggers
      always @(d_su_flag)    `SIM.printError(BFM_NAME, "SPI MISO setup timing violation detected. " );
      always @(d_hld_flag)   `SIM.printError(BFM_NAME, "SPI MISO hold timing violation detected. " );

endmodule 

//<> COMPONENT INSTANCE TEMPLATE

   // //<>--------------------------------------------------------------------
   // //<> SPI_B Master BFM 
   // //<>
   // bfm_spi_host_master
      // #( .BFM_NAME            ("bfm_spi_host_master"),
         // .SPI_CLK_PERIOD      (100ns),    // SPI SCL period (ns)
         // .QUERY_RETRY_LIMIT   (8),        // maximum number of SPI query requests to retry before failing
         // .SILENT              (0),        // if true, suppress `SIM.printMessage outputs
         // .IDLE_LVL            (1'b0)      // default logic level (not user adjustable)
      // ) bfm_spi_host_master_inst
      // (
         // .o_SCL   (),     // clock output 
         // .i_MISO  (),     // data in wire
         // .o_MOSI  (),     // data out wire
         // .o_EN    ()      // enable out (optional)
      // );
      
  