#!/usr/bin/env bash

echo "==> [Stage 3] Fetching kernel source tree..."

mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

if [ "$KERNEL_TYPE" = "vanilla" ]; then
    echo "==> Fetching latest stable kernel version from kernel.org via wget..."

    KERNEL_VERSION=$(wget -qO- https://www.kernel.org/ | grep -A1 'id="latest_link"' | tail -n1 | grep -oP '(?<=href=").*?(?=")' | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || true)

    if [ -z "$KERNEL_VERSION" ]; then
        echo "Failed to determine latest kernel version."
        exit 1
    fi

    MAJOR_VERSION=$(echo "$KERNEL_VERSION" | cut -d. -f1)
    DOWNLOAD_URL="https://cdn.kernel.org/pub/linux/kernel/v${MAJOR_VERSION}.x/linux-${KERNEL_VERSION}.tar.xz"

    echo "==> Downloading linux-${KERNEL_VERSION}.tar.xz..."
    wget -c "$DOWNLOAD_URL"

    echo "==> Unpacking vanilla archive..."
    tar -xf "linux-${KERNEL_VERSION}.tar.xz"

    KERNEL_SRC_DIR="${WORK_DIR}/linux-${KERNEL_VERSION}"

elif [ "$KERNEL_TYPE" = "stock" ]; then
    echo "==> Locating Debian linux-source package..."

    # Find the tarball downloaded by apt in Step 1
    DEBIAN_SRC_TAR=$(ls /usr/src/linux-source-*.tar.xz 2>/dev/null | head -n 1)

    if [ -z "$DEBIAN_SRC_TAR" ]; then
        echo "Debian kernel source archive not found in /usr/src."
        exit 1
    fi

    echo "==> Unpacking ${DEBIAN_SRC_TAR} to ${WORK_DIR}..."
    tar -xf "$DEBIAN_SRC_TAR"

    DIR_NAME=$(basename "$DEBIAN_SRC_TAR" .tar.xz)

    KERNEL_SRC_DIR="${WORK_DIR}/${DIR_NAME}"
    KERNEL_VERSION=$(echo "$DIR_NAME" | sed 's/linux-source-//')
else
    echo "Unknown KERNEL_TYPE: $KERNEL_TYPE"
    exit 1
fi

echo "==> Stage 3 completed successfully."
echo "----------------------------------------"
echo

