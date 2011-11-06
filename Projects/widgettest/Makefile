export THEOS=/toolchain4/theos
export SDKBINPATH=/toolchain4/pre/bin
export SYSROOT=/toolchain4/sys50
export TARGET_CXX=clang -ccc-host-triple arm-apple-darwin9 
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = widgettest
widgettest_FILES = widgettestController.m
widgettest_INSTALL_PATH = /System/Library/WeeAppPlugins/
widgettest_FRAMEWORKS = UIKit CoreGraphics

IPHONEOSMINVERSION:=50000
ADDITIONAL_CFLAGS = -D__IPHONE_OS_VERSION_MIN_REQUIRED=$(IPHONEOSMINVERSION)

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
