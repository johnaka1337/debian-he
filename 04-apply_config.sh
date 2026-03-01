#!/usr/bin/env bash

echo "==> [Stage 4] Applying custom kernel configuration and compiler optimizations..."

if [ ! -f "$KERNEL_CONFIG" ]; then
    echo "Custom .config not found at $KERNEL_CONFIG"
    exit 1
fi

echo "==> Copying $KERNEL_CONFIG to $KERNEL_SRC_DIR/.config..."
cd "$KERNEL_SRC_DIR"
cp "$KERNEL_CONFIG" "./config"


echo "==> Injecting compiler optimizations (-pipe -march=native -mtune=native) into Makefile..."
sed -i 's/-O2/-O2 -pipe -march=native -mtune=native/g' Makefile

echo "==> Stage 4 completed successfully."
echo "----------------------------------------"
echo
