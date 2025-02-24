//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_driver.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.12.2023
//
// Description: 
//
//----------------------------------------------------------------------

class i2c_driver #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_driver #(i2c_item#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH));

    i2c_agent #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) m_agent;

    virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) vif;

    i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) tr;
    i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) prev_tr;

    i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) periph_tr;

    bit [I2C_DATA_WIDTH-1:0] data_storage[bit [I2C_ADDR_WIDTH-1:0]];

    bit m_periph_dis_storage_chk_at_addr = 0;

    `uvm_component_param_utils_begin(i2c_driver#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
    `uvm_component_utils_end

    function new(string name, uvm_component parent = null);
        super.new(name,parent);
    endfunction // new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

	//`uvm_info ("i2c_driver",$sformatf("this agent is %0s",m_agent.is_active),UVM_LOW)

        if (!(uvm_config_db#(virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::get(this, "", "vif", vif))) begin
            `uvm_fatal("i2c_driver",$sformatf("Can't find vif %s in uvm_config_db", get_full_name()))
        end
        
    endfunction // build_phase

    //==============================================
    //==============================================
    //==============================================
    // When the agent/config is controlling the bus
    //==============================================
    //==============================================
    //==============================================
    virtual task run_controller();

        vif.controller_cb.SCL_oe <= 1'b1;
        vif.controller_cb.SDA_oe <= 1'b1;

        forever begin

            if(vif.controller_cb.RESET_N == 1'b1) begin

                seq_item_port.get_next_item(req);
                $cast(rsp,req.clone());
                rsp.set_id_info(req);

                this.tr = req;          

                foreach(req.SCL[i]) begin
                    fork
                        begin : SCL
                            drive_cont_scl(req, i);
                        end
                        begin : SDA
                            drive_cont_sda(req, i);
                        end

                        case(req.wait_posedge)
                          0 : @(negedge vif.CLK);
                          1 : @(posedge vif.CLK);
                        endcase

                        // Send back info (since could potentialy contains info from a peripherals)
                        rsp.SCL[i] = vif.SCL;
                        rsp.SDA[i] = vif.SDA;
                        //`uvm_info("i2c_driver.controller",$sformatf("response recorded = 1'b%1b ", rsp.SDA[0]), UVM_DEBUG)

                    join
                end

                seq_item_port.item_done(rsp);

            end
            else begin
                vif.controller_cb.SCL_oe <= 1'b1;
                vif.controller_cb.SDA_oe <= 1'b1;
                @(posedge vif.controller_cb.RESET_N);
                @(posedge vif.CLK);
            end

        end

    endtask // run_controller  

    virtual task drive_cont_scl(ref i2c_item req, int i);
        if(req.update_SCL) begin
            if(req.t_to_SCL_ps > 0) #(req.t_to_SCL_ps*1ps);
            `uvm_info("i2c_driver.controller",$sformatf("driving SCL %0b",req.SCL[i]), UVM_DEBUG)
            vif.controller_cb.SCL_oe <= req.SCL[i];
        end
    endtask // drive_cont_scl

    virtual task drive_cont_sda(ref i2c_item req, int i);
        if(req.update_SDA) begin
            if (req.t_to_SDA_ps > 0) #(req.t_to_SDA_ps*1ps);
            `uvm_info("i2c_driver.controller",$sformatf("driving SDA %0b",req.SDA[i]), UVM_DEBUG)
            vif.controller_cb.SDA_oe <= req.SDA[i];
        end
        else begin
            `uvm_info("i2c_driver.controller",$sformatf("Releasing the SDA bus."), UVM_DEBUG)
            vif.controller_cb.SDA_oe <= 1'b1;
        end
    endtask // drive_cont_sda

    //==============================================
    //==============================================
    //==============================================
    // When the agent/config is answering the bus
    //==============================================
    //==============================================
    //==============================================
    virtual task run_peripheral();

        bit started                      = 0;
        bit new_clk                      = 0;
        bit was_ack                      = 0;
        int count_between_start_and_stop = 0;
        int data_count                   = 0;
        bit rwb                          = 0;
        bit [I2C_ADDR_WIDTH-1:0] addr   = 0;
        bit [I2C_DATA_WIDTH-1:0] data   = 0;
        int addr_offset                  = 0;
        int measured_SCL_period_tmp      = 0;
        int measured_SCL_period          = 0;
        bit read_data_valid              = 1;
        bit stop_received                = 0;

        //vif.SCL_oe <= 1'b0;
        vif.SDA_oe <= 1'b1;

        forever begin

            if(vif.peripheral_cb.RESET_N == 1'b1) begin

                //@(vif.peripheral_cb.SCL or vif.peripheral_cb.SDA);
                //@(posedge vif.CLK);
                @(vif.peripheral_cb);
                measured_SCL_period_tmp++;
                
                // Worst case, needs to release
                //vif.peripheral_cb.SDA_oe = 1'b1; // << this works only when periph clk == controller clk. when periph faster
                //if(measured_SCL_period_tmp == measured_SCL_period) begin
                if(was_ack) begin
                    was_ack = 1'b0;
                    fork
                        begin
                            repeat (measured_SCL_period) @(vif.peripheral_cb);
                            vif.SDA_oe = 1'b1;
                        end
                    join_none
                end

                tr = new();
                void'(tr.randomize() with {size == 1;});
                tr.SCL[0] = vif.SCL;
                tr.SDA[0] = vif.SDA;

                new_clk = 0;

                if(prev_tr != null) begin

                    // SCL rise
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b01) begin
                        if(measured_SCL_period_tmp > 3*measured_SCL_period/2) begin
                            `uvm_info("i2c_driver.peripheral",$sformatf("controler seems to have elongated a bit too much the SCL"), UVM_LOW)
                            vif.SDA_oe = 1'b1;
                        end
                    end

                    // SCL high, SDA fall
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b11
                       &&
                       {prev_tr.SDA[0],tr.SDA[0]} === 2'b10) begin
                        case(started)
                          0 : begin
                              `uvm_info("i2c_driver.peripheral",$sformatf("Detected START condition"), UVM_LOW)
                              started = 1;
                          end
                          1 : begin                              
                              `uvm_info("i2c_driver.peripheral",$sformatf("Detected Repeated START condition"), UVM_LOW)
                              started = 1;

                              //started = 0;
                              count_between_start_and_stop = 0;
                              was_ack = 1'b0;
                              data_count = 0;
                              addr = 0;
                              addr_offset = 0;                        
                              rwb  = 0;
                              stop_received = 0;

                          end

                        endcase // case (started)
                        
                    end

                    // SCL high, SDA rise
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b11
                       &&
                       {prev_tr.SDA[0],tr.SDA[0]} === 2'b01) begin
                        `uvm_info("i2c_driver.peripheral",$sformatf("Detected STOP condition"), UVM_LOW)
                        `uvm_info("i2c_driver.peripheral",$sformatf("ADDR was 7'b%7b (0x%0x) and RWB was RWb 1'b%1b",addr,addr,rwb), UVM_LOW)
                        started = 0;
                        count_between_start_and_stop = 0;
                        was_ack = 1'b0;
                        data_count = 0;
                        addr = 0;
                        addr_offset = 0;                        
                        rwb  = 0;
                        stop_received = 0;
                    end

                    // SCL fall
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b10) begin
                        measured_SCL_period = measured_SCL_period_tmp;
                        measured_SCL_period_tmp = 0;
                    end
                       
                    // SCL fall and started
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b10
                       && 
                       started && !stop_received) begin

                        new_clk = 1;

                        //`uvm_info("i2c_driver.peripheral",$sformatf("Debug info: measured_SCL_period=%0d, measured_SCL_period_tmp=%0d,count_between_start_and_stop=%0d, data_count=%0d"
                        // ,measured_SCL_period,measured_SCL_period_tmp,count_between_start_and_stop,data_count), UVM_DEBUG)

                        case(count_between_start_and_stop) inside
                          I2C_ADDR_WIDTH + 1 : begin

                              // Is the addr our addr ?
                              case(addr) inside
                                [m_agent.m_config.m_addr_min:m_agent.m_config.m_addr_max]: begin

                                    seq_item_port.get_next_item(req);
                                    $cast(rsp,req.clone());
                                    rsp.set_id_info(req);
                                    
                                    this.periph_tr = req;

                                    //`uvm_info("i2c_driver.peripheral",$sformatf("m_periph_dis_storage_chk_at_addr=%0d", m_periph_dis_storage_chk_at_addr), UVM_LOW)

                                    //should we ACK ro NACK here?
                                    if (check_for_addr_nack(rwb,addr))begin//rwb ==1 && !data_storage.exists(addr) && !m_periph_dis_storage_chk_at_addr) begin      
                                        `uvm_info("i2c_driver.peripheral",$sformatf("Driving ADDR NACK = 1'b1 for ADDR 7'b%7b (0x%0x)", addr, addr), UVM_LOW)
                                        vif.SDA_oe = 1'b1;
                                    end else begin
                                        `uvm_info("i2c_driver.peripheral",$sformatf("Driving ADDR ACK = 1'b%1b for ADDR 7'b%7b (0x%0x)", periph_tr.SDA[0], addr, addr), UVM_LOW)
                                        vif.SDA_oe = periph_tr.SDA[0];
                                    end

                                    rsp.SDA[0] = vif.SDA_oe;

                                    //`uvm_info("i2c_driver.peripheral",$sformatf("response recorded = 1'b%1b periph_tr.SDA = 1'b%1b req.SDA = 1'b%1b ", rsp.SDA[0] , periph_tr.SDA[0], req.SDA[0]), UVM_DEBUG)

                                    seq_item_port.item_done(rsp);

                                end

                                default : begin
                                    // Not for us
                                end

                              endcase

                          end
                          I2C_ADDR_WIDTH : begin
                              `uvm_info("i2c_driver.peripheral",$sformatf("Detected RWb = 1'b%1b", tr.SDA[0]), UVM_LOW)
                              rwb = tr.SDA[0];
                          end
                          [0:I2C_ADDR_WIDTH-1] : begin
                              // Sampling ADDR
                              addr = addr << 1;  // MSB first, thus needs to shift when get another               
                              addr[0] = tr.SDA[0];
                              `uvm_info("i2c_driver.peripheral",$sformatf("ADDR[%0d] = 1'b%1b", (I2C_ADDR_WIDTH-1)-count_between_start_and_stop, tr.SDA[0]), UVM_DEBUG)
                              if (count_between_start_and_stop == I2C_ADDR_WIDTH-1)
                                  `uvm_info("i2c_driver.peripheral",$sformatf("Full ADDR recorded: 7'b%7b (0x%0x)", addr,addr), UVM_LOW)
                          end
                          default : begin

                              // Sampling DATA region

                              case(data_count) inside
                                I2C_DATA_WIDTH : begin

                                    // Is the addr our addr ?
                                    case(addr) inside
                                      [m_agent.m_config.m_addr_min:m_agent.m_config.m_addr_max]: begin

                                          // Now we may need to store data
                                          case(rwb)
                                            0: begin
                                                `uvm_info("i2c_driver.peripheral",$sformatf("Driving DATA ACK = 1'b%1b", 1'b0), UVM_LOW)
                                                vif.SDA_oe = 1'b0; // This should come from  seq_item_port like above for ADDR TBD
                                                was_ack = 1'b1;

                                                // Storage of accumulated
                                                void'(store_peripheral_data(.addr(addr), .offset(addr_offset), .data(data)));
                                            end
                                            1: begin
                                                // Up to controller to ACK
                                                vif.SDA_oe = 1'b1;
                                                
                                                // Already sent data
                                            end
                                          endcase

                                          //wait 1 clk to sample vif.SDA (controller ACK/NACK)

                                          @(vif.peripheral_cb);

                                          if (vif.SDA == 1'b1) begin
                                              `uvm_info("i2c_driver.peripheral",$sformatf("Received NACK from controller. releasing SDA bus to stop!"), UVM_LOW)
                                              stop_received = 1;
                                              vif.SDA_oe = 1'b1;
                                          end

                                          // ACK without stop means we continue to next addr
                                          addr_offset++;

                                      end

                                      default : begin
                                          // Not for us
                                      end

                                    endcase

                                    data_count = 0;

                                end
                                default : begin

                                    // Is the addr our addr ?
                                    case(addr) inside
                                      [m_agent.m_config.m_addr_min:m_agent.m_config.m_addr_max]: begin

                                          // Now we may need to retrieve data
                                          case(rwb)
                                            0: begin
                                                int data_count_local = data_count;
                                                fork
                                                    begin
                                                        @(posedge vif.SCL);
                                                        @(vif.peripheral_cb);     
                                                        `uvm_info("i2c_driver.peripheral",$sformatf("DATA[%0d] = 1'b%1b", (I2C_DATA_WIDTH-1)-data_count_local, tr.SDA[0]), UVM_LOW)
                                                        // Accumulating before storage
                                                        data = data << 1;  // MSB first, thus needs to shift when get another               
                                                        data[0] = tr.SDA[0];
                                                    end // UNMATCHED !!
                                                join_none
                                                // Up to controller to drive
                                                vif.SDA_oe = 1'b1;
                                            end
                                            1: begin
                                                // Retrieving
                                                //vif.peripheral_cb.SDA_oe <= 1'b0; // This should come from  seq_item_port TBD

                                                // BIG OR
                                                
                                                // from internal storage for now...
                                                if(data_count == 0) begin
                                                    data = retrieve_peripheral_data(.addr(addr), .offset(addr_offset),.valid(read_data_valid));
                                                end 

                                                if (read_data_valid) begin

                                                   `uvm_info("i2c_driver.peripheral",$sformatf("DATA[%0d] = 1'b%1b", (I2C_DATA_WIDTH-1)-data_count, data[(I2C_DATA_WIDTH-1)-data_count]), UVM_LOW)
                                                   vif.SDA_oe = data[(I2C_DATA_WIDTH-1)-data_count];
                                                end
                                                else begin
                                                   `uvm_info("i2c_driver.peripheral",$sformatf("data is not valid, releasing the bus!"), UVM_LOW)
                                                   vif.SDA_oe = 1'b1;
                                                end
                                            end
                                          endcase
                                      end
                                      default : begin
                                          // Not for us
                                      end
                                    endcase

                                    data_count++;

                                end
                              endcase

                          end
                        endcase

                        if (new_clk) count_between_start_and_stop++;

                    end // if ({prev_tr.SCL[0],tr.SCL[0]} === 2'b01...

                end

                prev_tr = new();
                prev_tr = tr;              

            end
            else begin

                //vif.peripheral_cb.SCL_oe <= 1'b0;
                vif.peripheral_cb.SDA_oe <= 1'b1;
                @(posedge vif.peripheral_cb.RESET_N);

                prev_tr = new();
                void'(prev_tr.randomize() with {size == 1;});
                prev_tr.SCL[0] = vif.SCL;
                prev_tr.SDA[0] = vif.SDA;              

            end

        end

    endtask // run_peripheral
    
    task run_phase(uvm_phase phase);

        case(m_agent.m_config.m_context)
          I2C_CONTROLLER : run_controller();
          I2C_PERIPHERAL : run_peripheral();
        endcase

    endtask // run_phase

    virtual function void store_peripheral_data(bit [I2C_ADDR_WIDTH-1:0] addr, int offset, bit [I2C_DATA_WIDTH-1:0] data);
        `uvm_info("store_peripheral_data",$sformatf("ADDR=0x%0x, DATA=0x%0x",addr+offset,data), UVM_LOW)
        data_storage[addr+offset] = data;
    endfunction

    virtual function bit [I2C_DATA_WIDTH-1:0] retrieve_peripheral_data(bit [I2C_ADDR_WIDTH-1:0] addr, int offset, output bit valid);
        valid = 1;
        if (!data_storage.exists(addr+offset)) begin
            `uvm_warning("i2c_driver.peripheral",$sformatf("Reading at ADDR 7'b%7b while never wrote there", addr+offset))
        valid = 0;
        end

        `uvm_info("retrieve_peripheral_data",$sformatf("ADDR=0x%0x, DATA=0x%0x",addr+offset,data_storage[addr+offset]), UVM_LOW)
        return data_storage[addr+offset];
    endfunction

    virtual function bit check_for_addr_nack (bit rwb, bit [I2C_ADDR_WIDTH-1:0] addr);
        bit not_exist = 0;

        if (rwb ==1 && !data_storage.exists(addr) && !m_periph_dis_storage_chk_at_addr) begin   
            `uvm_warning("i2c_driver.peripheral",$sformatf("Data does not exist in address 7'b%7b (0x%0x)", addr,addr))
        not_exist = 1;
        end
        return not_exist;
    endfunction

endclass // i2c_driver

