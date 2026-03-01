#!/usr/bin/env bash

echo "==> [Stage 6] Installing generated Debian kernel packages..."

# Ensure the kernel source directory is valid before proceeding
if [ -z "$KERNEL_SRC_DIR" ] || [ ! -d "$KERNEL_SRC_DIR" ]; then
    echo "FATAL: KERNEL_SRC_DIR is not set or directory does not exist: $KERNEL_SRC_DIR"
    exit 1
fi

# Retrieve the exact kernel version (including localversion) directly from the build system
export EXACT_KERNEL_VER=$(make -s kernelrelease)
echo "==> Target kernel release to install: $EXACT_KERNEL_VER"

# Navigate to the directory where bindeb-pkg outputs the .deb files
cd "$WORK_DIR"

# Fetch exactly one package of each type with the highest version/revision number.
# 'ls -v' performs a natural sort of version numbers, and 'tail -n 1' picks the highest one.
LATEST_IMAGE=$(ls -v linux-image-${EXACT_KERNEL_VER}_*.deb 2>/dev/null | tail -n 1)
LATEST_HEADERS=$(ls -v linux-headers-${EXACT_KERNEL_VER}_*.deb 2>/dev/null | tail -n 1)

# The libc-dev package name does not include the localversion suffix, so we match it using a base wildcard.
LATEST_LIBC=$(ls -v linux-libc-dev_*.deb 2>/dev/null | tail -n 1)

# Combine the found packages into a single string
DEB_PACKAGES="$LATEST_IMAGE $LATEST_HEADERS $LATEST_LIBC"

# Trim any extra whitespace in case a specific package (like libc-dev) was not generated
DEB_PACKAGES=$(echo "$DEB_PACKAGES" | xargs)

# Verify that we actually found packages to install
if [ -z "$DEB_PACKAGES" ]; then
    echo "FATAL: No generated .deb packages found for version $EXACT_KERNEL_VER in $WORK_DIR."
    exit 1
fi

echo "==> Found the latest matching packages by version:"
for pkg in $DEB_PACKAGES; do
    echo "  -> $pkg"
done

echo "==> Installing packages via dpkg..."
# Install the selected packages.
# NOTE: dpkg will automatically trigger initramfs-tools and update-grub via post-install hooks.
dpkg -i $DEB_PACKAGES

echo "==> Stage 6 completed successfully."
echo "==> The new custom kernel ($EXACT_KERNEL_VER) has been installed."
echo "----------------------------------------"
echo
