#!/usr/bin/env bash

# Fail fast on pipeline errors
set -e

# Enforce root privileges execution at the entry point
if [ "$EUID" -ne 0 ]; then
  echo "Root privileges required! Re-run with the 'sudo' command or as root."
  exit 1
fi

KERNEL_TYPE="stock"
MOK_NAME="Machine Owner Key ${SUDO_USER:-$USER}"
MOK_EMAIL="${SUDO_USER:-$USER}@$(hostnamectl --static)"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --kernel-type)    KERNEL_TYPE="$2"; shift 2 ;;
        --kernel-type=*)  KERNEL_TYPE="${1#*=}"; shift 1 ;;

        --mok-name)       MOK_NAME="$2"; shift 2 ;;
        --mok-name=*)     MOK_NAME="${1#*=}"; shift 1 ;;

        --mok-email)      MOK_EMAIL="$2"; shift 2 ;;
        --mok-email=*)    MOK_EMAIL="${1#*=}"; shift 1 ;;

        -h|--help)
            echo "Usage: $0 [--kernel-type stock|vanilla] [--mok-name NAME] [--mok-email EMAIL]"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

# Validate kernel type argument
if [[ "$KERNEL_TYPE" != "stock" && "$KERNEL_TYPE" != "vanilla" ]]; then
    echo "'--kernel-type' must be either 'stock' or 'vanilla'."
    exit 1
fi


# Define and export global pipeline variables
export REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export WORK_DIR="/usr/local/src"
export KERNEL_CONFIG="${REPO_DIR}/.config"
#echo "REPO_DIR = ${REPO_DIR}"
#echo "WORK_DIR = ${WORK_DIR}"
#echo "KERNEL_CONFIG = ${KERNEL_CONFIG}"
export KERNEL_TYPE
export MOK_NAME
export MOK_EMAIL
#echo "Kernel type: ${KERNEL_TYPE}"
#echo "MOK name:    ${MOK_NAME}"
#echo "MOK e-mail:  ${MOK_EMAIL}"
export KERNEL_SRC_DIR=""
export KERNEL_VERSION=""

echo "==> Initiating Debian kernel build pipeline..."

# Execute pipeline stages in the current shell context
source "${REPO_DIR}/01-install_deps.sh"
source "${REPO_DIR}/02-setup_mok.sh"
source "${REPO_DIR}/03-fetch_source.sh"
source "${REPO_DIR}/04-apply_config.sh"
source "${REPO_DIR}/05-build_kernel.sh"
source "${REPO_DIR}/06-install_kernel.sh"
source "${REPO_DIR}/07-sign_kernel.sh"

echo "==> Current pipeline execution completed."
echo "==> Active kernel source directory: ${KERNEL_SRC_DIR}"
echo "==> Kernel version: ${KERNEL_VERSION}"
echo
echo "You must use 'mokutil --import ${MOK_PUB}' command before reboot!"
echo
