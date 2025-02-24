# To create the 3 AXI BFMs from Xilinx
# Use Vivado 2018.2
# Run vivado -source vip_management_project_script.tcl

# Create project.
set proj_dir "."
create_project vip_management $proj_dir/vip_management -part xcku115-flvd1924-1-c -ip

#create_project managed_ip_project /home/victor.dumitriu/Work/VIP_Test1/Managed_IP/managed_ip_project -part xcku115-flvd1924-1-c -ip

# Configure project.
set_property target_simulator Questa [current_project]

# Create Master AXI 4 Lite VIP.
#create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_vip_0 -dir /home/victor.dumitriu/Work/VIP_Test1/Managed_IP
create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axilite_master -dir $proj_dir
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.INTERFACE_MODE {MASTER} CONFIG.SUPPORTS_NARROW {0} CONFIG.HAS_BURST {0} CONFIG.HAS_LOCK {0} CONFIG.HAS_CACHE {0} CONFIG.HAS_REGION {0} CONFIG.HAS_QOS {0}] [get_ips axilite_master]
generate_target {instantiation_template simulation} [get_files $proj_dir/axilite_master/axilite_master.xci]

# Create Master AXI 4 VIP.
#create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_vip_1 -dir /home/victor.dumitriu/Work/VIP_Test1/Managed_IP
create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi_master -dir $proj_dir
set_property -dict [list CONFIG.INTERFACE_MODE {MASTER}] [get_ips axi_master]
generate_target {instantiation_template simulation} [get_files $proj_dir/axi_master/axi_master.xci]

# Create Master AXI 4 Stream VIP.
#create_ip -name axi4stream_vip -vendor xilinx.com -library ip -version 1.1 -module_name axi4stream_vip_0 -dir /home/victor.dumitriu/Work/VIP_Test1/Managed_IP
create_ip -name axi4stream_vip -vendor xilinx.com -library ip -version 1.1 -module_name axistream_master -dir $proj_dir
set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.TDATA_NUM_BYTES {4} CONFIG.TUSER_WIDTH {1} CONFIG.HAS_TLAST {1}] [get_ips axistream_master]
generate_target {instantiation_template simulation} [get_files $proj_dir/axistream_master/axistream_master.xci]
