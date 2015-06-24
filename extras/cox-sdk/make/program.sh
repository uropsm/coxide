#!/bin/sh

projpath=`pwd`
makepath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

openocdpath=/Users/jsjeong/Work/openocd/install/osx/openocd

cd build
echo $openocdpath/bin/openocd -s "$openocdpath/scripts" -f "$openocdpath/scripts/board/atmel_samr21_xplained_pro.cfg" -c "program build/output.bin verify reset exit"

#$makepath/../tools/openocd/osx/bin/openocd \
#    -s "$makepath/../tools/openocd/osx/share/openocd/scripts" \
#    -f "$makepath/../tools/openocd/osx/share/openocd/scripts/board/atmel_samr21_xplained_pro.cfg" \
#    -c "program output.bin verify reset exit"

$openocdpath/bin/openocd \
    -s "$openocdpath/scripts" \
    -f "$openocdpath/scripts/board/atmel_samr21_xplained_pro.cfg" \
    -c "program output.bin verify reset exit"
cd $projpath
