# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Antonio Niño Díaz, 2023

BLOCKSDS	?= /opt/blocksds/core
BLOCKSDSEXT	?= /opt/blocksds/external

# User config
# ===========

NAME		:= hbmenu

GAME_TITLE	:= Homebrew Menu
GAME_SUBTITLE	:= Built with BlocksDS
GAME_AUTHOR	:= github.com/blocksds/sdk
GAME_ICON	:= icon.bmp

export HBMENU_MAJOR	:= 0
export HBMENU_MINOR	:= 9
export HBMENU_PATCH	:= 0-blocks

VERSION	:=	$(HBMENU_MAJOR).$(HBMENU_MINOR).$(HBMENU_PATCH)

# DLDI and internal SD slot of DSi
# --------------------------------

# Root folder of the SD image
SDROOT		:= sdroot
# Name of the generated image it "DSi-1.sd" for no$gba in DSi mode
SDIMAGE		:= image.bin

# Source code paths
# -----------------

SOURCEDIRS	:= source
INCLUDEDIRS	:=
GFXDIRS		:= gfx
BINDIRS		:= data
AUDIODIRS	:=
NITROFATDIR	:=

# Defines passed to all files
# ---------------------------

DEFINES		:=

# Libraries
# ---------

LIBS		:= -lnds9 -lc -lstdc++
LIBDIRS		:= $(BLOCKSDS)/libs/maxmod \
		   $(BLOCKSDS)/libs/libnds

# Build artifacts
# ---------------

BUILDDIR	:= build
ELF		:= build/$(NAME).elf
DUMP		:= build/$(NAME).dump
NITROFAT_IMG	:= build/nitrofat.bin
MAP		:= build/$(NAME).map
SOUNDBANKDIR	:= $(BUILDDIR)/maxmod
ROM		:= $(NAME).nds

# Tools
# -----

PREFIX		:= arm-none-eabi-
CC		:= $(PREFIX)gcc
CXX		:= $(PREFIX)g++
OBJDUMP		:= $(PREFIX)objdump
MKDIR		:= mkdir
RM		:= rm -rf

# Verbose flag
# ------------

ifeq ($(VERBOSE),1)
V		:=
else
V		:= @
endif

# Source files
# ------------

ifneq ($(BINDIRS),)
    SOURCES_BIN	:= $(shell find -L $(BINDIRS) -name "*.bin")
    INCLUDEDIRS	+= $(addprefix $(BUILDDIR)/,$(BINDIRS))
endif
ifneq ($(GFXDIRS),)
    SOURCES_PNG	:= $(shell find -L $(GFXDIRS) -name "*.png")
    INCLUDEDIRS	+= $(addprefix $(BUILDDIR)/,$(GFXDIRS))
endif
ifneq ($(AUDIODIRS),)
    SOURCES_AUDIO	:= $(shell find -L $(AUDIODIRS) -regex '.*\.\(it\|mod\|s3m\|wav\|xm\)')
    ifneq ($(SOURCES_AUDIO),)
        INCLUDEDIRS	+= $(SOUNDBANKDIR)
    endif
endif

SOURCES_S	:= $(shell find -L $(SOURCEDIRS) -name "*.s")
SOURCES_C	:= $(shell find -L $(SOURCEDIRS) -name "*.c")
SOURCES_CPP	:= $(shell find -L $(SOURCEDIRS) -name "*.cpp")

# Compiler and linker flags
# -------------------------

DEFINES		+= -D__NDS__ -DARM9

ARCH		:= -march=armv5te -mtune=arm946e-s

WARNFLAGS	:= -Wall

ifeq ($(SOURCES_CPP),)
    LD	:= $(CC)
else
    LD	:= $(CXX)
endif

INCLUDEFLAGS	:= $(foreach path,$(INCLUDEDIRS),-I$(path)) \
		   $(foreach path,$(LIBDIRS),-I$(path)/include)

LIBDIRSFLAGS	:= $(foreach path,$(LIBDIRS),-L$(path)/lib)

ASFLAGS		+= -x assembler-with-cpp $(DEFINES) $(ARCH) \
		   -mthumb -mthumb-interwork $(INCLUDEFLAGS) \
		   -ffunction-sections -fdata-sections

