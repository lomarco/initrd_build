SRC_DIR := initrd
PREFIX := /boot

TARGET_BASE := initramfs-linux-zen
TARGET_INSTALL := $(TARGET_BASE).img
TARGET_FALLBACK := $(TARGET_INSTALL:.img=-fallback.img)
DECOMP_DIR := extracted_initramfs

COMPRESS ?= gzip

ifeq ($(COMPRESS),none)
	EXT :=
	COMPRESS_CMD := cat
	DECOMPRESS_CMD := cat
else ifeq ($(COMPRESS),gzip)
	EXT := .gz
	COMPRESS_CMD := gzip
	DECOMPRESS_CMD := gzip -cd
else ifeq ($(COMPRESS),bz2)
	EXT := .bz2
	COMPRESS_CMD := bzip2
	DECOMPRESS_CMD := bzip2 -cd
else ifeq ($(COMPRESS),xz)
	EXT := .xz
	COMPRESS_CMD := xz -z
	DECOMPRESS_CMD := xz -cd
else
$(error Unsupported compression specified: $(COMPRESS))
endif

TARGET := $(TARGET_BASE).img$(EXT)

all: build

build:
	@echo "Building initramfs image: $(TARGET)"
	@cd $(SRC_DIR) && set -e; \
	find . -mindepth 1 -printf '%P\0' | sort -z | \
	bsdtar --uid 0 --gid 0 --null -cnf - -T - | \
	bsdtar --null -cf - --format=newc @- | \
	$(COMPRESS_CMD) > ../$(TARGET)

decomp:
	@if [ ! -f $(TARGET) ]; then \
		echo "File $(TARGET) not found!"; exit 1; \
	fi
	@mkdir -p $(DECOMP_DIR)
	@echo "Decompressing and extracting $(TARGET) into $(DECOMP_DIR)..."
	@$(DECOMPRESS_CMD) $(TARGET) | bsdtar -xf - -C $(DECOMP_DIR)

clean:
	@rm -rf $(TARGET_BASE)* $(DECOMP_DIR)

install:
	@if [ ! -f "$(TARGET)" ]; then \
		echo "Error: Target file '$(TARGET)' does not exist!"; \
		exit 1; \
	fi
	@if [ -f $(PREFIX)/$(TARGET_INSTALL) ]; then \
		echo "Backing up current initramfs to $(TARGET_FALLBACK)"; \
		sudo mv -f $(PREFIX)/$(TARGET_INSTALL) $(PREFIX)/$(TARGET_FALLBACK); \
	fi
	@echo "Installing new initramfs image to $(PREFIX)/$(TARGET_INSTALL)"
	@sudo cp -f $(TARGET) $(PREFIX)/$(TARGET_INSTALL)

.PHONY: all build clean decomp install
