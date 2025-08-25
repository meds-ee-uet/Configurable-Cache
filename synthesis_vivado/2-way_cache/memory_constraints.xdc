set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
#req_type
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { req_type }]; #IO_L24N_T3_RS0_15 Sch=sw[0]
#read_en_cache
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { read_en_cache }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=sw[1]
#write_en_cache
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { write_en_cache}]; #IO_L6N_T0_D08_VREF_14 Sch=sw[2]
#read_en_mem
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { read_en_mem }]; #IO_L13N_T2_MRCC_14 Sch=sw[3]
#write_en_mem
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { write_en_mem }]; #IO_L12N_T1_MRCC_14 Sch=sw[4]
#nibble constraints for address and data_in
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { sw_nibble[0] }]; #IO_L7N_T1_D10_14 Sch=sw[5]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { sw_nibble[1] }]; #IO_L17N_T2_A13_D29_14 Sch=sw[6]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { sw_nibble[2] }]; #IO_L5N_T0_D07_14 Sch=sw[7]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { sw_nibble[3]}]; #IO_L24N_T3_34 Sch=sw[8]

#load_address (button)
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { load_address }]; #IO_L9P_T1_DQS_14 Sch=btnc
#load_data (button)
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {load_data }]; #IO_L4N_T0_D05_14 Sch=btnu
#clear_address (button)
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports {clear_address}]; #IO_L12P_T1_MRCC_14 Sch=btnl
#clear_data (button )
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { clear_data }]; #IO_L10N_T1_D15_14 Sch=btnr

#hit
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {hit }]; #IO_L18P_T2_A24_15 Sch=led[0]
#dirty_bit
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports {dirty_bit}]; #IO_L24P_T3_RS1_15 Sch=led[1]
# data_out: map lower 8 bits of data_out to 8 LEDs
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { data_out[0] }]; #IO_L17N_T2_A25_15 Sch=led[2]
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { data_out[1] }]; #IO_L8P_T1_D11_14 Sch=led[3]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {data_out[2] }]; #IO_L7P_T1_D09_14 Sch=led[4]
set_property -dict { PACKAG