CFLAGS		+= -std=gnu11 $(WARNFLAGS) $(DEFINES) $(ARCH) \
		   -mthumb -mthumb-interwork $(INCLUDEFLAGS) -O2 \
		   -ffunction-sections -fdata-sections \
		   -fomit-frame-pointer

CXXFLAGS	+= -std=gnu++14 $(WARNFLAGS) $(DEFINES) $(ARCH) \
		   -mthumb -mthumb-interwork $(INCLUDEFLAGS) -O2 \
		   -ffunction-sections -fdata-sections \
		   -fno-exceptions -fno-rtti \
		   -fomit-frame-pointer

LDFLAGS		:= -mthumb -mthumb-interwork $(LIBDIRSFLAGS) \
		   -Wl,-Map,$(MAP) -Wl,--gc-sections -nostdlib \
		   -T$(BLOCKSDS)/sys/crts/ds_arm9.mem \
		   -T$(BLOCKSDS)/sys/crts/ds_arm9.ld \
		   -Wl,--no-warn-rwx-segments \
		   -Wl,--start-group $(LIBS) -lgcc -Wl,--end-group

# Intermediate build files
# ------------------------

OBJS_ASSETS	:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_BIN))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_PNG)))

HEADERS_ASSETS	:= $(patsubst %.bin,%_bin.h,$(addprefix $(BUILDDIR)/,$(SOURCES_BIN))) \
		   $(patsubst %.png,%.h,$(addprefix $(BUILDDIR)/,$(SOURCES_PNG)))

ifneq ($(SOURCES_AUDIO),)
    OBJS_ASSETS		+= $(SOUNDBANKDIR)/soundbank.c.o
    HEADERS_ASSETS	+= $(SOUNDBANKDIR)/soundbank.h
endif

OBJS_SOURCES	:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_S))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_C))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_CPP)))

OBJS		:= $(OBJS_ASSETS) $(OBJS_SOURCES)

DEPS		:= $(OBJS:.o=.d)

# Targets
# -------

.PHONY: bootloader bootstub BootStrap exceptionstub all clean dump dldipatch sdimage cia

all: bootloader bootstub exceptionstub $(ROM) BootStrap

cia:
	$(MAKE) -C BootStrap bootstrap.cia

dist:	all
	rm	-fr	hbmenu
	mkdir -p hbmenu/nds
	cp hbmenu.nds hbmenu/BOOT.NDS
	cp BootStrap/_BOOT_MP.NDS BootStrap/TTMENU.DAT BootStrap/_ds_menu.dat BootStrap/ez5sys.bin BootStrap/akmenu4.nds BootStrap/ismat.dat hbmenu
	cp -r BootStrap/ACE3DS hbmenu
ifneq (,$(wildcard BootStrap/bootstrap.cia))
	cp "BootStrap/bootstrap.cia" hbmenu
