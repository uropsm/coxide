@SET projpath=%cd%
@SET makepath=%~dp0
@SET makepath=%makepath:~0,-1%

@cd build
%makepath%\..\tools\openocd\win32\openocd\bin\openocd.exe -s "%makepath%\..\tools\openocd\win32\openocd\scripts" -f "%makepath%\..\tools\openocd\win32\openocd\scripts\board\atmel_samr21_xplained_pro.cfg" -c "program output.bin verify reset exit"
@cd ..
