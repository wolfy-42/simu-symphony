onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/test_case_inst/eth_bfm/clk
add wave -noupdate /tb/test_case_inst/eth_bfm/rst
add wave -noupdate -expand -subitemconfig {/tb/test_case_inst/eth_bfm/dut_axis.std -expand /tb/test_case_inst/eth_bfm/dut_axis.tuser -expand} /tb/test_case_inst/eth_bfm/dut_axis
add wave -noupdate /tb/test_case_inst/eth_bfm/mac_axis_rdy
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3323340 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 99
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1461331 ps} {4133855 ps}
