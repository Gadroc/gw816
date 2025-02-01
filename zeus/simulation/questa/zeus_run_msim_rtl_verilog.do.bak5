transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/ccourtne/Source/zeus/src/syscon {C:/Users/ccourtne/Source/zeus/src/syscon/pll_phi2.v}
vlog -vlog01compat -work work +incdir+C:/Users/ccourtne/Source/zeus/src/syscon {C:/Users/ccourtne/Source/zeus/src/syscon/pll_sys.v}
vlog -vlog01compat -work work +incdir+C:/Users/ccourtne/Source/zeus/db {C:/Users/ccourtne/Source/zeus/db/pll_phi2_altpll.v}
vlog -vlog01compat -work work +incdir+C:/Users/ccourtne/Source/zeus/db {C:/Users/ccourtne/Source/zeus/db/pll_sys_altpll.v}
vlog -vlog01compat -work work +incdir+C:/Users/ccourtne/Source/zeus/db {C:/Users/ccourtne/Source/zeus/db/clock_generator_altpll.v}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src/video {C:/Users/ccourtne/Source/zeus/src/video/video_controller.sv}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src/syscon {C:/Users/ccourtne/Source/zeus/src/syscon/syscon.sv}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src {C:/Users/ccourtne/Source/zeus/src/top.sv}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src/sdram {C:/Users/ccourtne/Source/zeus/src/sdram/sdram_controller.sv}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src/ps2 {C:/Users/ccourtne/Source/zeus/src/ps2/ps2_controller.sv}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src/uart {C:/Users/ccourtne/Source/zeus/src/uart/uart_controller.sv}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src/spi {C:/Users/ccourtne/Source/zeus/src/spi/spi_controller.sv}
vlog -sv -work work +incdir+C:/Users/ccourtne/Source/zeus/src/ext_65xx_bus {C:/Users/ccourtne/Source/zeus/src/ext_65xx_bus/ext_65xx_bus.sv}

