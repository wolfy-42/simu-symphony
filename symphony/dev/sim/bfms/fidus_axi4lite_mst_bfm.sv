//---------------------------------------------------------------------------//
//
// Copyright (C) 2015 Fidus Systems Inc.
// 
// Project       : simu
// Author        : Kevin Eckstrand
// Created       : 2015-04-23 
//---------------------------------------------------------------------------//
//---------------------------------------------------------------------------//
// Description   : BFM package that contains class acting as AXI4-lite master.
//               Writes and reads are initiated by user and follow AXI4-lite
//               protocol.
//               Errors are flagged via assertions.
//               Contains the following functions / tasks
//                 - new
//                 - fSetTransactionMessagingOnOff
//                 - fSetDebugMessagingOnOff
//                 - fSetWrErrorChkOnOff
//                 - fSetRdErrorChkOnOff
//                 - fSetWrRespReadyLatency
//                 - fSetRdRespReadyLatency
//                 - fSetTransactionTimeoutValues
//                 - tReadModWriteAXI4Lite
//                 - tReadAXI4LiteWithDataCheck
//                 - tReadAXI4Lite
//                 - tReadAXI4LiteWithStatus
//                 - tWriteAXI4Lite
//                 - tWriteAXI4LiteWithStatus
//                 - tWaitForPosClk
//                 - tWaitForNegClk
//                 - tWaitForDrvEdge
//                 - tWaitForAWReady
//                 - tWaitForWReady
//                 - tWaitForARReady
//                 - tWaitForBValid
//                 - tWaitForRValid
//                 - tWaitForChannelIdle
//                 - fSetTimeoutCntrValue
//                 - tCheckWriteResponseStability
//                 - tCheckReadResponseStability
//               Package also contains AXI4-lite interface type definition,
//               same interface type definition as used by the BFM class.
//
//  Updated      : 2018-10-10 / Kevin E.
//               - Added
//                 - tReadModWriteAXI4Lite
//                 - tReadAXI4LiteWithDataCheck
//---------------------------------------------------------------------------//

package fidus_axi4lite_mst_bfm_pkg;

import sim_management_pkg::*; 

