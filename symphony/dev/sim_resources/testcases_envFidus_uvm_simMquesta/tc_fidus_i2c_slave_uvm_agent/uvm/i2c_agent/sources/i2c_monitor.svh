//----------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Filename        : i2c_monitor.svh
// Project         : I2C
// Author          : Serge Patenaude
// Created         : 05.12.2023
//
// Description: 
//
//----------------------------------------------------------------------

class i2c_monitor #(int I2C_ADDR_WIDTH=7, I2C_DATA_WIDTH=8) extends uvm_monitor;
    
    i2c_agent #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) m_agent;

    virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) vif;

    i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) tr;
    i2c_item #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) prev_tr;

    i2c_basic_data_seq #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH) data_tr;

    uvm_analysis_port #(i2c_basic_data_seq#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH)) ap;    

    `uvm_component_param_utils_begin(i2c_monitor#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))
    `uvm_component_utils_end

    function new(string name, uvm_component parent = null);
        super.new(name,parent);
        ap = new("ap",this);
    endfunction // new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!(uvm_config_db#(virtual i2c_if #(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::get(this, "", "vif", vif))) begin
            `uvm_fatal("i2c_monitor",$sformatf("Can't find vif %s in uvm_config_db", get_full_name()))
        end

    endfunction // build_phase
    
    task run_phase(uvm_phase phase);

        bit started                      = 0;
        bit new_clk                      = 0;
        int count_between_start_and_stop = 0;
        int data_count                   = 0;
        bit rwb                          = 0;
        bit ack                          = 1;
        bit [I2C_ADDR_WIDTH-1:0] addr   = 0;        
        bit [I2C_DATA_WIDTH-1:0] data   = 0;
        int addr_offset                  = 0;    

        forever begin

            if(vif.monitor_cb.RESET_N == 1'b1) begin

                //@(vif.monitor_cb.SCL or vif.monitor_cb.SDA);
                //@(posedge vif.monitor_cb.CLK);
                //@(vif.monitor_cb);
                //@(posedge vif.CLK_del);

                case(m_agent.m_config.m_context)
                  I2C_CONTROLLER : @(negedge vif.CLK);
                  I2C_PERIPHERAL : @(vif.monitor_cb);
                endcase
                
                tr = new();
                void'(tr.randomize() with {size == 1;});
                tr.SCL[0] = vif.SCL;
                tr.SDA[0] = vif.SDA;

                new_clk = 0;

                if(prev_tr != null) begin

                    // SCL high, SDA fall
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b11
                       &&
                       {prev_tr.SDA[0],tr.SDA[0]} === 2'b10) begin
                        case(started)
                          0 : begin
                              `uvm_info("i2c_monitor",$sformatf("Detected START condition"), UVM_LOW)
                              started = 1;
                          end
                          1 : begin
                              `uvm_info("i2c_monitor",$sformatf("Detected Repeated START condition"), UVM_LOW)
                              started = 1;

                              void'(process_stop(.addr(addr)));

                              //started = 0;
                              count_between_start_and_stop = 0;
                              data_count = 0;
                              addr = 0;
                              addr_offset = 0;                        
                              rwb  = 0;
                              ack  = 1;

                          end
                        endcase // case (started)

                    end

                    // SCL high, SDA rise
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b11
                       &&
                       {prev_tr.SDA[0],tr.SDA[0]} === 2'b01) begin
                        `uvm_info("i2c_monitor",$sformatf("Detected STOP condition"), UVM_LOW)
                        //`uvm_info("i2c_monitor",$sformatf("\nADDR was 7'b%7b,\nRWB was RWb 1'b%1b,\nDATA was 0x%0x",addr,rwb,data), UVM_LOW)

                        //data_tr.print();

                        void'(process_stop(.addr(addr)));
                        
                        started = 0;
                        count_between_start_and_stop = 0;
                        data_count = 0;
                        addr = 0;
                        addr_offset = 0;                        
                        rwb  = 0;
                        ack  = 1;
                    end

                    // SCL rise and started
                    if({prev_tr.SCL[0],tr.SCL[0]} === 2'b01
                       && 
                       started) begin

                        new_clk = 1;                        

                        case(count_between_start_and_stop) inside
                          I2C_ADDR_WIDTH + 1 : begin
                              `uvm_info("i2c_monitor",$sformatf("Detected ADDR ACK = 1'b%1b for ADDR 7'b%7b", tr.SDA[0], addr), UVM_LOW)
                              ack = tr.SDA[0];
                              data_tr = new();
                              data_tr.addr = addr;
                              data_tr.rwb  = rwb;

                              // Concatenation of all ack, one bad is enough to be reported, 
                              // but we start by overriding default with first one (addr ack)
                              data_tr.ack  = ack;

                          end
                          I2C_ADDR_WIDTH : begin
                              `uvm_info("i2c_monitor",$sformatf("Detected RWb = 1'b%1b", tr.SDA[0]), UVM_LOW)
                              rwb = tr.SDA[0];
                          end
                          [0:I2C_ADDR_WIDTH-1] : begin
                              // Sampling ADDR
                              addr = addr << 1;  // MSB first, thus needs to shift when get another               
                              addr[0] = tr.SDA[0];
			                  if (count_between_start_and_stop == I2C_ADDR_WIDTH-1)
                                  `uvm_info("i2c_monitor",$sformatf("Full ADDR recorded: 7'b%7b (0x%0x)", addr,addr), UVM_LOW)
                          end
                          default : begin
                              // Sampling DATA region

                              case(data_count) inside
                                I2C_DATA_WIDTH : begin
                                    `uvm_info("i2c_monitor",$sformatf("Detected DATA ACK = 1'b%1b", tr.SDA[0]), UVM_LOW)
                                    ack = tr.SDA[0];

                                    data_count = 0;
                                    data_tr.data = new[data_tr.data.size()+1](data_tr.data);
                                    data_tr.data[addr_offset] = data;
                                    data_tr.nbr_data_bytes = data_tr.data.size();

                                    // Concatenation of all ack, one bad is enough to be reported
                                    data_tr.ack  = ack || data_tr.ack; 

                                    // ACK without stop means we continue to next addr
                                    addr_offset++;
                                    data = 0;                                    

                                end
                                default : begin
                                    `uvm_info("i2c_monitor",$sformatf("DATA[%0d] = 1'b%1b", (I2C_DATA_WIDTH-1)-data_count, tr.SDA[0]), UVM_LOW)
                                    data = data << 1;  // MSB first, thus needs to shift when get another               
                                    data[0] = tr.SDA[0];
                                    if (data_count == I2C_DATA_WIDTH-1)
                                        `uvm_info("i2c_monitor",$sformatf("Data recorded 0x%0x", data), UVM_LOW)
				                    data_count++;
                                end
                              endcase

                          end
                        endcase

                        if (new_clk) count_between_start_and_stop++;

                    end

                end

                prev_tr = new();
                prev_tr = tr;              

            end
            else begin

                @(posedge vif.monitor_cb.RESET_N);

                prev_tr = new();
                void'(prev_tr.randomize() with {size == 1;});
                prev_tr.SCL[0] = vif.SCL;
                prev_tr.SDA[0] = vif.SDA;              

            end

        end

    endtask // run_phase

    function void process_stop(bit [I2C_ADDR_WIDTH-1:0] addr);

        // Send newly detected transaction to upper listeners
        case(m_agent.m_config.m_context)
          I2C_CONTROLLER : begin ap.write(data_tr); end
          I2C_PERIPHERAL : begin
              // Is the addr our addr ?
              case(addr) inside
                [m_agent.m_config.m_addr_min:m_agent.m_config.m_addr_max]: begin ap.write(data_tr); end
                default : begin if(m_agent.m_config.m_peripheral_report_all) begin ap.write(data_tr); end end
              endcase // case (addr)                              
          end
        endcase // case (m_agent.m_config.m_context)                        

    endfunction

endclass // i2c_monitor
