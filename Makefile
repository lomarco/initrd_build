SRC_DIR = initrd
PREFIX = /boot
TARGET_BASE = initramfs-linux-zen
TARGET_INSTALL = $(TARGET_BASE).img
TARGET_FALLBACK_NAME = $(TARGET_INSTALL:.img=-fallback.img)

COMPRESS ?= gzip

ifeq ($(COMPRESS),none)
	EXT =
	COMPRESS_CMD = cat
	DECOMPRESS_CMD = cat
else ifeq ($(COMPRESS),gzip)
	EXT = .gz
	COMPRESS_CMD = gzip
	DECOMPRESS_CMD = gzip -cd
else ifeq ($(COMPRESS),bz2)
	EXT = .bz2
	COMPRESS_CMD = bzip2
	DECOMPRESS_CMD = bzip2 -cd
else ifeq ($(COMPRESS),xz)
	EXT = .xz
	COMPRESS_CMD = xz -z
	DECOMPRESS_CMD = xz -cd
else
	$(error Unsupported compression specified: $(COMPRESS))
endif

TARGET = $(TARGET_BASE).img$(EXT)

all: build

build:
	cd $(SRC_DIR) && \
	find . -mindepth 1 -printf '%P\0' | \
	sort -z | \
	bsdtar --uid 0 --gid 0 --null -cnf - -T - | \
	bsdtar --null -cf - --format=newc @- | \
	$(COMPRESS_CMD) > ../$(TARGET)

decomp:
	@if [ ! -f $(TARGET) ]; then \
		echo "File $(TARGET) not found!"; exit 1; \
	fi
	$(DECOMPRESS_CMD) $(TARGET) | bsdtar -xf -

clean:
	rm -f $(TARGET_BASE)*

install:
	if [ -f $(PREFIX)/$(TARGET_INSTALL) ]; then \
		echo "Backup current initramfs to $(TARGET_FALLBACK_NAME)"; \
		mv -f $(PREFIX)/$(TARGET_INSTALL) $(PREFIX)/$(TARGET_FALLBACK_NAME); \
	fi
	cp -f $(TARGET) $(PREFIX)/$(TARGET_INSTALL)

.PHONY: all build clean decomp install