class fidus_axi4lite_mst_bfm # (
   AWIDTH = 32,
   DWIDTH = 32,                 // must be divisible by 8
   OUTPUT_DRV_EDGE = "rise",    // "fall" for falling edge, otherwise assumes rising edge
   OUTPUT_DRV_DLY = 0);
   sim_management       s;
   string                 CLASS_NAME;
   virtual axi4lite_intf #(.AWIDTH(AWIDTH),.DWIDTH(DWIDTH)) io;
   logic [AWIDTH-1:0]     awaddr;             // write address bus output                
   logic                  awvalid;            // write address valid output, assertion indicates address can be sampled by slave
   logic [DWIDTH-1:0]     wdata;              // write data bus output
   logic [(DWIDTH/8)-1:0] wstrb;              // write data strobe output, indicates which bytes are valid on data bus
   logic                  wvalid;             // write data valid output, assertion indicates data can be sampled by slave
   logic [1:0]            bresp;              // write response status input, indicates success/error of write transaction
   logic                  bready;             // write response ready output, indicates master can accept response transaction if ready
   logic [AWIDTH-1:0]     araddr;             // read address bus output
   logic                  arvalid;            // read address valid output, assertion indicates address can be sampled by slave
   logic [DWIDTH-1:0]     rdata;              // read data bus input
   logic [1:0]            rresp;              // read response status input, indicates success/error of read transaction
   logic                  rready;             // read response valid input, indicates master can accept data/response transaction if ready
   int                    bready_latency;     // latency associated with master bready assertion in write response transaction
   int                    rready_latency;     // latency associated with master rready assertion in read transaction
   int                    read_timeout;       // specifies # of clock cycles beyond theoretical minimum before
   int                    write_timeout;      //      aborting read or write transaction, neg value specifies no timeout
   logic                  dbg_print_status;   // when set, debug messaging will be printed 
   logic                  messaging_status;   // when set, user message will be printed at termination of AXI4-lite transaction
   logic                  chk_wr_error_en;    // when set, write transactions will include error checking
   logic                  chk_rd_error_en;    // when set, read transactions will include error checking
   logic                  channel_busy;
   int                    timeout_counter;

      // other AXI4-Lite signals not represented by internal variables
      //                           awready       write address ready input, indicates slave can accept write address transaction
      //                           wready        write data ready input, indicates slave can accept write data transaction
      //                           bvalid        write response valid input, assertion indicates write response status can be sampled by master
      //                           arready       read address ready input, indicates slave can accept read address transaction
      //                           rvalid        read data valid signal, assertion indicates read data/response can be sampled by master


   //////////////////////////////////////////////////////////////////////////////////
   // function new
   //     Constructor
   //////////////////////////////////////////////////////////////////////////////////

   function new (
      string                name = "fidus_axi4lite_mst_bfm",
      virtual axi4lite_intf #(.AWIDTH(AWIDTH),.DWIDTH(DWIDTH)) io);
      this.CLASS_NAME     = name;
      this.io             = io;
      // default variable states
      awaddr              = 'h0;
      awvalid             = 'b0;
      wdata               = 'h0;
      wstrb               = 'b0;
      wvalid              = 'h0;
      bresp               = 'h0;
      bready              = 'b0;
      araddr              = 'h0;
      arvalid             = 'h0;
      rdata               = 'h0;
      rresp               = 'b0;
      rready              = 'b0;
      bready_latency      = 0;
      rready_latency      = 0;
      read_timeout        = -1;
      write_timeout       = -1;
      dbg_print_status    = 0;
      messaging_status    = 1;
      chk_wr_error_en     = 0;
      chk_rd_error_en     = 0;
      channel_busy        = 0;
      timeout_counter     = -1;
      // default drive of IO
      io.awaddr           = 'h0;
      io.awvalid          = 'b0;
      io.wdata            = 'h0;
      io.wstrb            = 'b0;
      io.wvalid           = 'h0;
      io.bready           = 'b0;
      io.araddr           = 'h0;
      io.arvalid          = 'h0;
      io.rready           = 'b0;
      // launch looping check tasks
      fork
         tCheckWriteResponseStability();
         tCheckReadResponseStability();
      join_none
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetTransactionMessagingOnOff
   //     Enables/disables log messaging associated with read & write transactions
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetTransactionMessagingOnOff(
      input logic messaging_status);
      s.printMessage(CLASS_NAME,$sformatf("Turning transaction logging %0s, was previously set %0s",
         ((messaging_status) ? "ON" : "OFF"), ((this.messaging_status) ? "ON" : "OFF")));
      this.messaging_status = messaging_status;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetDebugMessagingOnOff
   //     Enables/disables debug messaging associated with events, state
   //       transitions, etc  (intended for debug only)
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetDebugMessagingOnOff(
      input logic dbg_print_status);
      s.printMessage(CLASS_NAME,$sformatf("Turning debug logging %0s, was previously set %0s",
         ((dbg_print_status) ? "ON" : "OFF"), ((this.dbg_print_status) ? "ON" : "OFF")));
      this.dbg_print_status = dbg_print_status;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetWrErrorChkOnOff
   //     Enables/disables check of write response status for errors
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetWrErrorChkOnOff(
      input logic chk_wr_error_enable_status);
      s.printMessage(CLASS_NAME,$sformatf("Turning write error check & reporting %0s, was previously set %0s",
         ((chk_wr_error_enable_status) ? "ON" : "OFF"), ((this.chk_wr_error_en) ? "ON" : "OFF")));
      this.chk_wr_error_en = chk_wr_error_enable_status;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetRdErrorChkOnOff
   //     Enables/disables check of read response status for errors
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetRdErrorChkOnOff(
      input logic chk_rd_error_enable_status);
      s.printMessage(CLASS_NAME,$sformatf("Turning write error check & reporting %0s, was previously set %0s",
         ((chk_rd_error_enable_status) ? "ON" : "OFF"), ((this.chk_rd_error_en) ? "ON" : "OFF")));
      this.chk_rd_error_en = chk_rd_error_enable_status;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetWrRespReadyLatency
   //     Sets the latency associated with write response ready signal assertion
   //       measured in clk edges following the assertion of write address valid
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetWrRespReadyLatency(
      input int bready_latency);
      s.printMessage(CLASS_NAME,$sformatf(
         "Setting write response channel ready signal latency to %0d, was previously %0d",
         bready_latency, this.bready_latency));
      this.bready_latency = bready_latency;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetRdRespReadyLatency
   //     Sets the latency associated with read response ready signal assertion
   //       measured in clk edges following the assertion of read address valid
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetRdRespReadyLatency(
      input int rready_latency);
      s.printMessage(CLASS_NAME,$sformatf(
         "Setting read channel ready signal latency to %0d, was previously %0d",
         rready_latency, this.rready_latency));
      this.rready_latency = rready_latency;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetTransactionTimeoutValues
   //     Sets the timeout values for various transactions
   //     Specifies # of clk cycles of slave driven latency allowed
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetTransactionTimeoutValues(
      input int read_timeout,
      input int write_timeout);
      s.printMessage(CLASS_NAME,$sformatf(
         "Setting allowable latencies to %0d%s for read, %0d%s for write", read_timeout,
         ((read_timeout < 0) ? " (no timeout)" : ""),  write_timeout,
         ((write_timeout < 0) ? " (no timeout)" : "")));
      this.read_timeout = read_timeout;
      this.write_timeout = write_timeout;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // task tReadModWriteAXI4Lite
   //     Initiates AXI4-lite read transaction followed by AXI4-lite write of
   //       same value with bit fields modified as per user control
   //////////////////////////////////////////////////////////////////////////////////

   task tReadModWriteAXI4Lite(
      input  [AWIDTH-1:0] addr,
      input  [DWIDTH-1:0] wr_data_partial,      // data to overwrite existing (combined with mask)
      input  [DWIDTH-1:0] wr_data_mask,         // set ignore/preserve bits to 1
      output [DWIDTH-1:0] orig_rd_data);

      logic [DWIDTH-1:0] rd_data_int;
      tReadAXI4Lite(addr, rd_data_int);
      tWriteAXI4Lite(addr, ( (rd_data_int&wr_data_mask) | wr_data_partial) );
      orig_rd_data = rd_data_int;
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tReadAXI4LiteWithDataCheck
   //     Initiates AXI4-lite read transaction as per tReadAXI4Lite, does additional
   //       pass/fail check with expected value (and mask for don't care bits)
   //////////////////////////////////////////////////////////////////////////////////

   task tReadAXI4LiteWithDataCheck(
      input  [AWIDTH-1:0] rd_addr,
      output [DWIDTH-1:0] rd_data,
      input  [DWIDTH-1:0] rd_data_expected,     // set expected value
      input  [DWIDTH-1:0] rd_data_mask = 'h0,   // set don't care bits to 1
      input            pass_en = 0);         // 0 - generate error on failure only
                                             // 1 - generates pass if successful
      logic [DWIDTH-1:0] rd_data_int;
      tReadAXI4Lite(rd_addr, rd_data_int);
      if ( ( (rd_data_int^rd_data_expected) & (~rd_data_mask) ) != 0 )
          s.printError(CLASS_NAME,$sformatf("AXI read of Addr %X returned value %X, expecting %X (mask %X)", rd_addr, rd_data_int, rd_data_expected, rd_data_mask));
      else if (pass_en!=0)
          s.printPass(CLASS_NAME,$sformatf("AXI read of Addr %X returned value %X matches expected value %X (mask %X)", rd_addr, rd_data_int, rd_data_expected, rd_data_mask));
      rd_data = rd_data_int;
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tReadAXI4Lite
   //     Initiates AXI4-lite read transaction across connected interface (same as
   //       tReadAXI4LiteWithStatus) without returning response status
   //////////////////////////////////////////////////////////////////////////////////

   task tReadAXI4Lite(
      input  [AWIDTH-1:0] rd_addr,
      output [DWIDTH-1:0] rd_data);
      logic [1:0] dummy_rd_resp_status;
      tReadAXI4LiteWithStatus(rd_addr, rd_data, dummy_rd_resp_status);
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tReadAXI4LiteWithStatus
   //     Initiates AXI4-lite read transaction across connected interface
   //     Uses following procedure
   //       Waits until previous transaction is finished
   //       Drive address & address valid onto bus
   //       Stop driving address & address valid once address ready asserted
   //       Drive read response ready once both address & data deasserted
   //       Stop driving read response ready once read response valid asserted
   //       Store read response data & status code
   //     If error checking is enabled, will set error condition unless slave
   //       returns "OK" error code (00) for read response status
   //     Will set error condition if timeout occurs
   //////////////////////////////////////////////////////////////////////////////////

   task tReadAXI4LiteWithStatus(
      input  [AWIDTH-1:0] rd_addr,
      output [DWIDTH-1:0] rd_data,
      output [1:0]        rd_resp_status);
      logic arready_timeout, rvalid_timeout;
      int rready_latency_cntr;
      rready_latency_cntr = rready_latency;  // read in latency value for local use
      // latch in port fields
      this.araddr = rd_addr;
      // wait until previous transaction is complete
      tWaitForChannelIdle();
      channel_busy = 1;  // claim channel
      // drive address & data & strobe onto interface (along with valid signals)
      tWaitForDrvEdge();
      io.araddr = this.araddr;
      io.arvalid = 1'b1;
      // block until completion of address write & data write
      fSetTimeoutCntrValue(read_timeout);
      tWaitForARReady(arready_timeout); // takes minimum 1 clk cycle
      if (OUTPUT_DRV_EDGE == "fall")
         tWaitForDrvEdge();
      io.araddr = 'h0;
      io.arvalid = 1'b0;
      // address read transaction has occurred, indicate readiness for read response
      while (rready_latency_cntr > 0) begin
         // if latency defined, wait requested number of cycles first
         tWaitForDrvEdge();
         rready_latency_cntr--;
      end
      io.rready = 1'b1;
      tWaitForRValid(rvalid_timeout); // takes minimum 1 clk cycle
      rdata = io.rdata;
      rresp = io.rresp;
      if (OUTPUT_DRV_EDGE == "fall")
         tWaitForDrvEdge();
      io.rready = 1'b0;

      if ((chk_rd_error_en) && (rresp != 2'b00))
         s.printError(CLASS_NAME,$sformatf("Illegal read response code of %b received, decodes as %0s", rresp,
         ((rresp == 2'b01) ? "Exclusive Access OK which is not allowed on AXI4-Lite" :
         ((rresp == 2'b10) ? "Slave Error (slave signaling of an error condition)" :
                             "Decode Error (often indicates address does not exist)"))));
      
      // ensure at least a cycle of bus inactivity (no burst support)
      tWaitForDrvEdge();
      channel_busy = 0;

      if (arready_timeout || rvalid_timeout)
         s.printError(CLASS_NAME,$sformatf(
            "Read transaction timeout! Slave introduced latency more than %0d additional clk cycles", read_timeout));
      else begin
         rd_resp_status = rresp;
         rd_data = rdata;
         if (messaging_status)
            s.printMessage(CLASS_NAME,$sformatf("AXI READ     ADDR =   %X     DATA = %X", rd_addr, rd_data));
      end

   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWriteAXI4Lite
   //     Initiates AXI4-lite write transaction across connected interface (same as
   //       tWriteAXI4LiteWithStatus) without returning response status
   //////////////////////////////////////////////////////////////////////////////////

   task tWriteAXI4Lite(
      input [AWIDTH-1:0]     wr_addr,
      input [DWIDTH-1:0]     wr_data,
      input [(DWIDTH/8)-1:0] wr_data_str = {(DWIDTH/8){1'b1}});  // optional input
      logic [1:0] dummy_wr_resp_status;
      tWriteAXI4LiteWithStatus(wr_addr, wr_data, dummy_wr_resp_status);
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWriteAXI4LiteWithStatus
   //     Initiates AXI4-lite write transaction across connected interface
   //     Uses following procedure
   //       Waits until previous transaction is finished
   //       Drive address & address valid & data & data valid onto bus
   //       Stop driving address & address valid once address ready asserted
   //       Stop driving data & data valid once data ready asserted
   //       Drive write response ready once both address & data deasserted
   //       Stop driving write response ready once write response valid asserted
   //       Store write response status code
   //     If error checking is enabled, will set error condition unless slave
   //       returns "OK" error code (00) for write response status
   //     Will set error condition if timeout occurs
   //     User can optionally specify asserted strobes if intent is to send only
   //       a subset of bytes, default is to assert all strobes
   //////////////////////////////////////////////////////////////////////////////////

   task tWriteAXI4LiteWithStatus(
      input  [AWIDTH-1:0] wr_addr,
      input  [DWIDTH-1:0] wr_data,
      output [1:0]        wr_resp_status,
      input [(DWIDTH/8)-1:0] wr_data_str = {(DWIDTH/8){1'b1}});  // optional input
      logic awready_timeout, wready_timeout, bvalid_timeout;
      int bready_latency_cntr;
      bresp = 'h0;
      bready_latency_cntr = bready_latency;  // read in latency value for local use
      // latch in port fields
      this.awaddr = wr_addr;
      this.wdata = wr_data;
      this.wstrb = wr_data_str;
      // wait until previous transaction is complete
      tWaitForChannelIdle();
      channel_busy = 1;  // claim channel
      // drive address & data & strobe onto interface (along with valid signals)
      tWaitForDrvEdge();
      io.awaddr = this.awaddr;
      io.awvalid = 1'b1;
      io.wdata = this.wdata;
      io.wstrb = this.wstrb;
      io.wvalid = 1'b1;
      // block until completion of address write & data write
      fSetTimeoutCntrValue(write_timeout);
      fork
         begin
            tWaitForAWReady(awready_timeout); // takes minimum 1 clk cycle
            if (OUTPUT_DRV_EDGE == "fall")
               tWaitForDrvEdge();
            io.awaddr = 'h0;
            io.awvalid = 1'b0;
         end
         begin
            tWaitForWReady(wready_timeout); // takes minimum 1 clk cycle
            if (OUTPUT_DRV_EDGE == "fall")
               tWaitForDrvEdge();
            io.wdata = 'h0;
            io.wstrb = 'h0;
            io.wvalid = 1'b0;
         end
      join  // both responses are required before continuing
      // both address write & data write transactions have occurred, indicate readiness for write response
      while (bready_latency_cntr > 0) begin
         // if latency defined, wait requested number of cycles first
         tWaitForDrvEdge();
         bready_latency_cntr--;
      end
      io.bready = 1'b1;
      tWaitForBValid(bvalid_timeout); // takes minimum 1 clk cycle
      bresp = io.bresp;
      if (OUTPUT_DRV_EDGE == "fall")
         tWaitForDrvEdge();
      io.bready = 1'b0;

      if ((chk_wr_error_en) && (bresp != 2'b00))
         s.printError(CLASS_NAME,$sformatf("Illegal write response code of %b received, decodes as %0s", bresp,
         ((bresp == 2'b01) ? "Exclusive Access OK which is not allowed on AXI4-Lite" :
         ((bresp == 2'b10) ? "Slave Error (slave signaling of an error condition)" :
                             "Decode Error (often indicates address does not exist)"))));
      
      // ensure at least a cycle of bus inactivity (no burst support)
      tWaitForDrvEdge();
      channel_busy = 0;

      if (awready_timeout || wready_timeout || bvalid_timeout)
         s.printError(CLASS_NAME,$sformatf(
            "Write transaction timeout! Slave introduced latency more than %0d additional clk cycles", write_timeout));
      else begin
         wr_resp_status = bresp;
         if (messaging_status)
            s.printMessage(CLASS_NAME,$sformatf("AXI WRITE    ADDR =   %X     DATA = %X", wr_addr, wr_data));
      end

   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForPosClk
   //     Blocks until clk rising edge
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForPosClk();
      forever begin
         @(posedge io.aclk);
         break;
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForNegClk
   //     Blocks until clk rising edge
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForNegClk();
      forever begin
         @(negedge io.aclk);
         break;
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForDrvEdge
   //     Blocks until clk edge used to drive output
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForDrvEdge();
      if (OUTPUT_DRV_EDGE == "fall")
         tWaitForNegClk();
      else
         tWaitForPosClk();
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForAWReady
   //     Blocks until clk rising edge with 'awready' signal asserted
   //     Returns error code if user-defined timeout exceeded, error handling must
   //       be implemented at higher level
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForAWReady(
      output logic timeout_occurred);
      int additional_write_cycles = 0;
      timeout_occurred = 0;
      forever begin
         tWaitForPosClk();
         if (io.awready) begin
            // update internal timeout counter with additional cycles incurred
            //   in this part of the overall transaction
            this.timeout_counter = this.timeout_counter - additional_write_cycles;
            break;
         end else if (this.timeout_counter >= 0) begin
            // only do this check if write_timeout value set to non-negative value
            additional_write_cycles++;
            if (additional_write_cycles > this.timeout_counter) begin
               timeout_occurred = 1;
               this.timeout_counter = 0;
               break;
            end
         end
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForWReady
   //     Blocks until clk rising edge with 'wready' signal asserted
   //     Returns error code if user-defined timeout exceeded, error handling must
   //       be implemented at higher level
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForWReady(
      output logic timeout_occurred);
      int additional_write_cycles = 0;
      timeout_occurred = 0;
      forever begin
         tWaitForPosClk();
         if (io.wready) begin
            // update internal timeout counter with additional cycles incurred
            //   in this part of the overall transaction
            this.timeout_counter = this.timeout_counter - additional_write_cycles;
            break;
         end else if (this.timeout_counter >= 0) begin
            // only do this check if write_timeout value set to non-negative value
            additional_write_cycles++;
            if (additional_write_cycles > this.timeout_counter) begin
               timeout_occurred = 1;
               this.timeout_counter = 0;
               break;
            end
         end
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForARReady
   //     Blocks until clk rising edge with 'arready' signal asserted
   //     Returns error code if user-defined timeout exceeded, error handling must
   //       be implemented at higher level
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForARReady(
      output logic timeout_occurred);
      int additional_read_cycles = 0;
      timeout_occurred = 0;
      forever begin
         tWaitForPosClk();
         if (io.arready) begin
            // update internal timeout counter with additional cycles incurred
            //   in this part of the overall transaction
            this.timeout_counter = this.timeout_counter - additional_read_cycles;
            break;
         end else if (this.timeout_counter >= 0) begin
            // only do this check if read_timeout value set to non-negative value
            additional_read_cycles++;
            if (additional_read_cycles > this.timeout_counter) begin
               timeout_occurred = 1;
               this.timeout_counter = 0;
               break;
            end
         end
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForBValid
   //     Blocks until clk rising edge with 'bvalid' signal asserted
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForBValid(
      output logic timeout_occurred);
      int additional_write_cycles = 0;
      timeout_occurred = 0;
      forever begin
         tWaitForPosClk();
         if (io.bvalid)
            break;
         else if (this.timeout_counter >= 0) begin
            // only do this check if write_timeout value set to non-negative value
            additional_write_cycles++;
            if (additional_write_cycles > this.timeout_counter) begin
               timeout_occurred = 1;
               break;
            end
         end
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForRValid
   //     Blocks until clk rising edge with 'rvalid' signal asserted
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForRValid(
      output logic timeout_occurred);
      int additional_read_cycles = 0;
      timeout_occurred = 0;
      forever begin
         tWaitForPosClk();
         if (io.rvalid)
            break;
         else if (this.timeout_counter >= 0) begin
            // only do this check if read_timeout value set to non-negative value
            additional_read_cycles++;
            if (additional_read_cycles > this.timeout_counter) begin
               timeout_occurred = 1;
               break;
            end
         end
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tWaitForChannelIdle
   //     Blocks until AXI4-lite channel is available
   //////////////////////////////////////////////////////////////////////////////////

   task tWaitForChannelIdle();
      wait(this.channel_busy == 0);
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // function fSetTimeoutCntrValue
   //     Sets the initial value to be used for timeout error checking associated
   //       with subsequent read or write transaction
   //////////////////////////////////////////////////////////////////////////////////

   function void fSetTimeoutCntrValue(
      input int timeout_value);
      this.timeout_counter = timeout_value;
   endfunction


   //////////////////////////////////////////////////////////////////////////////////
   // task tCheckWriteResponseStability
   //     Checks that write response code does not change while valid is asserted,
   //       reports error if change is captured
   //////////////////////////////////////////////////////////////////////////////////

   task tCheckWriteResponseStability();
      logic       prev_bvalid = 0;
      logic [1:0] starting_bresp;
      forever begin
         tWaitForPosClk();
         if (!prev_bvalid && io.bvalid)  // new bvalid assertion, sample initial response code
            starting_bresp = io.bresp;
         else if (prev_bvalid && io.bvalid)  // bvalid continuously asserted over multiple clocks
            if (starting_bresp != io.bresp)  // check to ensure response code doesn't change
               s.printError(CLASS_NAME,$sformatf(
                  "Write response code changed from %b to %b while valid signal continuously asserted",
                  starting_bresp, io.bresp));
      end
   endtask


   //////////////////////////////////////////////////////////////////////////////////
   // task tCheckReadResponseStability
   //     Checks that read response data & code does not change while valid is
   //       asserted, reports error if change is captured
   //////////////////////////////////////////////////////////////////////////////////

   task tCheckReadResponseStability();
      logic              prev_rvalid = 0;
      logic [1:0]        starting_rresp;
      logic [DWIDTH-1:0] starting_rdata;
      forever begin
         tWaitForPosClk();
         if (!prev_rvalid && io.rvalid) begin  // new bvalid assertion, sample initial response code
            starting_rresp = io.rresp;
            starting_rdata = io.rdata;
         end else if (prev_rvalid && io.rvalid) begin  // bvalid continuously asserted over multiple clocks
            if (starting_rresp != io.rresp)  // check to ensure response code doesn't change
               s.printError(CLASS_NAME,$sformatf(
                  "Read response code changed from %b to %b while valid signal continuously asserted",
                  starting_rresp, io.rresp));
            if (starting_rdata != io.rdata)  // check to ensure response code doesn't change
               s.printError(CLASS_NAME,$sformatf(
                  "Read data changed from %x to %x while valid signal continuously asserted",
                  starting_rdata, io.rdata));
         end
      end
   endtask


endclass

endpackage


   //////////////////////////////////////////////////////////////////////////////////
   // interface type axi4lite_intf
   //     Simple signal bundle representing AXI4-lite bus.
   //     No ports, no modports, no clocking.
   //////////////////////////////////////////////////////////////////////////////////

interface axi4lite_intf #(
   AWIDTH = 32,
   DWIDTH = 32);
      // AXI-Lite clock & reset
   logic                  aclk;    // common  clock
   logic                  aresetn; // common  active low synchronous reset
      // AXI-Lite write address channel
   logic [AWIDTH-1:0]     awaddr;  // m->s    address bus
   logic                  awvalid; // m->s    valid signal, assertion indicates address can be sampled
   logic                  awready; // s->m    ready signal, indicates slave can accept address transaction
      // AXI-Lite write data channel
   logic [DWIDTH-1:0]     wdata;   // m->s    data bus
   logic [(DWIDTH/8)-1:0] wstrb;   // m->s    strobes, indicates which bytes are valid on data bus
   logic                  wvalid;  // m->s    valid signal, assertion indicates data can be sampled
   logic                  wready;  // s->m    ready signal, indicates slave can accept data transaction
      // AXI-Lite write response channel
   logic [1:0]            bresp;   // s->m    response status, indicates success/error of write transaction
   logic                  bvalid;  // s->m    valid signal, assertion indicates response status can be sampled
   logic                  bready;  // m->s    ready signal, indicates master can accept response transaction
      // AXI-Lite read address channel
   logic [AWIDTH-1:0]     araddr;  // m->s    address bus
   logic                  arvalid; // m->s    valid signal, assertion indicates address can be sampled
   logic                  arready; // s->m    ready signal, indicates slave can accept address transaction
      // AXI-Lite read data channel
   logic [DWIDTH-1:0]     rdata;   // s->m    data bus
   logic                  rvalid;  // s->m    valid signal, assertion indicates data can be sampled
   logic [1:0]            rresp;   // s->m    response status, indicates success/error of read transaction
   logic                  rready;  // m->s    ready signal, indicates master can accept data/response transaction

   modport mst  (input   aclk, aresetn, awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid,            // master
                 output  awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr, arvalid, rready);
   modport slv  (input   aclk, aresetn, awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr,            // slave
                         arvalid, rready,
                 output  awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid);
   modport mon  (input   aclk, aresetn, awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr,            // monitor
                         arvalid, rready, awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid);

endinterface

// example declaration
//    axi4lite_intf #(.AWIDTH(8), .DWIDTH(16)) mst2slv_axi4lite_channel;