endif
	cp testfiles/* hbmenu/nds
	zip -9r hbmenu-$(VERSION).zip hbmenu README.md COPYING

ifneq ($(strip $(NITROFATDIR)),)
# Additional arguments for ndstool
NDSTOOL_FAT	:= -F $(NITROFAT_IMG)

$(NITROFAT_IMG): $(NITROFATDIR)
	@echo "  MKFATIMG $@ $(NITROFATDIR)"
	$(V)$(BLOCKSDS)/tools/mkfatimg/mkfatimg -t $(NITROFATDIR) $@ 0

# Make the NDS ROM depend on the filesystem image only if it is needed
$(ROM): $(NITROFAT_IMG)
endif

# Combine the title strings
ifeq ($(strip $(GAME_SUBTITLE)),)
    GAME_FULL_TITLE := $(GAME_TITLE);$(GAME_AUTHOR)
else
    GAME_FULL_TITLE := $(GAME_TITLE);$(GAME_SUBTITLE);$(GAME_AUTHOR)
endif

$(ROM): $(ELF)
	@echo "  NDSTOOL $@"
	$(V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-7 $(BLOCKSDS)/sys/default_arm7/arm7.elf -9 $(ELF) \
		-b $(GAME_ICON) "$(GAME_FULL_TITLE)" \
		$(NDSTOOL_FAT)

$(ELF): $(OBJS)
	@echo "  LD      $@"
	$(V)$(LD) -o $@ $(OBJS) $(BLOCKSDS)/sys/crts/ds_arm9_crt0.o $(LDFLAGS)

$(DUMP): $(ELF)
	@echo "  OBJDUMP   $@"
	$(V)$(OBJDUMP) -h -C -S $< > $@

dump: $(DUMP)

clean:
	@echo "  CLEAN"
	$(V)$(RM) $(ROM) $(DUMP) $(BUILDDIR) $(SDIMAGE) $(BINDIRS)
	$(V)+$(MAKE) -C bootloader clean
	$(V)+$(MAKE) -C bootstub clean
	$(V)+$(MAKE) -C BootStrap clean
	$(V)+$(MAKE) -C nds-exception-stub clean

sdimage:
	@echo "  MKFATIMG $(SDIMAGE) $(SDROOT)"
	$(V)$(BLOCKSDS)/tools/mkfatimg/mkfatimg -t $(SDROOT) $(SDIMAGE) 0

dldipatch: $(ROM)
	@echo "  DLDITOOL $(ROM)"
	$(V)$(BLOCKSDS)/tools/dlditool/dlditool \
		$(BLOCKSDS)/tools/dldi/r4tfv2.dldi $(ROM)

data:
	$(V)$(MKDIR) -p data

bootloader: data
	$(V)+$(MAKE) -C bootloader LOADBIN=$(CURDIR)/data/load.bin

exceptionstub: data
	$(V)+$(MAKE) -C nds-exception-stub STUBBIN=$(CURDIR)/data/exceptionstub.bin

bootstub: data
	$(V)+$(MAKE) -C bootstub

BootStrap:
	$(V)+$(MAKE) -C BootStrap

# Rules
# -----

$(BUILDDIR)/%.s.o : %.s
	@echo "  AS      $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CC) $(ASFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.c.o : %.c
	@echo "  CC      $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.cpp.o : %.cpp
	@echo "  CXX     $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CXX) $(CXXFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.bin.o $(BUILDDIR)/%_bin.h : %.bin
	@echo "  BIN2C   $<"
	@$(MKDIR) -p $(@D)
	$(V)$(BLOCKSDS)/tools/bin2c/bin2c $< $(@D)
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $(BUILDDIR)/$*.bin.o $(BUILDDIR)/$*_bin.c

$(BUILDDIR)/%.png.o $(BUILDDIR)/%.h : %.png %.grit
	@echo "  GRIT    $<"
	@$(MKDIR) -p $(@D)
	$(V)$(BLOCKSDS)/tools/grit/grit $< -ftc -W1 -o$(BUILDDIR)/$*
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $(BUILDDIR)/$*.png.o $(BUILDDIR)/$*.c
	$(V)touch $(BUILDDIR)/$*.png.o $(BUILDDIR)/$*.h

$(SOUNDBANKDIR)/soundbank.h: $(SOURCES_AUDIO)
	@echo "  MMUTIL  $^"
	@$(MKDIR) -p $(@D)
	@$(BLOCKSDS)/tools/mmutil/mmutil $^ -d \
		-o$(SOUNDBANKDIR)/soundbank.bin -h$(SOUNDBANKDIR)/soundbank.h

$(SOUNDBANKDIR)/soundbank.c.o: $(SOUNDBANKDIR)/soundbank.h
	@echo "  BIN2C   soundbank.bin"
	$(V)$(BLOCKSDS)/tools/bin2c/bin2c $(SOUNDBANKDIR)/soundbank.bin \
		$(SOUNDBANKDIR)
	@echo "  CC.9    soundbank_bin.c"
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $(SOUNDBANKDIR)/soundbank.c.o \
		$(SOUNDBANKDIR)/soundbank_bin.c

# All assets must be built before the source code
# -----------------------------------------------

$(SOURCES_S) $(SOURCES_C) $(SOURCES_CPP): $(HEADERS_ASSETS)

# Include dependency files if they exist
# --------------------------------------

-include $(DEPS)
