set_time_format -unit ns -decimal_places 3

create_clock -period 20.000 -name srcclk [get_ports {clk_50}]
create_generated_clock -source {janus|phi2|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 25 -multiply_by 4 -duty_cycle 50.00 -name phi2 {janus|phi2|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -source {janus|sysclk|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 25 -multiply_by 64 -duty_cycle 50.00 -name sysclk {janus|sysclk|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -source {apollo|vga_clock|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 147 -multiply_by 74 -duty_cycle 50.00 -name vga {apollo|vga_clock|altpll_component|auto_generated|pll1|clk[0]}

# derive_pll_clocks

derive_clock_uncertainty

# Output Delay Formula
# Max: trace_delay_max + setup_time
# Min: trace_delay_min - hold_time

# Input Delay Forumla
# Max: trace_delay_max + tco_max
# Min: trace_delay_min + tco_min

#*********************************************************************************
# Ignore Dev Board / Built-in
#*********************************************************************************
set_false_path -from [get_ports {altera_reserved_* sw*}]
set_false_path -to [get_ports {altera_reserved_* led*}]

#*********************************************************************************
# Ignore Async Bus Signals
#*********************************************************************************
set_false_path -to {reset_n cpu_irq_n cpu_abort_n cpu_halt_n}
set_false_path -to {io_*}
set_false_path -from {reset_req_n}


#*********************************************************************************
#                              65C816 3.3v
#*********************************************************************************
# CPU Write Data
# * 10ns tDHR for Bank Address
# * 40ns tMDS for write data to be available
set_input_delay -clock phi2 -rise -max 41 [get_ports cpu_data_bus[*]]
set_input_delay -clock phi2 -rise -min 10 [get_ports cpu_data_bus[*]]

# Bank Address Data
# * 10ns tDHW for write data to be held
# * 40ns tBAS for bank address to be available
set_input_delay -clock phi2 -fall -max 41 [get_ports cpu_data_bus[*]]
set_input_delay -clock phi2 -fall -min 10 [get_ports cpu_data_bus[*]]

# CPU Read Data
# * 10ns tDHR for Bank Address
# * 50ns tACC for Read Data to be available
set_output_delay -clock phi2 -max 16 [get_ports cpu_data_bus[*]]
set_output_delay -clock phi2 -min -10  [get_ports cpu_data_bus[*]]

# Address is strobed out on fall of clock
# * 10ns tAH for address to be held
# * 40ns tADS for bank address to be available
set_input_delay -clock phi2 -clock_fall -max 41 [get_ports {cpu_addr_bus[*] cpu_read_write cpu_vda cpu_vpa cpu_vp_n}]
set_input_delay -clock phi2 -clock_fall -min 10 [get_ports {cpu_addr_bus[*] cpu_read_write cpu_vda cpu_vpa cpu_vp_n}]

set_clock_groups -group [get_clocks sysclk] -group [get_clocks {phi2}] -asynchronous

#*********************************************************************************
#                             External Peripherals
# These must match 65C816 address and data line timings fro exteranl chips
# designed for use with the 65xxx bus.
#*********************************************************************************
create_clock -name ext_bus_write -period 125 [get_ports io_write_req_n]
create_clock -name ext_bus_read -period 125 [get_ports io_read_req_n]

set_clock_latency 10 -source -early [get_clocks ext_bus_write]
set_clock_latency 10 -source -early [get_clocks ext_bus_read]

#*********************************************************************************
#                             VGA Signals
#*********************************************************************************
set_output_delay -clock vga 10 [get_ports {vga_*}]