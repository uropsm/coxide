all :
	@echo "Usage: make {win32|osx}"

win32 : gcc-arm-none-eabi-4_9-2015q1-20150306-win32.zip
	mkdir $@
	unzip $< -d $@

gcc-arm-none-eabi-4_9-2015q1-20150306-win32.zip :
	wget https://launchpad.net/gcc-arm-embedded/4.9/4.9-2015-q1-update/+download/$@

osx : gcc-arm-none-eabi-4_9-2015q1-20150306-mac.tar.bz2
	tar xvjf $<
	mv gcc-arm-none-eabi-4_9-2015q1 osx

gcc-arm-none-eabi-4_9-2015q1-20150306-mac.tar.bz2 :
	wget https://launchpad.net/gcc-arm-embedded/4.9/4.9-2015-q1-update/+download/$@

clean :
	rm -rf win32 gcc-arm-none-eabi-4_9-2015q1-20150306-win32.zip
	rm -rf osx gcc-arm-none-eabi-4_9-2015q1-20150306-mac.tar.bz2
