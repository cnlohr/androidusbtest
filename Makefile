
APPNAME=androidusbtest
RAWDRAWANDROID=rawdrawandroid
CFLAGS:=-I. -ffunction-sections -Os
LDFLAGS:=-s
PACKAGENAME?=org.yourorgexample.$(APPNAME)
SRC:=test.c rawdrawandroid/android_usb_devices.c
ANDROIDVERSION:=32

include rawdrawandroid/Makefile


