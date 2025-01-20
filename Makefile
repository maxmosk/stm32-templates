#######################################################################
# Makefile for STM32F1 Blue Pill board projects

OUTPATH = build
PROJECT_DIR ?= ./
PROJECT = $(OUTPATH)/firmware
CMSIS_DIR = cmsis-device-f1
CMSIS_PREFIX = $(CMSIS_DIR)/Source/Templates/
PERIPH_DIR = stm32f1xx-hal-driver
PERIPH_PREFIX = $(PERIPH_DIR)/Src/
DRIVER_DIR = STM32CubeF1
OPENOCD_SCRIPT_DIR ?= /usr/share/openocd/scripts
HEAP_SIZE = 0x400
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Add *_USER variables
include $(PROJECT_DIR)/firmware.mk

################
# Sources

SOURCES_S = $(CMSIS_PREFIX)gcc/startup_stm32f103xb.s
SOURCES_S += $(SOURCES_S_USER)

SOURCES_C = $(CMSIS_PREFIX)system_stm32f1xx.c
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

INCLUDES = -I$(CMSIS_DIR)/Include -I$(PERIPH_DIR)/Inc -I$(DRIVER_DIR)/Drivers/CMSIS/Include
DEFINES = -DSTM32 -DSTM32F1 -DSTM32F103xB -DHEAP_SIZE=$(HEAP_SIZE) -DUSE_FULL_LL_DRIVER=1
MCUFLAGS = -mcpu=cortex-m3 -mlittle-endian -mfloat-abi=soft -mthumb -mno-unaligned-access
DEBUG_OPTIMIZE_FLAGS = -O0 -ggdb -gdwarf-2
CFLAGS = -Wall -Wextra --pedantic
CFLAGS_EXTRA = -nostartfiles -nodefaultlibs -nostdlib -fdata-sections -ffunction-sections
CFLAGS += $(DEFINES) $(MCUFLAGS) $(DEBUG_OPTIMIZE_FLAGS) $(CFLAGS_EXTRA) $(INCLUDES) $(CFLAGS_USER)

LDFLAGS = -static $(MCUFLAGS) -Wl,--start-group -lgcc -lc -lg -Wl,--end-group  -Wl,--gc-sections \
          -T $(CMSIS_PREFIX)gcc/linker/STM32F103XB_FLASH.ld $(LDFLAGS_USER)

.PHONY: dirs all clean flash erase

all: dirs $(PROJECT).bin $(PROJECT).s

dirs: | $(OUTPATH) $(CMSIS_DIR) $(PERIPH_DIR) $(DRIVER_DIR) $(USER_DIRS)

$(CMSIS_DIR):
	git clone https://github.com/STMicroelectronics/cmsis-device-f1.git $@

$(PERIPH_DIR):
	git clone https://github.com/STMicroelectronics/stm32f1xx-hal-driver.git $@

$(DRIVER_DIR):
	git clone https://github.com/STMicroelectronics/STM32CubeF1.git $@

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
               -f $(OPENOCD_SCRIPT_DIR)/target/stm32f1x.cfg

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
