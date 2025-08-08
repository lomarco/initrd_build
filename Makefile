PWD = $(shell pwd)
SRC_DIR = initrd
ALL_FILES = $(shell find $(SRC_DIR))
PREFIX = /boot

TARGET_INSTALL = initramfs-linux-zen.img
TARGET = initramfs.cpio.gz

all: build

build:
	cd $(SRC_DIR) && \
	find . -mindepth 1 -printf '%P\0' | \
	sort -z | \
	bsdtar --uid 0 --gid 0 --null -cnf - -T - | \
	bsdtar --null -cf - --format=newc @- | \
	gzip > ../$(TARGET)

clean:
	rm -f $(TARGET)

install:
	cp $(TARGET) $(PREFIX)/$(TARGET_INSTALL)

.PHONY: all build clean decomp
