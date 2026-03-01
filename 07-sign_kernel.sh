#!/usr/bin/env bash

echo "==> [Stage 7] Securing boot chain with MOK signatures..."

# Skip signing if we are on Legacy BIOS
if [ "$UEFI_MODE" != "true" ]; then
    echo "==> Legacy BIOS detected (UEFI_MODE=false). Skipping Secure Boot signature process."
    exit 0
fi

# Ensure all necessary keys and versions are available
if [ -z "$MOK_KEY" ] || [ -z "$MOK_PEM" ]; then
    echo "MOK_KEY or MOK_PEM variables are not set. Cannot sign the kernel."
    exit 1
fi

if [ -z "$EXACT_KERNEL_VER" ]; then
    echo "EXACT_KERNEL_VER is not set. Cannot locate the kernel image in /boot."
    exit 1
fi

KERNEL_IMAGE="/boot/vmlinuz-${EXACT_KERNEL_VER}"

if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "FATAL: Kernel image not found at $KERNEL_IMAGE."
    exit 1
fi

echo "==> Signing ${KERNEL_IMAGE} with ${MOK_PEM}..."

# Execute sbsign.
# We output to a temporary file first to prevent corruption in case of failure.
TEMP_VMLINUZ=$(mktemp)
sbsign --key "$MOK_KEY" --cert "$MOK_PEM" --output "$TEMP_VMLINUZ" "$KERNEL_IMAGE"

if [ $? -eq 0 ]; then
    echo "==> Signature applied successfully. Replacing original kernel image..."

    # We use cp instead of mv to preserve original file permissions and SELinux contexts (if any)
    cp "$TEMP_VMLINUZ" "$KERNEL_IMAGE"
    rm -f "$TEMP_VMLINUZ"

    echo "==> Kernel signing completed."
else
    echo "sbsign failed to sign the kernel image."
    rm -f "$TEMP_VMLINUZ"
    exit 1
fi

echo "==> Stage 7 completed successfully."
echo "----------------------------------------"
echo "==> [PIPELINE COMPLETE] Please reboot the system."
echo "==> If you generated new MOK keys on Stage 2, your UEFI firmware will prompt you to enroll them on the next boot."
