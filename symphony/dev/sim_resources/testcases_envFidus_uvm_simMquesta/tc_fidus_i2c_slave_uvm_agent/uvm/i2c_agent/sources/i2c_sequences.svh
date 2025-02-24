//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_sequences.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.16.2023
//
// Description: 
//
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// controller sequences
//----------------------------------------------------------------------
class i2c_basic_data_seq #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_sequence #(i2c_item#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH));

    rand int                        size;
    rand int                        nbr_data_bytes;

    rand logic                      ack;
    rand logic                      rwb;
    rand logic [I2C_ADDR_WIDTH-1:0] addr;
    rand logic [I2C_DATA_WIDTH-1:0] data[];

    i2c_item tr;
    i2c_item tr_rsp;

    constraint c_default {
        soft size < 10000;
        soft nbr_data_bytes < 100;
    }

    constraint c_consistant {
        soft data.size() == nbr_data_bytes;
    }

    `uvm_object_param_utils_begin(i2c_basic_data_seq #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
        `uvm_field_int(size,    UVM_ALL_ON)
        `uvm_field_int(ack,     UVM_ALL_ON)
        `uvm_field_int(rwb,     UVM_ALL_ON)
        `uvm_field_int(addr,    UVM_ALL_ON)
        `uvm_field_int(nbr_data_bytes,    UVM_ALL_ON)
        `uvm_field_array_int(data,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_basic_data_seq");
        super.new(name);
    endfunction // new
    
    virtual task body();
        
        for(int i = 0; i < size; i++) begin
            tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
            void'(tr.randomize() with {size == 1;});
            start_item(tr);
            finish_item(tr);
            get_response(tr_rsp);
        end

    endtask // body

endclass // i2c_basic_data_seq

class i2c_basic_controller_seq extends i2c_basic_data_seq#(7,8);

    constraint c_single {
        soft size == 1;
    }
 
   `uvm_object_param_utils_begin(i2c_basic_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_basic_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        for(int i = 0; i < size; i++) begin
            tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
            void'(tr.randomize() with {size == 1;});
            start_item(tr);
            finish_item(tr);
            get_response(tr_rsp);
        end

    endtask // body
    
endclass // i2c_basic_controller_seq

class i2c_idle_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_idle_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_idle_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        // Start
        tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
        void'(tr.randomize() with {size == 2;});
        start_item(tr);        

        tr.SDA[0] = 1'b1;
        tr.SCL[0] = 1'b0;

        tr.SDA[1] = 1'b1;
        tr.SCL[1] = 1'b1;

        finish_item(tr);
        get_response(tr_rsp);

    endtask // body
    
endclass // i2c_idle_controller_seq


//driving START in 3 transactions as below
//       ____
//SCL __|    
//    ____
//SDA     |__

class i2c_start_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_start_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_start_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        // Start
        tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
        void'(tr.randomize() with {size == 3;});
        start_item(tr);        

        tr.SDA[0] = 1'b1;
        tr.SCL[0] = 1'b0;

        tr.SDA[1] = 1'b1;
        tr.SCL[1] = 1'b1;

        tr.SDA[2] = 1'b0;
        tr.SCL[2] = 1'b1;

        finish_item(tr);
        get_response(tr_rsp);

    endtask // body
    
endclass // i2c_start_controller_seq

//driving STOP in 3 transactions as below
//       ____ 
//SCL __|     
//          __
//SDA _____|
class i2c_stop_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_stop_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_stop_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        // Stop
        tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
        void'(tr.randomize() with {size == 3;});
        start_item(tr);        

        tr.SDA[0] = 1'b0;
        tr.SCL[0] = 1'b0;

        tr.SDA[1] = 1'b0;
        tr.SCL[1] = 1'b1;

        tr.SDA[2] = 1'b1;
        tr.SCL[2] = 1'b1;

        finish_item(tr);
        get_response(tr_rsp);

    endtask // body
    
endclass // i2c_stop_controller_seq

class i2c_addr_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_addr_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_addr_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();
        
        // Addr
        for(int i = 0; i < size; i++) begin
            tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
            void'(tr.randomize() with {size == 2;});
            start_item(tr);
            tr.SDA[0] = addr[(size-1)-i]; // MSB first
            tr.SCL[0] = 1'b0;
            tr.SDA[1] = addr[(size-1)-i]; // MSB first
            tr.SCL[1] = 1'b1;
            finish_item(tr);
            get_response(tr_rsp);
        end

    endtask // body
    
endclass // i2c_addr_controller_seq

class i2c_rwb_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_rwb_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_rwb_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        // RWb        
        tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
        void'(tr.randomize() with {size == 2;});
        start_item(tr);
        tr.SDA[0] = rwb;
        tr.SCL[0] = 1'b0;
        tr.SDA[1] = rwb;
        tr.SCL[1] = 1'b1;
        finish_item(tr);
        get_response(tr_rsp);

    endtask // body
    
endclass // i2c_rwb_controller_seq

class i2c_ack_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_ack_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_ack_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        // Ack
/* -----\/----- EXCLUDED -----\/-----
        tr = new();
        void'(tr.randomize() with {size == 2;});
        start_item(tr);
        tr.update_SDA = 1'b0;
        //tr.SDA[0] = ack;
        tr.SCL[0] = 1'b0;
        //tr.SDA[1] = ack;
        tr.SCL[1] = 1'b1;
        finish_item(tr);
        get_response(tr_rsp);
 -----/\----- EXCLUDED -----/\----- */

        case(rwb)
          0: begin
              tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
              void'(tr.randomize() with {size == 2;});
              start_item(tr);
              tr.update_SDA = 1'b0;
              //tr.SDA[0] = ack;
              tr.SCL[0] = 1'b0;
              //tr.SDA[1] = ack;
              tr.SCL[1] = 1'b1;
              finish_item(tr);
              get_response(tr_rsp);
          end
          1: begin
              tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
              void'(tr.randomize() with {size == 2;});
              start_item(tr);
              tr.SDA[0] = 1'b0;
              tr.SCL[0] = 1'b0;
              tr.SDA[1] = 1'b0;
              tr.SCL[1] = 1'b1;
              finish_item(tr);
              get_response(tr_rsp);
          end
        endcase

    endtask // body
    
endclass // i2c_ack_controller_seq

class i2c_nack_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_nack_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_nack_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        case(rwb)
          0: begin
              tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
              void'(tr.randomize() with {size == 2;});
              start_item(tr);
              tr.update_SDA = 1'b0;
	      //tr.wait_posedge = 1'b0;
              //tr.SDA[0] = ack;
              tr.SCL[0] = 1'b0;
              //tr.SDA[1] = ack;
              tr.SCL[1] = 1'b1;
              finish_item(tr);
              get_response(tr_rsp);
          end
          1: begin
              tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
              void'(tr.randomize() with {size == 2;});
              start_item(tr);
              tr.SDA[0] = 1'b1;
              tr.SCL[0] = 1'b0;
              tr.SDA[1] = 1'b1;
              tr.SCL[1] = 1'b1;
              finish_item(tr);
              get_response(tr_rsp);
          end
        endcase

    endtask // body
    
endclass // i2c_nack_controller_seq

class i2c_send_data_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_send_data_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_send_data_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        //this.print();

        // Bytes
        for(int i = 0; i < I2C_DATA_WIDTH; i++) begin
            tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
            void'(tr.randomize() with {size == 2;});
            start_item(tr);
            tr.SDA[0] = data[0][(I2C_DATA_WIDTH-1)-i]; // MSB first            
            tr.SCL[0] = 1'b0;
            tr.SDA[1] = data[0][(I2C_DATA_WIDTH-1)-i]; // MSB first
            tr.SCL[1] = 1'b1;
            finish_item(tr);
            get_response(tr_rsp);
        end

    endtask // body
    
endclass // i2c_send_data_controller_seq

class i2c_receive_data_controller_seq extends i2c_basic_data_seq#(7,8);

   `uvm_object_param_utils_begin(i2c_receive_data_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_receive_data_controller_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        //this.print();
        
        // Bytes
        for(int i = 0; i < I2C_DATA_WIDTH; i++) begin
            tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
            void'(tr.randomize() with {size == 2;});
            start_item(tr);
            //tr.SDA[0] = data[0][(I2C_DATA_WIDTH-1)-i]; // MSB first            
            //tr.SDA[0] = 1'bz;
            //tr.update_SDA = 1'b0;
            tr.SDA[0] = 1'b1; // Driven by peripherals
            tr.SCL[0] = 1'b0;
            //tr.SDA[1] = data[0][(I2C_DATA_WIDTH-1)-i]; // MSB first
            //tr.SDA[1] = 1'bz;
            tr.SDA[1] = 1'b1; // Driven by peripherals
            tr.SCL[1] = 1'b1;           
            finish_item(tr);

            // Here the driver should have been capturing something
            // we need to fetch and send back
            get_response(tr_rsp);
            data[0][(I2C_DATA_WIDTH-1)-i] = tr_rsp.SDA[1];
        end

    endtask // body
    
endclass // i2c_receive_data_controller_seq

class i2c_command_addr_controller_seq extends i2c_basic_data_seq#(7,8);

    constraint c_single {
        soft size == I2C_ADDR_WIDTH;        
    }

   `uvm_object_param_utils_begin(i2c_command_addr_controller_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_command_addr_controller_seq");
        super.new(name);
        //item_array = new[size];        
    endfunction // new

    virtual task body();

        i2c_idle_controller_seq         idle_controller_seq;
        i2c_start_controller_seq        start_controller_seq;
        i2c_stop_controller_seq         stop_controller_seq;
        i2c_addr_controller_seq         addr_controller_seq;
        i2c_rwb_controller_seq          rwb_controller_seq;
        i2c_ack_controller_seq          ack_controller_seq;
        i2c_nack_controller_seq         nack_controller_seq;
        i2c_send_data_controller_seq    wrdata_controller_seq;
        i2c_receive_data_controller_seq rddata_controller_seq;
                
        idle_controller_seq   = i2c_idle_controller_seq::type_id::create($sformatf("idle"),null);
        start_controller_seq  = i2c_start_controller_seq::type_id::create($sformatf("start"),null);
        stop_controller_seq   = i2c_stop_controller_seq::type_id::create($sformatf("stop"),null);
        addr_controller_seq   = i2c_addr_controller_seq::type_id::create($sformatf("addr"),null);
        rwb_controller_seq    = i2c_rwb_controller_seq::type_id::create($sformatf("rwb"),null);
        ack_controller_seq    = i2c_ack_controller_seq::type_id::create($sformatf("ack"),null);
        nack_controller_seq   = i2c_nack_controller_seq::type_id::create($sformatf("nack"),null);
        wrdata_controller_seq = i2c_send_data_controller_seq::type_id::create($sformatf("send"),null);
        rddata_controller_seq = i2c_receive_data_controller_seq::type_id::create($sformatf("receive"),null);

        //a few idle sequences
        for (int i=0; i<4; i++)
             idle_controller_seq.start(get_sequencer(),this);

        // Start
        `uvm_info("i2c_command_addr_controller_seq",$sformatf("START sequence started!"), UVM_LOW)
         start_controller_seq.start(get_sequencer(),this);
         //$finish;


        // Addr
        addr_controller_seq.size = this.size;
        addr_controller_seq.addr = this.addr;
        addr_controller_seq.start(get_sequencer(),this);

        // RWb
        rwb_controller_seq.rwb = this.rwb;
        rwb_controller_seq.start(get_sequencer(),this);

       `uvm_info("i2c_command_addr_controller_seq",$sformatf("Starting ACK seq"), UVM_DEBUG)
        // ACK or NACK      
        this.ack = 1'b1; // Driven by peripherals
        ack_controller_seq.ack = this.ack;
        ack_controller_seq.rwb = 1'b0;
        ack_controller_seq.start(get_sequencer(),this);

        `uvm_info("i2c_command_addr_controller_seq",$sformatf("ADDR ACK read 1'b%1b!",ack_controller_seq.tr_rsp.SDA[1]), UVM_LOW)
        if (ack_controller_seq.tr_rsp.SDA[1] != 1'b1) begin

            // DATA
            for(int bytes = 0; bytes < nbr_data_bytes; bytes++) begin

                case(rwb)
                  0: begin
                      // Writing
                      `uvm_info("i2c_command_addr_controller_seq",$sformatf("starting wrdata_controller_seq!"), UVM_DEBUG)
      
                      void'(wrdata_controller_seq.randomize(nbr_data_bytes,data) with {nbr_data_bytes == 1;
                                                                                       local::data[bytes] == this.data[0];});    
		      
                      //$finish;
                      wrdata_controller_seq.start(get_sequencer(),this);
                  end
                  1: begin
                      // Reading
                      `uvm_info("i2c_command_addr_controller_seq",$sformatf("starting rddata_controller_seq!"), UVM_DEBUG)
                      void'(rddata_controller_seq.randomize(nbr_data_bytes,data) with {nbr_data_bytes == 1;});
                      rddata_controller_seq.start(get_sequencer(),this);

                      // Here the driver should have been capturing something
                      // we need to fetch and send back
                      //
                      // Needs to retrieve data
                      //
                      //rddata_controller_seq.tr_rsp.print();
                      //rddata_controller_seq.print();
                      this.data[bytes] = rddata_controller_seq.data[0];
                      `uvm_info("i2c_command_addr_controller_seq",$sformatf("rddata_controller_seq received data 0x%0x!",this.data[bytes]), UVM_DEBUG)
                  end
                endcase

                if (rwb == 1 && bytes==nbr_data_bytes-1) begin
                    this.ack = 1'b1; 
                    nack_controller_seq.ack = this.ack;
                    nack_controller_seq.rwb = rwb;
                    `uvm_info("i2c_command_addr_controller_seq",$sformatf("Driving DATA NACK for the last read to stop transaction!"), UVM_DEBUG)
                    nack_controller_seq.start(get_sequencer(),this);
                end
                else begin
                    // ACK 
                    this.ack = 1'b1; // Driven by peripherals
                    ack_controller_seq.ack = this.ack;
                    ack_controller_seq.rwb = rwb;
                    ack_controller_seq.start(get_sequencer(),this);
            	    `uvm_info("i2c_command_addr_controller_seq",$sformatf("DATA ACK read 1'b%1b!",ack_controller_seq.tr_rsp.SDA[1]), UVM_DEBUG)

            	    if (ack_controller_seq.tr_rsp.SDA[1] == 1'b1) begin //if received NACK, then break.
            	        break;
                    end
                end
            end
        end
        // Idle
        //idle_controller_seq.start(get_sequencer(),this);
        
        // Stop
	`uvm_info("i2c_command_addr_controller_seq",$sformatf("STOP sequence started!"), UVM_DEBUG)
        stop_controller_seq.start(get_sequencer(),this);

        //a few idle sequences
        for (int i=0; i<2; i++)
            idle_controller_seq.start(get_sequencer(),this);

    endtask // body
    
endclass // i2c_command_addr_controller_seq

//----------------------------------------------------------------------
// peripheral sequences
//----------------------------------------------------------------------
class i2c_peripheral_seq #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_sequence #(i2c_item#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH));

/* -----\/----- EXCLUDED -----\/-----
    rand int                        size;
    rand int                        nbr_data_bytes;

    rand logic                      ack;
    rand logic                      rwb;
    rand logic [I2C_ADDR_WIDTH-1:0] addr;
    rand logic [I2C_DATA_WIDTH-1:0] data[];

 -----/\----- EXCLUDED -----/\----- */

    i2c_item tr;
    i2c_item tr_rsp;

/* -----\/----- EXCLUDED -----\/-----
    constraint c_default {
        soft size < 10000;
        soft nbr_data_bytes < 100;
    }

    constraint c_consistant {
        soft data.size() == nbr_data_bytes;
    }
 -----/\----- EXCLUDED -----/\----- */

    `uvm_object_param_utils_begin(i2c_peripheral_seq #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
/* -----\/----- EXCLUDED -----\/-----
        `uvm_field_int(size,    UVM_ALL_ON)
        `uvm_field_int(ack,     UVM_ALL_ON)
        `uvm_field_int(rwb,     UVM_ALL_ON)
        `uvm_field_int(addr,    UVM_ALL_ON)
        `uvm_field_array_int(data,    UVM_ALL_ON)
 -----/\----- EXCLUDED -----/\----- */
    `uvm_object_utils_end

    function new(string name = "i2c_peripheral_seq");
        super.new(name);
    endfunction // new
    
    virtual task body();

        //tr = new();
        tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
        void'(tr.randomize());
        start_item(tr);
        finish_item(tr);
        get_response(tr_rsp);

    endtask // body

endclass // i2c_peripheral_seq

class i2c_basic_peripheral_seq extends i2c_peripheral_seq#(7,8);

/* -----\/----- EXCLUDED -----\/-----
    constraint c_single {
        soft size == 1;
    }
 -----/\----- EXCLUDED -----/\----- */
 
   `uvm_object_param_utils_begin(i2c_basic_peripheral_seq)
   `uvm_object_utils_end

    function new(string name = "i2c_basic_peripheral_seq");
        super.new(name);
    endfunction // new

    virtual task body();

        forever begin
        //for(int i = 0; i < 4; i++) begin

            //tr = new();
            tr = i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)::type_id::create("seq_item");
            void'(tr.randomize() with {size == 1;});
            tr.SDA[0] = 1'b0;
            //tr.SCL[0] = 1'bx; // Driven by controller
            //tr.SDA[1] = 1'b1;
            //tr.SCL[1] = 1'bx; // Driven by controller
            start_item(tr);
            finish_item(tr);
            get_response(tr_rsp);

        end

    endtask // body
    
endclass // i2c_basic_peripheral_seq
