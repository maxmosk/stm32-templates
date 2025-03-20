#######################################################################
# Makefile for STM32F1 Blue Pill board projects

OUTPATH = build
PROJECT_DIR ?= ./
PROJECT = $(OUTPATH)/firmware
OPENOCD_SCRIPT_DIR ?= /usr/share/openocd/scripts
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Add *_USER variables
include $(PROJECT_DIR)/firmware.mk

ifeq ($(USER_MCU),stm32f103c8t6)
MCU_SERIES = f1xx
MCU_DRIVER = F1
MCU_REFERENCE = f103xb
MCU_OPENOCD = f1x
MCU_CMSIS = F1xx
MCU_DEFINE = F103xB
MCU_LINKER = F103XB
else ifeq ($(USER_MCU),stm32g030f6p6)
MCU_SERIES = g0xx
MCU_DRIVER = G0
MCU_REFERENCE = g030xx
MCU_OPENOCD = g0x
MCU_CMSIS = G0xx
MCU_DEFINE = G030xx
MCU_LINKER = G030XX
MCU_LDS = link/STM32G030XX_FLASH.ld
endif

ifeq ($(MCU_LDS),)
MCU_LDS = $(DRIVER_DIR)/Drivers/CMSIS/Device/ST/STM32$(MCU_CMSIS)/Source/Templates/gcc/linker/STM32$(MCU_LINKER)_FLASH.ld
endif

DRIVER_DIR = STM32Cube$(MCU_DRIVER)

################
# Sources

SOURCES_S  = $(DRIVER_DIR)/Drivers/CMSIS/Device/ST/STM32$(MCU_CMSIS)/Source/Templates/gcc/startup_stm32$(MCU_REFERENCE).s
SOURCES_S += $(SOURCES_S_USER)

SOURCES_C  = $(DRIVER_DIR)/Drivers/CMSIS/Device/ST/STM32$(MCU_CMSIS)/Source/Templates/system_stm32$(MCU_SERIES).c
SOURCES_C += $(SOURCES_C_USER)

SOURCES = $(SOURCES_S) $(SOURCES_C)
OBJS = $(SOURCES_S:.s=.o) $(SOURCES_C:.c=.o)

# Cross compilation toolchain

CROSS_COMPILE ?= arm-none-eabi-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
AR = $(CROSS_COMPILE)ar
LD = $(CROSS_COMPILE)gcc
NM = $(CROSS_COMPILE)nm
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
READELF = $(CROSS_COMPILE)readelf
SIZE = $(CROSS_COMPILE)size
GDB = gdb-multiarch
RM = rm -f
OPENOCD = openocd

# Build options

INCLUDES = -I$(DRIVER_DIR)/Drivers/CMSIS/Include -I$(DRIVER_DIR)/Drivers/STM32$(MCU_CMSIS)_HAL_Driver/Inc -I$(DRIVER_DIR)/Drivers/CMSIS/Device/ST/STM32$(MCU_CMSIS)/Include
DEFINES = -DSTM32 -DSTM32$(MCU_DRIVER) -DSTM32$(MCU_DEFINE) -DUSE_FULL_LL_DRIVER=1
MCUFLAGS = -mcpu=cortex-m3 -mlittle-endian -mfloat-abi=soft -mthumb -mno-unaligned-access
DEBUG_OPTIMIZE_FLAGS = -O0 -ggdb -gdwarf-2
CFLAGS = -Wall -Wextra --pedantic
CFLAGS_EXTRA = -nostartfiles -nodefaultlibs -nostdlib -fdata-sections -ffunction-sections
CFLAGS += $(DEFINES) $(MCUFLAGS) $(DEBUG_OPTIMIZE_FLAGS) $(CFLAGS_EXTRA) $(INCLUDES) $(CFLAGS_USER)

LDFLAGS = -static $(MCUFLAGS) -Wl,--start-group -lgcc -lc -lg -Wl,--end-group  -Wl,--gc-sections \
          -T $(MCU_LDS) $(LDFLAGS_USER)

.PHONY: dirs all clean flash erase

all: dirs $(PROJECT).bin $(PROJECT).s

dirs: | $(OUTPATH) $(DRIVER_DIR) $(USER_DIRS)

$(DRIVER_DIR):
	git clone --recursive https://github.com/STMicroelectronics/$@.git

$(OUTPATH):
	mkdir -p $@

clean:
	$(RM) $(OBJS) $(PROJECT).elf $(PROJECT).bin $(PROJECT).s
	rm -rf ${OUTPATH}

# Hardware flash and debug

flash: $(PROJECT).bin
	st-flash write $(PROJECT).bin 0x08000000

erase:
	st-flash erase

gdb-server-ocd:
	$(OPENOCD) -f $(OPENOCD_SCRIPT_DIR)/interface/stlink-v2.cfg \
               -f $(OPENOCD_SCRIPT_DIR)/target/stm32$(MCU_OPENOCD).cfg

gdb-server-st:
	st-util

OPENOCD_P=3333
gdb-openocd: $(PROJECT).elf
	$(GDB) --eval-command="target extended-remote localhost:$(OPENOCD_P)" \
           --eval-command="load" $(PROJECT).elf

GDB_P=4242
gdb-st-util: $(PROJECT).elf
	$(GDB) --eval-command="target extended-remote localhost:$(GDB_P)" \
           --eval-command="load" $(PROJECT).elf

# Build

$(PROJECT).elf: $(OBJS)

%.elf:
	$(LD) $(OBJS) $(LDFLAGS) -o $@
	$(SIZE) -A $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.s: %.elf
	$(OBJDUMP) -dwh $< > $@
