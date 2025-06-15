#!/bin/bash

# ======== Default Values ========
STORAGE_TYPE=""
ROOT_DEVICE=""

# ======== Usage Function ========
usage() {
    echo "Usage: $0 --storage [nvme|emmc]"
    echo "Options:"
    echo "  --storage nvme    Use NVME storage (root=/dev/nvme0n1p1)"
    echo "  --storage emmc    Use eMMC storage (root=/dev/mmcblk0p1)"
    echo "  -h, --help       Show this help message"
    exit 1
}

# ======== Parse Arguments ========
while [[ $# -gt 0 ]]; do
    case "$1" in
        --storage)
            STORAGE_TYPE="$2"
            case "$STORAGE_TYPE" in
                nvme)
                    ROOT_DEVICE="/dev/nvme0n1p1"
                    ;;
                emmc)
                    ROOT_DEVICE="/dev/mmcblk0p1"
                    ;;
                *)
                    echo "Error: Invalid storage type. Use 'nvme' or 'emmc'"
                    usage
                    ;;
            esac
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown argument $1"
            usage
            ;;
    esac
done

# Check if storage type is provided
if [ -z "$STORAGE_TYPE" ]; then
    echo "Error: Storage type not specified"
    usage
fi

# ======== Install RT Kernel ========
install_rt_kernel() {
    sudo cp -rf ./compiled/5.15.148-rt-tegra /lib/modules/ && \
    sudo cp -rf ./compiled/dtbs /boot/dtbs/ && \
    sudo cp -rf ./compiled/image.rt /boot/image.rt && \
    sudo cp -rf ./compiled/initrd.img-5.15.148-rt-tegra /boot/initrd.img-5.15.148-rt-tegra

    # Create a temporary file with the content to insert
    cat << EOF > /tmp/kernel_config
LABEL primary
    MENU LABEL primary kernel
    LINUX /boot/Image
    INITRD /boot/initrd
    APPEND \${cbootargs} root=$ROOT_DEVICE rw rootwait rootfstype=ext4 mm init_loglevel=4 console=ttyTCU0,115200 console=ttyAMA0,115200 firmware_class.path=/etc/firmware fbcon=map:0 nospectre_bhb video=efifb:off console=tty0
EOF

    # Insert the content into /boot/extlinux/extlinux.conf
    sudo sed -i '/TIMEOUT 10/r /tmp/kernel_config' /boot/extlinux/extlinux.conf

    # Clean up temporary file
    rm -f /tmp/kernel_config

    return $?
}

# Run installation and check result
if install_rt_kernel; then
    echo "[SUCCESS] RT kernel installation completed successfully with $STORAGE_TYPE storage"
    exit 0
else
    echo "[FAILED] RT kernel installation failed"
    exit 1
fi