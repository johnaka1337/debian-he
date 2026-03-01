#!/usr/bin/env bash

echo "==> [Stage 5] Initiating kernel compilation and Debian packaging..."

if [ -z "$KERNEL_SRC_DIR" ] || [ ! -d "$KERNEL_SRC_DIR" ]; then
    echo "KERNEL_SRC_DIR is not set or directory does not exist: $KERNEL_SRC_DIR"
    exit 1
fi

cd "$KERNEL_SRC_DIR"


TOTAL_CPU_CORES="$(nproc)"
echo "==> Detected ${TOTAL_CPU_CORES} CPU threads. Starting parallel build..."

make -j"${TOTAL_CPU_CORES}" bindeb-pkg

echo
echo "==> Stage 5 completed successfully."
echo "==> Compilation finished. Debian packages are located in ${WORK_DIR}"
echo "----------------------------------------"
echo
