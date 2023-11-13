mkdir -p data
make -C bootloader LOADBIN=$PWD/data/load.bin
make -C bootstub
make -C nds-exception-stub STUBBIN=$PWD/data/exceptionstub.bin
make
