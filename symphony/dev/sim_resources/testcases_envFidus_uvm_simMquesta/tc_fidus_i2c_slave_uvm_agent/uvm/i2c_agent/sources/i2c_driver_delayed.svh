//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_driver_delayed.svh
// Project         : I2C
// Author          : Reza Shomalnasab
// Created         : 07.10.2023
//
// Description:  This i2c driver is running delayed version of run_controller
//                and run_peripheral. The controller toggles SDA when SCL is
//                low. This driver should be used when we have delay values 
//                set for SCL and SDA. (t_to_SCL_ps , t_to_SDA_ps)
//----------------------------------------------------------------------

class i2c_driver_delayed #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends i2c_driver #(I2C_ADDR_WIDTH, I2C_DATA_WIDTH);
    `uvm_component_param_utils_begin(i2c_driver_delayed#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
    `uvm_component_utils_end

    function new(string name, uvm_component parent = null);
        super.new(name,parent);
    endfunction // new

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
                    join
                    // Send back info (since could potentialy contains info from a peripherals)
                    rsp.SCL[i] = vif.SCL;
                    rsp.SDA[i] = vif.SDA;

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
        @(negedge vif.CLK);//the otherway around causes SDA changes during SCL high
        //`uvm_info("i2c_driver.controller",$sformatf("tick_scl"), UVM_DEBUG)
        if(req.update_SCL) begin
           `uvm_info("i2c_driver.controller",$sformatf("t_to_SCL_ps %0d",req.t_to_SCL_ps), UVM_DEBUG)
           if (req.t_to_SCL_ps > 0) begin
                #(req.t_to_SCL_ps*1ps);
                `uvm_info("i2c_driver.controller",$sformatf("driving SCL %0b",req.SCL[i]), UVM_DEBUG)
                vif.SCL_oe = req.SCL[i];
            end
            else begin
                `uvm_info("i2c_driver.controller",$sformatf("driving SCL %0b",req.SCL[i]), UVM_DEBUG)
                vif.controller_cb.SCL_oe <= req.SCL[i];
            end
        end
    endtask // drive_cont_scl

    virtual task drive_cont_sda(ref i2c_item req, int i);
	@(posedge vif.CLK);//the otherway around causes SDA changes during SCL high
        //`uvm_info("i2c_driver.controller",$sformatf("tick_sda"), UVM_DEBUG)
        if(req.update_SDA) begin
            `uvm_info("i2c_driver.controller",$sformatf("t_to_SDA_ps %0t",req.t_to_SDA_ps), UVM_DEBUG)
            if(req.t_to_SDA_ps > 0) begin
                #(req.t_to_SDA_ps*1ps);
                `uvm_info("i2c_driver.controller",$sformatf("driving SDA %0b",req.SDA[i]), UVM_DEBUG)
                vif.SDA_oe = req.SDA[i];
            end
            else begin
               `uvm_info("i2c_driver.controller",$sformatf("driving SDA %0b",req.SDA[i]), UVM_DEBUG)
                vif.controller_cb.SDA_oe <= req.SDA[i];
            end
        end
        else begin
            `uvm_info("i2c_driver.controller",$sformatf("Releasing the SDA bus."), UVM_DEBUG)
            //vif.controller_cb.SDA_oe <= 1'b1;
            vif.SDA_oe <= 1'b1;
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
        int scl_fall_count               = 0;
        int sda_intf_delay               = 3;

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
                              scl_fall_count = 1;
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
                              scl_fall_count = 1;

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
                        scl_fall_count = 0;
                    end

                    // SCL fall
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b10) begin
                        measured_SCL_period = measured_SCL_period_tmp;
                        measured_SCL_period_tmp = 0;
                        if (scl_fall_count > 0) scl_fall_count++;
                    end

                    //`uvm_info("i2c_driver.peripheral",$sformatf("scl_fall_count = %0d",scl_fall_count), UVM_LOW)
                  
                    // SCL fall and started
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b10
                       && 
                       started && scl_fall_count > 2 && !stop_received) begin

                       new_clk = 1;

                        //`uvm_info("i2c_driver.peripheral",$sformatf("Debug info: measured_SCL_period=%0d, measured_SCL_period_tmp=%0d,count_between_start_and_stop=%0d, data_count=%0d"
                        // ,measured_SCL_period,measured_SCL_period_tmp,count_between_start_and_stop,data_count), UVM_DEBUG)

                        case(count_between_start_and_stop) inside
                          I2C_ADDR_WIDTH : begin
                              `uvm_info("i2c_driver.peripheral",$sformatf("Detected RWb = 1'b%1b", tr.SDA[0]), UVM_LOW)
                              rwb = tr.SDA[0];

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
                                        repeat (sda_intf_delay) @(vif.peripheral_cb);
                                        `uvm_info("i2c_driver.peripheral",$sformatf("Driving ADDR NACK = 1'b1 for ADDR 7'b%7b (0x%0x)", addr, addr), UVM_LOW)
                                        vif.SDA_oe = 1'b1;
                                    end else begin
                                        repeat (sda_intf_delay) @(vif.peripheral_cb);
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
                              //`uvm_info("i2c_driver.peripheral",$sformatf("in data region, data_count=%0d!",data_count), UVM_DEBUG)
                              case(data_count) inside

                                I2C_DATA_WIDTH : begin

                                    // Is the addr our addr ?
                                    case(addr) inside
                                      [m_agent.m_config.m_addr_min:m_agent.m_config.m_addr_max]: begin

                                          // Now we may need to store data
                                          case(rwb)
                                            0: begin
                                                repeat (sda_intf_delay) @(vif.peripheral_cb);
                                                `uvm_info("i2c_driver.peripheral",$sformatf("Driving DATA ACK = 1'b%1b", 1'b0), UVM_LOW)
                                                vif.SDA_oe = 1'b0; // This should come from  seq_item_port like above for ADDR TBD
                                                was_ack = 1'b1;

                                                // Storage of accumulated
                                                void'(store_peripheral_data(.addr(addr), .offset(addr_offset), .data(data)));
                                            end
                                            1: begin
						repeat (sda_intf_delay) @(vif.peripheral_cb);
                                                // Up to controller to ACK
						`uvm_info("i2c_driver.peripheral",$sformatf("releasing bus for controller ACK"), UVM_LOW)
                                                vif.SDA_oe = 1'b1;

                                                 //after rising edge of SCL wait 3 clk to sample vif.SDA (controller ACK/NACK)
                                                 @(posedge vif.SCL);
                                                 repeat (sda_intf_delay) @(vif.peripheral_cb);

                                                 if (vif.SDA == 1'b1) begin
                                                     `uvm_info("i2c_driver.peripheral",$sformatf("Received NACK from controller. releasing SDA bus to stop!"), UVM_LOW)
                                                     stop_received = 1;
                                                     vif.SDA_oe = 1'b1;
                                                 end

                                                // Already sent data
                                            end
                                          endcase // case (rwb)
                                          // ACK without stop means we continue to next addr
                                          addr_offset++;

                                      end

                                      default : begin
                                          // Not for us
                                      end

                                    endcase  // case (addr)

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
                                                        repeat (sda_intf_delay) @(vif.peripheral_cb);     
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

                                                    repeat (sda_intf_delay) @(vif.peripheral_cb);

                                                    `uvm_info("i2c_driver.peripheral",$sformatf("DATA[%0d] = 1'b%1b", (I2C_DATA_WIDTH-1)-data_count, data[(I2C_DATA_WIDTH-1)-data_count]), UVM_LOW)
                                                    vif.SDA_oe = data[(I2C_DATA_WIDTH-1)-data_count];
                                                end
                                                else begin
                                                    `uvm_info("i2c_driver.peripheral",$sformatf("data is not valid, releasing the bus!"), UVM_LOW)
                                                    vif.SDA_oe = 1'b1;
                                                end
                                            end
                                          endcase // case(rwb)
                                      end
                                      default : begin
                                          // Not for us
                                      end
                                    endcase // case(addr)

                                    data_count++;

                                end
                              endcase // case(data_count)

                          end
                        endcase // case(count_between_start_and_stop)

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

endclass // i2c_driver_delayed


