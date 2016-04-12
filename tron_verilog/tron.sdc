create_clock -name clk -period 20 [get_ports {CLOCK_50}]
derive_pll_clocks
derive_clock_uncertainty