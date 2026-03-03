#!/usr/bin/env bash

echo "==> [Stage 1] Updating package repository cache..."
apt update

# Core dependencies required for custom kernel compilation and MOK signing
REQUIRED_PACKAGES=(
    build-essential
    xz-utils
    git
    sbsigntool
    dkms
    libncurses-dev
    flex
    bison
    debhelper
    bc
    libdw-dev
    libssl-dev
    rsync
    wget
    openssl
)

# Dynamically inject linux-source into the dependency array if stock kernel is requested
if [ "$KERNEL_TYPE" = "stock" ]; then
    echo "==> Stock kernel configuration detected. Appending linux-source to dependencies..."
    REQUIRED_PACKAGES+=(linux-source)
fi

echo "==> Provisioning build dependencies..."
# Execute non-interactive package installation
apt install -y "${REQUIRED_PACKAGES[@]}"

echo "==> Stage 1 completed successfully."
echo "----------------------------------------"
echo
