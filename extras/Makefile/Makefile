CC=C:\coxide\tools\MinGW\bin\gcc.exe
CCFLAGS=-Wall
LDFLAGS=
SOURCES=$(wildcard *.c)
OBJECTS=$(SOURCES:.c=.o)
TARGET=des
 
all: $(TARGET)
 
$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^
 
%.o: %.c %.h
	$(CC) $(CCFLAGS) -c $<
 
%.o: %.c
	$(CC) $(CCFLAGS) -c $<
 
clean:
	rm -f *.o $(TARGET)