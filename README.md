stm32f411-gnat-blink
====================

The first baby-steps example for any microcontroller board, now in
Ada.

Building
--------

To compile the example, run ```gprbuild -p -P firmware.gpr```. This will
create =build= and =bin= directories, and put a compiled ELF binary in
bin/demo.

Uploading to the board
----------------------

You can use either stlink (https://github.com/texane/stlink) or
openocd (http://sourceforge.net/p/openocd/code/ci/master/tree/) to
upload the binary. Note that you will need to use openocd 0.9.0+ to
talk to this chip; I suggest you compile it from HEAD. Here's a sample
config file:

    # This is an STM32F4 discovery board with a single STM32F411 chip.
    # http://www.st.com/web/catalog/tools/FM116/SC959/SS1532/LN1847/PF260320

    source [find interface/stlink-v2-1.cfg]
    source [find board/st_nucleo_f4.cfg]

Et voila, you should have a nice little blinker!
