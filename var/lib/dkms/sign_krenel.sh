#ver=$(uname -r)
ver=6.19.5-lazy-1000hz
echo "Kernel version: $ver"
sbsign --key mok.key --cert mok.pem /boot/vmlinuz-$ver --output /tmp/vmlinuz
mv /tmp/vmlinuz /boot/vmlinuz-$ver
