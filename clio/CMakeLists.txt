cmake_minimum_required(VERSION 3.22)

include(pico_sdk_import.cmake)

project(gw816_clio C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_executable(clio_firmware
        main.c inc/cpu_module.h modules/cpu_module.c inc/config.h modules/serial_module.c inc/serial_module.h inc/irq_module.h inc/reg_module.h modules/reg_module.c inc/bus_module.h modules/bus_module.c inc/ring_buffer.h inc/rom_module.h modules/rom_module.c inc/led_module.h modules/led_module.c
        rom-bios.c rom-bootstrap.c rom-monitor.c)
include_directories(clio_firmware PRIVATE inc)
add_custom_command(
        OUTPUT rom-bootstrap.c
        COMMAND xxd -i bios-bootstrap.bin ${CMAKE_CURRENT_BINARY_DIR}/rom-bootstrap.c
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bios-bootstrap.bin
)
add_custom_command(
        OUTPUT rom-bios.c
        COMMAND xxd -i bios.bin ${CMAKE_CURRENT_BINARY_DIR}/rom-bios.c
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bios.bin
)
add_custom_command(
        OUTPUT rom-monitor.c
        COMMAND xxd -i bios-monitor.bin ${CMAKE_CURRENT_BINARY_DIR}/rom-monitor.c
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bios-monitor.bin
)


# Setup Program Descriptors
pico_set_program_name(clio_firmware "GW816 Clio Firmware")
pico_set_program_description(clio_firmware "GW816 System Interface Adapter (Clio)")

# Make sure we create the UF2 file
pico_add_extra_outputs(clio_firmware)
pico_set_binary_type(clio_firmware copy_to_ram)

target_link_libraries(clio_firmware PRIVATE
        pico_stdlib
        pico_multicore
        hardware_dma
        hardware_pio
        )
pico_generate_pio_header(clio_firmware ${CMAKE_CURRENT_LIST_DIR}/modules/bus_module.pio)

# Setup USB for standard io
pico_enable_stdio_usb(clio_firmware 1)
pico_enable_stdio_uart(clio_firmware 0)