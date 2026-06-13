## Clock signal
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { CLK }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK }]
## Inputs
## SW0 = START_STOP
## SW1 = CLEAR

set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { START_STOP }]
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports { CLEAR }]


## 7-segment display cathodes
## SEG(6) = A
## SEG(5) = B
## SEG(4) = C
## SEG(3) = D
## SEG(2) = E
## SEG(1) = F
## SEG(0) = G

set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { SEG[6] }]
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { SEG[5] }]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { SEG[4] }]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports { SEG[3] }]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { SEG[2] }]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { SEG[1] }]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { SEG[0] }]


## 7-segment display anodes
## AN = "11111110", only rightmost digit enabled

set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports { AN[0] }]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports { AN[1] }]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { AN[2] }]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports { AN[3] }]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { AN[4] }]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { AN[5] }]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { AN[6] }]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { AN[7] }]












