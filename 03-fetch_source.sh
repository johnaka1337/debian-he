#!/usr/bin/env bash

echo "==> [Stage 3] Fetching kernel source tree..."

mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

if [ "$KERNEL_TYPE" = "vanilla" ]; then
    echo "==> Fetching latest stable kernel info from releases.json..."

    JSON_DATA=$(wget -qO- https://www.kernel.org/releases.json)

    KERNEL_VERSION=$(echo "$JSON_DATA" | jq -r '[.releases[] | select(.moniker=="stable")] | first | .version')
    DOWNLOAD_URL=$(echo "$JSON_DATA" | jq -r '[.releases[] | select(.moniker=="stable")] | first | .source')
    PGP_URL=$(echo "$JSON_DATA" | jq -r '[.releases[] | select(.moniker=="stable")] | first | .pgp')

    if [ -z "$KERNEL_VERSION" ] || [ "$KERNEL_VERSION" == "null" ]; then
        echo "Error: Could not parse stable kernel version from JSON."
        exit 1
    fi

    echo "==> Latest stable is ${KERNEL_VERSION}"
    echo "==> Downloading tarball and signature..."
    wget -c "$DOWNLOAD_URL"
    wget -nc "$PGP_URL"

    TAR_FILE=$(basename "$DOWNLOAD_URL")
    SIG_FILE=$(basename "$PGP_URL")
    UNCOMPRESSED_TAR="${TAR_FILE%.xz}"

    echo "==> Importing kernel maintainer PGP keys via gpg2 (WKD)..."
    gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org

    echo "==> Decompressing tarball for signature verification (per kernel.org spec)..."
    xz -dk "$TAR_FILE"

    echo "==> Verifying PGP signature using gpg2..."
    if gpg2 --trust-model tofu --verify "$SIG_FILE" "$UNCOMPRESSED_TAR" >/dev/null 2>&1; then
        echo "==> Signature check: PASSED"
    else
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "CRITICAL ERROR: PGP Signature verification failed!"
        echo "The source code might be corrupted or tampered with."
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        rm -f "$UNCOMPRESSED_TAR"
        exit 1
    fi

    # Убираем временный несжатый тарболл, чтобы не занимать место, распаковывать будем штатно
    rm -f "$UNCOMPRESSED_TAR"

    echo "==> Unpacking vanilla archive..."
    tar -xf "$TAR_FILE"
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

# =====================================================================
# Hardware Workaround: Detect mobile AMD Ryzen without tsc_adjust
# =====================================================================
if grep -q "AuthenticAMD" /proc/cpuinfo && ! grep -qw "tsc_adjust" /proc/cpuinfo && grep -qi "Ryzen" /proc/cpuinfo; then
    echo "==> [Hardware Workaround] Detected mobile AMD Ryzen without tsc_adjust."
    PATCH_FILE="${REPO_DIR:-..}/kernel_patches/001-tsc_sync.patch"

    if [ -f "$PATCH_FILE" ]; then
        echo "==> Applying tsc_sync patch to ${KERNEL_SRC_DIR}..."
        patch -p1 -d "$KERNEL_SRC_DIR" --forward < "$PATCH_FILE"
        if [ $? -eq 0 ]; then
            echo "==> Patch 001-tsc_sync.patch applied successfully."
        else
            echo "CRITICAL: Failed to apply 001-tsc_sync.patch cleanly. Check rejects."
            exit 1
        fi
    else
        echo "CRITICAL: Required patch not found at $PATCH_FILE"
        exit 1
    fi
fi

echo "==> Stage 3 completed successfully."
echo "----------------------------------------"
echo
