# RXKeySystem - Makefile
# Собирает систему ключей в отдельный dylib

TARGET_OS     = iphone
ARCHS         = arm64
MIN_IOS_VER   = 14.0

CC            = xcrun -sdk iphoneos clang
CFLAGS        = -arch arm64 \
                -miphoneos-version-min=$(MIN_IOS_VER) \
                -fobjc-arc \
                -fmodules \
                -O2 \
                -Wall

LDFLAGS       = -arch arm64 \
                -miphoneos-version-min=$(MIN_IOS_VER) \
                -dynamiclib \
                -framework Foundation \
                -framework UIKit \
                -framework Security \
                -framework CommonCrypto \
                -install_name @rpath/RXKeySystem.dylib

SRCS          = RXKeyManager.m RXActivationViewController.m
OBJS          = $(SRCS:.m=.o)
OUTPUT        = RXKeySystem.dylib

all: $(OUTPUT)

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

$(OUTPUT): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $@
	@echo "✓ Собрано: $(OUTPUT)"

clean:
	rm -f $(OBJS) $(OUTPUT)

.PHONY: all clean
