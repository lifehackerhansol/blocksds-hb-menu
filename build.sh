mkdir -p data
make -C bootloader LOADBIN=$PWD/data/load.bin
make -C BootStrap
make -C bootstub
make -C nds-exception-stub STUBBIN=$PWD/data/exceptionstub.bin
make
