#!/usr/bin/env bash

set -euo pipefail

# Require root privileges
if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] This script must be run as root." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_ROOT="/"

# Array of root-level directories in the repository to process
SOURCE_DIRS=("etc")

echo "[INFO] Deploying configurations to '${TARGET_ROOT}'..."

for dir_it in "${SOURCE_DIRS[@]}"; do
    source_dir="${REPO_DIR}/${dir_it}"

    if [[ ! -d "${source_dir}" ]]; then
        echo "[WARN] Source directory '${source_dir}' not found. Skipping." >&2
        continue
    fi

    # Process configuration files recursively
    find "${source_dir}" -type f -print0 | while IFS= read -r -d '' file; do
        dir_path=$(dirname "$file")
        encoded_basename=$(basename "$file")

        # Parse the naming pattern: owner_group_perms_filename
        IFS=_ read -r owner group perms real_filename <<< "$encoded_basename"

        # Skip files that do not match the expected pattern
        if [[ -z "$owner" || -z "$group" || -z "$perms" || -z "$real_filename" ]]; then
            echo "[WARN] Skipping: $file (does not match 'owner_group_perms_filename' pattern)" >&2
            continue
        fi

        # Compute relative directory path by stripping REPO_DIR
        rel_dir="${dir_path#"${REPO_DIR}/"}"

        # Compute absolute target paths
        target_dir="${TARGET_ROOT%/}/${rel_dir}"
        target_file="${target_dir}/${real_filename}"
        backup_file="${target_file}.he-backup"

        # Create target directory hierarchy if it does not exist
        mkdir -p "$target_dir"

        # Create a backup of the existing file (only if backup doesn't already exist)
        #if [[ -e "$target_file" ]]; then
        #    if [[ ! -e "$backup_file" ]]; then
        #        echo "[INFO] Creating backup: $backup_file"
        #        cp -a "$target_file" "$backup_file"
        #    fi
        #fi

        # Deploy the file and apply security attributes
        cp "$file" "$target_file"
        chown "${owner}:${group}" "$target_file"
        chmod "${perms}" "$target_file"

        echo "[INFO] -> $target_file ($owner:$group $perms)"
        echo
    done
done


echo "[INFO] Applying system hardening patches..."

# Secure process information (hidepid=2)
echo "Securing /proc mounts (hidepid=2) in /etc/fstab"
if ! grep -q "hidepid=2" /etc/fstab; then
    if grep -qE "^proc\s+/proc" /etc/fstab; then
        sed -i 's|^\(proc\s\+/proc\s\+proc\s\+\S*\)|\1,hidepid=2|' /etc/fstab
    else
        echo -e "proc\t/proc\tproc\tdefaults,hidepid=2\t0\t0" >> /etc/fstab
    fi
    mount -o remount,hidepid=2 /proc || true
fi

echo "Restricting access to /boot artifacts (config, System.map, etc.)"
find /boot -maxdepth 1 -type f -name "config-*" -exec chmod 400 {} + || true
find /boot -maxdepth 1 -type f -name "System.map-*" -exec chmod 400 {} + || true
find /boot -maxdepth 1 -type f -name "vmlinuz-*" -exec chmod 400 {} + || true
find /boot -maxdepth 1 -type f -name "initrd.img-*" -exec chmod 400 {} + || true
chmod 500 /boot


echo "Disabling initramfs resume (RESUME=none)"
mkdir -p /etc/initramfs-tools/conf.d
echo "RESUME=none" > /etc/initramfs-tools/conf.d/resume

echo "Reloading system states..."
sysctl --system >/dev/null 2>&1 || true


echo "Reload D-Bus configuration to apply new policies"
if systemctl is-active --quiet dbus; then
    systemctl reload dbus || true
fi


if [[ -f "/etc/nftables.conf" ]]; then
    echo "Enable firewall"
    systemctl enable --now nftables.service || true
fi

echo "Deployment completed successfully."
