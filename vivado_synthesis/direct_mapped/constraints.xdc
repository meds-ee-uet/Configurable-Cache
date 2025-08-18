## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #clk100mhz

## Reset signal
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { rst }]; #sw[0]

## req_valid
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { req_valid }]; #sw[1]

## req_type
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { req_type }]; #sw[2]

## nibble_value[3:0]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { nibble_value[0] }]; #sw[3]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { nibble_value[1] }]; #sw[4]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { nibble_value[2] }]; #sw[5]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { nibble_value[3] }]; #sw[6]

## nibble_select[2:0]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { nibble_select[0] }]; #sw[7]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { nibble_select[1] }]; #sw[8]
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports { nibble_select[2] }]; #sw[9]

## load_nibble
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { load_nibble }]; #sw[10]

## done_cache LED
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { done_cache }]; #led[0]

## data_out[15:0] LEDs
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { data_out[0] }];  #led[1]
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { data_out[1] }];  #led[2]
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { data_out[2] }];  #led[3]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { data_out[3] }];  #led[4]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { data_out[4] }];  #led[5]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { data_out[5] }];  #led[6]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { data_out[6] }];  #led[7]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { data_out[7] }];  #led[8]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { data_out[8] }];  #led[9]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { data_out[9] }];  #led[10]
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { data_out[10] }]; #led[11]
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { data_out[11] }]; #led[12]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { data_out[12] }]; #led[13]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { data_out[13] }]; #led[14]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { data_out[14] }]; #led[15]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { data_out[15] }]; #led[16]
