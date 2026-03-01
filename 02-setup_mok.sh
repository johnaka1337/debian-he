#!/usr/bin/env bash

echo "==> [Stage 2] Checking firmware environment and MOK infrastructure..."
UEFI_MODE=""

if [ -d "/sys/firmware/efi" ]; then
    echo "==> UEFI firmware detected. Checking Secure Boot signing keys..."
    UEFI_MODE="true"

    # TODO: read an actual values from the DKMS settings (/etc/dkms/framework.conf)
    MOK_DIR="/var/lib/dkms"
    export MOK_KEY="${MOK_DIR}/mok.key"
    export MOK_PUB="${MOK_DIR}/mok.pub"
    export MOK_PEM="${MOK_DIR}/mok.pem"

    if [[ -f "$MOK_KEY" && -f "$MOK_PUB" && -f "$MOK_PEM" ]]; then
        echo "==> MOK keys already exist in ${MOK_DIR}. Skipping generation."
    else
        echo "==> MOK keys not found. Generating new X.509 keys for Secure Boot..."
        mkdir -p "$MOK_DIR"

        openssl req -new -x509 -newkey rsa:4096 -nodes -days 36500 \
            -subj "/O=$MOK_NAME/CN=$MOK_NAME/emailAddress=$MOK_EMAIL" \
            -addext "basicConstraints=critical,CA:FALSE" \
            -addext "keyUsage=digitalSignature" \
            -keyout "$MOK_KEY" -out "$MOK_PEM"

        openssl x509 -in "$MOK_PEM" -outform DER -out "$MOK_PUB"

        echo "==> MOK generation successful."
        echo "==> NOTE: New keys generated. You may need to enroll $MOK_PUB using mokutil."
    fi
else
    echo "==> Legacy BIOS detected. Secure Boot MOK setup is not applicable."
    UEFI_MODE="false"
fi

export UEFI_MODE

echo "==> Stage 2 completed successfully."
echo "----------------------------------------"
echo
