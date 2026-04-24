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

    SIG_FILE=$(basename "$PGP_URL")
    TAR_FILE=$(basename "$DOWNLOAD_URL")

    #echo "==> Verifying PGP signature..."
    # import public keys
    #gpg --locate-keys torvalds@kernel.org gregkh@kernel.org >/dev/null 2>&1

    # Checking. 0 == errors
    #if gpg --verify "$SIG_FILE" "$TAR_FILE" >/dev/null 2>&1; then
    #    echo "==> Signature check: PASSED"
    #else
    #    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    #    echo "CRITICAL ERROR: PGP Signature verification failed!"
    #    echo "The source code might be corrupted or tampered with."
    #    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    #    exit 1
    #fi

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

