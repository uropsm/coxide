@SET projpath=%cd%
@SET makepath=%~dp0
@SET makepath=%makepath:~0,-1%
@mkdir build
@cd /d %makepath%
@win32\make.exe -C "%projpath%\build" -f "%makepath%\Makefile.build" BOARD=atsamr21-xpro OS=win32
@cd /d %projpath%
