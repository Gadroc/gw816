set_time_format -unit ns -decimal_places 3
create_clock -period 20.000 -name {clk_50} [get_ports {clk_50}]
derive_pll_clocks
