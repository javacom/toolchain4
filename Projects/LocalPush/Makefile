# Makefile for gcc compiler for toolchain 4 (SDK Headers)

PROJECTNAME=LocalPush
APPFOLDER=$(PROJECTNAME).app
INSTALLFOLDER=$(PROJECTNAME).app

toolchain=/toolchain4
SDK=/toolchain4/sys
MINIMUMVERSION:=4.0
DEBUG=DEBUGOFF

#CC = $(toolchain)/pre/bin/arm-apple-darwin9-gcc
CC:=clang -ccc-host-triple arm-apple-darwin9 
CPP:=$(toolchain)/pre/bin/arm-apple-darwin9-g++
LD:=$(toolchain)/pre/bin/arm-apple-darwin9-gcc


LDFLAGS = -arch arm -lobjc 
LDFLAGS += -framework CoreFoundation 
LDFLAGS += -framework Foundation 
LDFLAGS += -framework UIKit 
LDFLAGS += -framework CoreGraphics
//LDFLAGS += -framework AVFoundation
//LDFLAGS += -framework AddressBook
//LDFLAGS += -framework AddressBookUI
//LDFLAGS += -framework AudioToolbox
//LDFLAGS += -framework AudioUnit
//LDFLAGS += -framework CFNetwork
//LDFLAGS += -framework CoreAudio
//LDFLAGS += -framework CoreData
//LDFLAGS += -framework CoreFoundation 
//LDFLAGS += -framework GraphicsServices
//LDFLAGS += -framework CoreLocation
//LDFLAGS += -framework ExternalAccessory
//LDFLAGS += -framework GameKit
//LDFLAGS += -framework IOKit
//LDFLAGS += -framework MapKit
//LDFLAGS += -framework MediaPlayer
//LDFLAGS += -framework MessageUI
//LDFLAGS += -framework MobileCoreServices
//LDFLAGS += -framework OpenAL
//LDFLAGS += -framework OpenGLES
//LDFLAGS += -framework QuartzCore
//LDFLAGS += -framework Security
//LDFLAGS += -framework StoreKit
//LDFLAGS += -framework System
//LDFLAGS += -framework SystemConfiguration
//LDFLAGS += -framework CoreSurface
//LDFLAGS += -framework GraphicsServices
//LDFLAGS += -framework Celestial
//LDFLAGS += -framework WebCore
//LDFLAGS += -framework WebKit
//LDFLAGS += -framework SpringBoardUI
//LDFLAGS += -framework TelephonyUI
//LDFLAGS += -framework JavaScriptCore
//LDFLAGS += -framework PhotoLibrary

LDFLAGS += -isysroot $(SDK)
LDFLAGS += -F"$(SDK)/System/Library/Frameworks"
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"
LDFLAGS += -bind_at_load
LDFLAGS += -multiply_defined suppress
LDFLAGS += -march=armv6
LDFLAGS += -mcpu=arm1176jzf-s 

CFLAGS += -ObjC -fblocks
CFLAGS += -std=c99 #-Wall 
CFLAGS += -isysroot $(SDK)
CFLAGS += -D__IPHONE_OS_VERSION_MIN_REQUIRED=40000
//CFLAGS += -Diphoneos_version_min=$(MINIMUMVERSION)
ifeq ($(DEBUG),DEBUGOFF)
CFLAGS += -O0 -g0
else
CFLAGS += -g
endif
CFLAGS += -Wno-attributes -Wno-trigraphs -Wreturn-type -Wunused-variable
CFLAGS += -D$(DEBUG)

ifeq ($(DEBUG),DEBUGOFF)
CPPFLAGS += -g0 -O2
else
CPPFLAGS += -g
endif
CPPFLAGS += -isysroot $(SDK)
//CPPFLAGS += -Diphoneos_version_min=$(MINIMUMVERSION)
CPPFLAGS += -D__IPHONE_OS_VERSION_MIN_REQUIRED=40000
CPPFLAGS += -Wno-attributes -Wno-trigraphs -Wreturn-type -Wunused-variable
CPPFLAGS += $(addprefix -I,$(SRCDIR))
CPPFLAGS += -I"$(SDK)/usr/include/c++/4.2.1" 
CPPFLAGS += -I"$(SDK)/usr/include/c++/4.2.1/armv7-apple-darwin9" 
CPPFLAGS += -D$(DEBUG)

BUILDDIR=./build/$(MINIMUMVERSION)
SRCDIR1=.
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SRCDIR1)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SRCDIR1)/*.c))
PCH=$(wildcard *.pch)
INFOPLIST=$(wildcard *Info.plist)

CFLAGS += -I"$(SRCDIR1)"
CPPLAGS += -I"$(SRCDIR1)"

all:	$(PROJECTNAME)

$(PROJECTNAME):	$(OBJS)
	$(LD) $(LDFLAGS) $(filter %.o,$^) -o $@ 

%.o:	%.m
	$(CC) --include $(PCH) -c $(CFLAGS) $< -o $@

%.o:	%.c
	$(CC) --include $(PCH) -c $(CFLAGS) $< -o $@

%.o:	%.cpp
	$(CPP) --include $(PCH) -c $(CPPFLAGS) $< -o $@

dist:	$(PROJECTNAME)
	rm -rf $(BUILDDIR)
	mkdir -p $(BUILDDIR)/$(APPFOLDER)
ifneq ($(RESOURCES),)
	cp -r $(RESOURCES) $(BUILDDIR)/$(APPFOLDER)
	rm -fr $(BUILDDIR)/$(APPFOLDER)/.svn
	rm -fr $(BUILDDIR)/$(APPFOLDER)/*/.svn
endif
	cp $(INFOPLIST) $(BUILDDIR)/$(APPFOLDER)/Info.plist
	@echo "APPL????" > $(BUILDDIR)/$(APPFOLDER)/PkgInfo
	export CODESIGN_ALLOCATE=$(toolchain)/pre/bin/arm-apple-darwin9-codesign_allocate; $(toolchain)/pre/bin/ldid -S $(PROJECTNAME)
	mv $(PROJECTNAME) $(BUILDDIR)/$(APPFOLDER)
	mkdir $(BUILDDIR)/Payload
	cd $(BUILDDIR)/Payload; ln -s ../$(APPFOLDER) .
	cd $(BUILDDIR); zip -r $(PROJECTNAME).ipa Payload
	rm -fr Payload

install: dist
	ping -t 3 -c 1 $(IPHONE_IP)
	ssh root@$(IPHONE_IP) 'rm -fr /Applications/$(INSTALLFOLDER)'
	scp -r $(BUILDDIR)/$(APPFOLDER) root@$(IPHONE_IP):/Applications/$(INSTALLFOLDER)
	@echo "Application $(INSTALLFOLDER) installed, please respring iPhone"
	ssh root@$(IPHONE_IP) 'respring'

uninstall:
	ping -t 3 -c 1 $(IPHONE_IP)
	ssh root@$(IPHONE_IP) 'rm -fr /Applications/$(INSTALLFOLDER); respring'
	@echo "Application $(INSTALLFOLDER) uninstalled, please respring iPhone"

clean:
	@rm -f $(SRCDIR1)/*.o
	@rm -rf $(BUILDDIR)
	@rm -f $(PROJECTNAME)

