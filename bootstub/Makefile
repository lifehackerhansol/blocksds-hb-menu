# SPDX-License-Identifier: CC0-1.0

BLOCKSDS	?= /opt/blocksds/core
BLOCKSDSEXT	?= /opt/blocksds/external

TARGET	:=	bootstub

PREFIX		:= arm-none-eabi-
CC		:= $(PREFIX)gcc
OBJCOPY		:= $(PREFIX)objcopy
RM		:= rm -rf

ifeq ($(VERBOSE),1)
V		:=
else
V		:= @
endif

../data/$(TARGET).bin: $(TARGET).elf
	@echo "  OBJCOPY $@"
	@$(OBJCOPY) -O binary $< $@

$(TARGET).elf: $(TARGET).s Makefile
	@echo "  CC      $<"
	$(V)$(CC) -Wl,-Ttext=0 -x assembler-with-cpp -nostartfiles -nostdlib $(TARGET).s -o $@


clean:
	@echo "  CLEAN"
	$(V)$(RM) -f $(TARGET).elf $(TARGET).bin
