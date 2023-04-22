# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Antonio Niño Díaz, 2023

BLOCKSDS	?= /opt/blocksds/core
BLOCKSDSEXT	?= /opt/blocksds/external

# User config
# ===========

NAME		:= bootstrap

GAME_TITLE	:= blocksds-hb-menu bootstrap
GAME_SUBTITLE	:= Built with BlocksDS
GAME_AUTHOR	:= github.com/blocksds/sdk
GAME_ICON	:= bootstrap.bmp

# DLDI and internal SD slot of DSi
# --------------------------------

# Root folder of the SD image
SDROOT		:= sdroot
# Name of the generated image it "DSi-1.sd" for no$gba in DSi mode
SDIMAGE		:= image.bin

# Source code paths
# -----------------

NITROFATDIR	:= # A single directory that is the root of NitroFAT

# Tools
# -----

MAKE		:= make
RM		:= rm -rf

# Verbose flag
# ------------

ifeq ($(VERBOSE),1)
V		:=
else
V		:= @
endif

# Directories
# -----------

ARM9DIR		:= arm9
ARM7DIR		:= arm7

# Build artfacts
# --------------

NITROFAT_IMG	:= build/nitrofat.bin
ROM		:= $(NAME).nds
ROM		:= $(NAME).nds

# Targets
# -------

.PHONY: all clean arm9 arm7 dldipatch sdimage

all: $(ROM) $(ROMDSI) \
	_ds_menu.dat ismat.dat ez5sys.bin \
	akmenu4.nds TTMENU.DAT _BOOT_MP.NDS \
	ACE3DS/_ds_menu.dat ACE3DS/_dsmenu.dat

clean:
	@echo "  CLEAN"
	$(V)$(MAKE) -f Makefile.arm9 clean --no-print-directory
	$(V)$(MAKE) -f Makefile.arm7 clean --no-print-directory
	$(V)$(RM) $(ROM) build $(SDIMAGE) \
	_ds_menu.dat ismat.dat ez5sys.bin \
	akmenu4.nds TTMENU.DAT _BOOT_MP.NDS \
	ACE3DS/_ds_menu.dat ACE3DS/_dsmenu.dat

arm9:
	$(V)+$(MAKE) -f Makefile.arm9 --no-print-directory

arm7:
	$(V)+$(MAKE) -f Makefile.arm7 --no-print-directory

ifneq ($(strip $(NITROFATDIR)),)
# Additional arguments for ndstool
NDSTOOL_FAT	:= -F $(NITROFAT_IMG)

$(NITROFAT_IMG): $(NITROFATDIR)
	@echo "  MKFATIMG $@ $(NITROFATDIR)"
	$(V)$(BLOCKSDS)/tools/mkfatimg/mkfatimg -t $(NITROFATDIR) $@

# Make the NDS ROM depend on the filesystem image only if it is needed
$(ROM): $(NITROFAT_IMG)
endif

# Combine the title strings
ifeq ($(strip $(GAME_SUBTITLE)),)
    GAME_FULL_TITLE := $(GAME_TITLE);$(GAME_AUTHOR)
else
    GAME_FULL_TITLE := $(GAME_TITLE);$(GAME_SUBTITLE);$(GAME_AUTHOR)
endif

$(ROM): arm9 arm7
	@echo "  NDSTOOL $@"
	$(V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-7 build/arm7.elf -9 build/arm9.elf \
		-b $(GAME_ICON) "$(GAME_FULL_TITLE)" \
		$(NDSTOOL_FAT)

$(ROMDSI): arm9 arm7
	@echo "  NDSTOOL $@"
	$(V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-7 build/arm7.elf -9 build/arm9i.elf \
		-b $(GAME_ICON) "$(GAME_FULL_TITLE)" \
		$(NDSTOOL_FAT)

_ds_menu.dat	:	$(ROM) r4tfv2.dldi
	@cp $(ROM) _ds_menu.nds
	@dlditool r4tfv2.dldi _ds_menu.nds
	@r4denc $< _ds_menu.nds $@

ACE3DS/_ds_menu.dat	:	$(ROM) ace3ds_sd.dldi
	@[ -d ACE3DS ] || mkdir -p ACE3DS
	@cp $(ROM) ACE3DS/_ds_menu.nds
	@dlditool ace3ds_sd.dldi ACE3DS/_ds_menu.nds
	@r4denc --key 0x4002 ACE3DS/_ds_menu.nds $@

# Alternative name for some ACE3DS clones.
ACE3DS/_dsmenu.dat	:	$(ROM) ace3ds_sd.dldi
	@[ -d ACE3DS ] || mkdir -p ACE3DS
	@cp $(ROM) ACE3DS/_dsmenu.nds
	@dlditool ace3ds_sd.dldi ACE3DS/_dsmenu.nds
	@r4denc --key 0x4002 ACE3DS/_dsmenu.nds $@

ez5sys.bin	:	$(ROM) EZ5V2.dldi
	@cp $< $@
	@dlditool EZ5V2.dldi $@

akmenu4.nds	:	$(ROM)  ak2_sd.dldi
	@cp $< $@
	@dlditool ak2_sd.dldi $@

TTMENU.DAT	:	$(ROM)  TTCARDIOLibrary.dldi
	@cp $< $@
	@dlditool TTCARDIOLibrary.dldi $@

_BOOT_MP.NDS	:	$(ROM) mpcf.dldi
	@cp $< $@
	@dlditool mpcf.dldi $@

ismat.dat	:	$(ROM) mati.dldi
	@cp $< $@
	@dlditool mati.dldi $@

#---------------------------------------------------------------------------------
# Building separate .dsi and .nds binaries here is done purely to allow the .nds
# binary to be used to replace various flashcart boot menus.
#
# This is *NOT* for general use, standard .nds files with a full header are DSi
# hybrid binaries.
#
#---------------------------------------------------------------------------------
bootstrap.cia: bootstrap.dsi
	make_cia --srl=bootstrap.dsi

#---------------------------------------------------------------------------------
bootstrap.dsi : $(TARGET).arm7.elf $(TARGET).arm9i.elf
	ndstool -u 00030004 -g HBLA -b bootstrap.bmp "nds-hb-menu bootstrap;built with devkitARM;http://devkitpro.org" -c $@ -7 $(TARGET).arm7.elf -9 $(TARGET).arm9i.elf

sdimage:
	@echo "  MKFATIMG $(SDIMAGE) $(SDROOT)"
	$(V)$(BLOCKSDS)/tools/mkfatimg/mkfatimg -t $(SDROOT) $(SDIMAGE)

dldipatch: $(ROM)
	@echo "  DLDITOOL $(ROM)"
	$(V)$(BLOCKSDS)/tools/dlditool/dlditool \
		$(BLOCKSDS)/tools/dldi/r4tfv2.dldi $(ROM)
