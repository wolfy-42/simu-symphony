//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_LTC2492_ADC.v
//Project     : VIP
//Author      : Arnold Balisch
//Created     : Nov 29, 2013
//--------------------------------------------------------------------
//Description : BFM and Monitor for 2/4 channel LTC2492 ADC
//  - as per specification in Datasheet, SPI transactions output PREVIOUS 
//    sampled Channel inputs.
// NOTES:
//    i_a2d_value/1 --> inputs latched on rising edge of i_csn input, and 
//                          should be stable for one i_sclk period before and after.
//    NOTE: if input is differential, only positive a2d_value used.
//
// datasheet: http://www.linear.com/product/LTC2492
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2015-07-07 19:39:30 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

  module bfm_LTC2492_ADC
   #( parameter BFM_NAME         = "bfm_LTC2492_ADC ",      // instance name for logfile message prefexing
      parameter SCK_PERIOD       = 333,       // period of SCK clock input (ns)
      parameter CONV_TIME        = 1_000,                   // delay for conversion time emulation (ns)
      parameter SILENT           = 0,                       // mechanism to squelch transcript logging of messages
      parameter FADC_FRAME_SIZE  = 32,                      // full frame transfer size (bits)  << DO NOT CHANGE >>
      parameter NUM_DATA_BITS    = 24                       // number of sample resolution      << DO NOT CHANGE >>)
   )
   (
      //<> Device SPI port
      input wire  i_sclk ,                                        // transfer clock
      input wire  i_csn ,                                         // conversion enable
      input wire  i_sdi  ,                                        // serial in shifter 
      output reg  o_sdo  = 0,                                     // serial out shifter (POR default low)
      //<> testbench inputs
      input integer i_a2d_value_ch0,       // "analog" value to output on SDO (2's complement )
      input integer i_a2d_value_ch1,       // "analog" value to output on SDO (2's complement )
      input integer i_a2d_value_ch2,       // "analog" value to output on SDO (2's complement )
      input integer i_a2d_value_ch3,       // "analog" value to output on SDO (2's complement )
      input integer i_a2d_temp            // "analog" value for internal Temp sensor
   );
   
   localparam CONV_ACT_LVL    = 1;                    // active level of conversion start strobe
   localparam NUM_STATUS_BITS = 3;                    // fixed do not change
   localparam NUM_SUFFIX_BITS = 5;                    // fixed do not change
   // localparam FADC_FRAME_SIZE = (NUM_STATUS_BITS 
                               // + NUM_DATA_BITS 
                               // + NUM_SUFFIX_BITS );    // calculate # bits in a full frame
   
   //<> timing specs (in nanoseconds) from vendor Datahsheet
   localparam ts_CStest_max = SCK_PERIOD;    // hold delay (ns) SDO after falling SCLK 
   localparam ts_SDO_hld = 15;               // hold delay (ns) SDO after falling SCLK 
   localparam ts_SDO_su  = 50;               // setup delay (ns) SDO before falling SCLK
   localparam ts_SDI_hld = 100;              // hold delay (ns) SDI after rising SCLK 
   localparam ts_SDI_su  = 100;              // setup delay (ns) SDI before rising SCLK
   localparam ts_CLK2OUT = ((SCK_PERIOD/2)-ts_SDO_su);    // delay (ns) from SCLK rising edge to SDO data out valid (From datasheet, timing spec "T8")   

   //<> ------------------------------------------------------------
   //<> INTERNAL VARIABLES
   //<> ------------------------------------------------------------
   integer frame_cntr = 0;
   // integer i;     // shift register index pointer
   string msg ;
   reg  [NUM_DATA_BITS-1:0]    dword         = 0; 
   reg  [NUM_DATA_BITS-1:0]    dword_next    = 0; 
   reg  [FADC_FRAME_SIZE-1:0]  cmd_word      = 0; 
   reg  [FADC_FRAME_SIZE-1:0]  cmd_word_next = 0; 
   reg  [NUM_SUFFIX_BITS-1:0]  dword_suffix  = 0; 
   reg  [FADC_FRAME_SIZE-1:0]  sdo_frame     = 0;
   wire [FADC_FRAME_SIZE-1:0]  sdo_full_data;
   integer cmd_ptr      = (FADC_FRAME_SIZE-1) ;   // initialize to MSbit of command frame (data arrives MSB first)
   integer sdo_ptr      = (FADC_FRAME_SIZE-1) ;   // pointer into SDO frame output
   reg conv_sign        = 1;                 // positive = 1, negative =0
   reg conv_sign_next   = 1;                 
   reg int_sdo          = 1'bz;
   reg conv_busy        = 0;                 // 1=conversion still in-progress(busy), 0=done
   integer next_val     = 0;
   wire [3:0] chan_sel;
   event start_conv_evnt;
   
   //<> aliases to specific control bits in SDI frame
   wire c_enable ;            // SDI bit[29]
   wire c_single ;            // SDI bit[28]
   wire c_odd ;               // SDI bit[27]
   wire [2:0] c_mux_addr;     // SDI bit[26:24]
   wire c_en2 ;               // SDI bit[23]
   wire c_im ;                // SDI bit[22]
   wire c_fa ;                // SDI bit[21]
   wire c_fb ;                // SDI bit[20]
   wire c_speed ;             // SDI bit[19]
   
   //================================================================= BODY
      
   //<> ------------------------------------------------------------
   //<> INPUT COMMAND CAPTURE/PROCESSING
   //<> ------------------------------------------------------------

   assign sdo_full_data = {3'b0,dword,dword_suffix};     // for testbench confirmation of full 28bit datavalue

   //<>------------------------------------------------------------
   //<> incoming SDI pointer control
   always @(posedge i_csn or posedge i_sclk ) 
   begin
      if (i_csn == 1'b1) begin                   // chipselect deasserted
         if (cmd_ptr == 0) begin                 // check if full frame was recieved?
            ->start_conv_evnt;                   // full SPI frame recieved, so kick start of analog conversion timer
            cmd_word_next <= cmd_word;            // latch new testcase "analog" value to output during next full SPI trasaction
            if (!SILENT) `SIM.printMessage(BFM_NAME, {"Current command Input ==> value: ", `V2HEXSTR(cmd_word)});
         end
         if (cmd_ptr < 0) begin                  // watch for oversized frame...block SDI latching to avoid array index out-of-bounds errors
            `SIM.printWarning(BFM_NAME, {"Oversized Command Input frame detected"}); 
         end
         cmd_ptr <= (FADC_FRAME_SIZE);           // reset pointer to MSb for next incoming frame (delay to avoid race)
      end
      else begin                                 // i_csn deasserted -- end of frame reached
         cmd_ptr <= cmd_ptr - 1; 
      end
   end 
   
   //<>------------------------------------------------------------
   //<> capture SDI input into cmd_word  
   //  - SAFE as i_sclk is only active during i_csn low
   always 
   begin
      @(posedge i_sclk ) ;
      if (cmd_ptr >= 0) begin                         // safeguard pointer range
         #(ts_SDI_hld) cmd_word[cmd_ptr] = i_sdi;     // left shift MSbit recieved first
      end
   end 

   //<> extract required control flags from previously recieved input frame 
   assign c_enable      = cmd_word[29];
   assign c_single      = cmd_word[28];
   assign c_odd         = cmd_word[27];
   assign c_mux_addr    = cmd_word[26:24];      // extract mux position select from previous input frame
   assign c_en2         = cmd_word[23];
   assign c_im          = cmd_word[22];
   assign c_fa          = cmd_word[21];
   assign c_fb          = cmd_word[20];
   assign c_speed       = cmd_word[19];
 
   //<> ------------------------------------------------------------
   //<> DATA FRAME PROCESSING/OUTPUT
   //<> ------------------------------------------------------------

   // assign dword_suffix = 'b0;  // <<NOTE>> current BFM does not assert these bits

   //<>------------------------------------------------------------
   //<> SAMPLE: 
   //<> - build current output frame (with datasheet sample delay)
   always 
   begin
      @(negedge i_csn);
      dword  = dword_next;                      // latch previous input values for output on *current* SPI transaction
      if (!SILENT) `SIM.printMessage(BFM_NAME, {"Converted Analog value ==> ", `V2HEXSTR(dword)});
      conv_sign = conv_sign_next;
      //<> build up current Frame structure based on previous inputs
      sdo_frame = {conv_busy, 1'b0, conv_sign, dword, dword_suffix};        // build frame to send to SDO pin                
   end 

   //<> waveform signal for testbench confirmation of full 28bit datavalue portion of SDO frame 
   assign sdo_full_data = {3'b0,dword,dword_suffix};     

   //<>------------------------------------------------------------
   //<> Analog input Sampling: 
   //<> - channel selection by current SDI value
   
   //<> build required channel mux selection from current SPI command frame fields
   assign chan_sel = {c_im, c_single, c_odd, c_mux_addr[0]};
   
   //<> capture selected value on BFM "analog" inputs based on SPI command selection 
   always
   begin
      @(start_conv_evnt);     // kicked at end of valid SPI transfer
      //<> latch current input values for output on *next* SPI transaction
      casex (chan_sel)   
         4'b00x0 : next_val = i_a2d_value_ch0;    // diff ch1
         4'b00x1 : next_val = i_a2d_value_ch2;    // diff ch2
         4'b0100 : next_val = i_a2d_value_ch0;    // single ch0
         4'b0101 : next_val = i_a2d_value_ch2;    // single ch2
         4'b0110 : next_val = i_a2d_value_ch1;    // single ch1
         4'b0111 : next_val = i_a2d_value_ch3;    // single ch3
         4'b1xxx : next_val = i_a2d_temp;        // internal temp sensor
      endcase
      dword_next = `MATH.ABS(next_val);         // store as unsigned...sign seperate
      conv_sign_next = (next_val >= 0) ? 1'b1  : 1'b0;   // define sign of input value (positive = 1, negative = 0)
   end

   //<>------------------------------------------------------------
   //<> DATA OUTPUT Parsing (int_sdo)
   //    - SPI frame output 
   //   NOTE: due to gated clock a fork-join construct is used to enable transaction end/abort 
   always
   begin
      if (i_csn === 1'b0) begin  //----- transaction underway
         fork: f_csn_sck            
            begin //-- sdo output if chipselect stays low
               @(posedge i_sclk);        // wait for clock rising...
               if (sdo_ptr > 0) begin
                  int_sdo = #ts_CLK2OUT sdo_frame[sdo_ptr-1];     // assert data onto port with propagation delay (index adjusted to vector range)
               end
               sdo_ptr = sdo_ptr - 1;   // decrement pointer into frame
               disable f_csn_sck;       // escape fork-join
            end
            begin //-- transaction abort or end before next clock?
               @(posedge i_csn);             // wait for chipselect rising (end/abort transaction)
               int_sdo = 1'bz;               // tristate at end of transaction
               sdo_ptr = FADC_FRAME_SIZE-1;  // re-init vector pointer to MSbit at end of chip select (accomadates transaction abort)
               disable f_csn_sck;            // escape fork-join
            end
         join
      end
      else begin        //----- SPI bus idle
         int_sdo = 1'bz;               // tristate at end of transaction
         sdo_ptr = FADC_FRAME_SIZE-1;  // re-init vector pointer to MSbit at end of chip select (accomadates transaction abort)
         @(negedge i_csn);             // pause for next falling edge of Chipselect to reduce simulator overhead
      end
   end

   
   //<>-------------------------------------------- 
   //<> Conversion Busy flag generation
   //  - ensure conv_busy flag set if interval between SPI frames too short
   // time conv_time = 0ns;
   always
   begin
      @(start_conv_evnt);
      conv_busy = 1'b1;    // indicate conversion underway (busy)
      #(CONV_TIME);        // delay for choosen conversion time 
      conv_busy = 1'b0;    // indicate conversion complete (not busy)
   end

   //<> ------------------------------------------------------------
   //<> Define weak high/low logic values for SDO Driver 
   //  - supports Conversion busy flag status mechanism
   //  - (verilog equivalent to VHDL std_logic = 'H' or 'L' logic levels)
   //<> ------------------------------------------------------------
   wire weak_high, weak_low;   // internal nets for weak logic level operations
   pullup(weak_high);
   pulldown(weak_low);

   //<>-------------------------------------------- 
   //<>  SDO Driver 
   //  - conv_busy flag output during CSN pulsing
   //  - int_sdo is tristated when bus is idled...allows weak logic to dominate
   //  - ensure conv_busy flag bit in SDO set if interval between SPI frames too short
   //  (weak logic should only rule when int_sdo is tri-stated (1'bZ))
   always @(*)
   begin
      if (i_csn === 1'b1) begin  // SPI bus idle
         o_sdo = 1'bZ;
      end
      else begin  // chipselect asserted
         if (conv_busy) begin      // conversion still busy 
            o_sdo = (int_sdo === 1'bz) ? weak_high : int_sdo;   
         end
         else begin              // conversion completed/ready for read
            o_sdo = (int_sdo === 1'bz) ? weak_low : int_sdo;   
         end
      end
   end
   
   
  
   
endmodule


//<> -----------------------------Instantiation Template--------------------------------
// //--------------------------------------------------------------------
// //Description : BFM and Monitor for LTC2492 2/4 channel ADC
// //  - as per specification in Datasheet, SPI transactions output PREVIOUS 
// //    sampled Channel inputs.
// bfm_LTC2492_ADC
   // #( .BFM_NAME      ("bfm_LTC2492_ADC "),      // instance name for logfile message prefexing
      // .SCK_PERIOD    (333),                     // period of SCK clock input (ns)
      // .CONV_TIME     (1_000),                   // delay for conversion time emulation (ns)
      // .SILENT        (0)                        // mechanism to squelch transcript logging of messages
   // )
   // bfm_LTC2492_ADC_inst
   // (  //<> Device SPI port
      // .i_sclk (),                               // transfer clock
      // .i_csn  (),                               // conversion enable
      // .i_sdi  (),                               // serial in shifter 
      // .o_sdo  (),                               // serial out shifter (POR default low)
      // //<> testbench inputs      
      // .i_a2d_value_ch0(),                        // "analog" value to output on SDO (2's complement)
      // .i_a2d_value_ch1(),                        // "analog" value to output on SDO (2's complement)
      // .i_a2d_value_ch2(),                        // "analog" value to output on SDO (2's complement)
      // .i_a2d_value_ch3(),                        // "analog" value to output on SDO (2's complement)
      // .i_a2d_temp ()                            // "analog" value to output for internal temp sensor
   // );
 
