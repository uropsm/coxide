#!/bin/bash

projpath=`pwd`
makepath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

mkdir build
cd $makepath
make -C $projpath/build -f $makepath/Makefile.build BOARD=atsamr21-xpro OS=osx
cd $makepath
