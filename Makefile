PROJECT = MYSBootloader

MCU = atmega328p
CLK = 16000000L
BAUDRATE = 115200


ISP_PORT = com5
ISP_SPEED = $(BAUDRATE)
ISP_PROTOCOL = stk500v2
ISP_MCU = m328p
ISP_HFUSE = DA
ISP_LFUSE = F7
ISP_EFUSE = 06
ISP_ARGS = -c$(ISP_PROTOCOL) -P$(ISP_PORT) -b$(ISP_SPEED) -p$(ISP_MCU)

ifeq ($(OS),Windows_NT)
	BINPATH = C:/Program Files (x86)/Atmel/Studio/7.0/toolchain/avr8/avr8-gnu-toolchain/bin/
	INCLUDES = C:/Program Files (x86)/Atmel/Studio/7.0/toolchain/avr8/avr8-gnu-toolchain/avr/include/avr		
else
	UNAME_S := $(shell uname -s)
	UNAME_P := $(shell uname -p)
	UNAME_M := $(shell uname -m)
	ifeq ($(UNAME_S),Linux)
		ifeq ($(UNAME_P),x86_64)
			BINPATH = ../arduino/bin-linux64/bin/
		else ifneq ($(filter %86,$(UNAME_P)),)
			BINPATH = ../arduino/bin-linux32/bin/
		else ifneq ($(filter arm%,$(UNAME_M)),)
			BINPATH = /usr/bin/
		endif
	endif
endif

CFLAGS = -funsigned-char -funsigned-bitfields -DF_CPU=$(CLK) -DBAUD_RATE=$(BAUDRATE) -Os -ffunction-sections -fdata-sections -fpack-struct -fshort-enums -mrelax -Wall -Wextra -Wundef -pedantic -mmcu=$(MCU) -c -std=gnu99 -MD -MP -MF "$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)" 
LDFLAGS = -nostartfiles -Wl,-s -Wl,-static -Wl,-Map="$(OutputFileName).map" -Wl,--start-group -Wl,--end-group -Wl,--gc-sections -mrelax -Wl,-section-start=.text=0x7800 -mmcu=$(MCU)  


all: clean out

clean:
	- rm *.o
	- rm *.elf
	- rm *.hex

$(PROJECT).o: $(PROJECT).c
	"$(BINPATH)avr-gcc" -I"$(INCLUDES)" $(CFLAGS) $< -o $@

$(PROJECT).elf: $(PROJECT).o
	"$(BINPATH)avr-gcc" $(LDFLAGS) -o $@ $< -lm
	
$(PROJECT).hex: $(PROJECT).elf
	"$(BINPATH)avr-objcopy" -O ihex -R .eeprom $< $@ 

out: $(PROJECT).hex
	"$(BINPATH)avr-size" $(PROJECT).elf

load: clean out isp

isp: $(PROJECT).hex
	"$(BINPATH)avrdude" $(ISP_ARGS) -e -u -Ulock:w:0x3f:m -qq -Uefuse:w:0x$(ISP_EFUSE):m -Uhfuse:w:0x$(ISP_HFUSE):m -Ulfuse:w:0x$(ISP_LFUSE):m -Ulock:w:0x0f:m
	"$(BINPATH)avrdude" $(ISP_ARGS) -V -q -s -Uflash:w:$(PROJECT).hex
	"$(BINPATH)avrdude" $(ISP_ARGS)
