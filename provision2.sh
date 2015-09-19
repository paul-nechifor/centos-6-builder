#!/bin/bash -eux

HOME_DIR="${HOME_DIR:-/home/vagrant}"

main() {
    vagrant
    vmtools
    cleanup
    minimize
}

vagrant() {
    mkdir -p "$HOME_DIR/.ssh";
    chown -R vagrant "$HOME_DIR/.ssh"
    chmod -R go-rwsx "$HOME_DIR/.ssh"
    mv /tmp/vagrant.pub "$HOME_DIR/.ssh/authorized_keys"
}

vmtools() {
    mkdir -p /tmp/vbox
    local ver="$(cat /home/vagrant/.vbox_version)"
    mount -o loop "$HOME_DIR/VBoxGuestAdditions_${ver}.iso" /tmp/vbox
    sh /tmp/vbox/VBoxLinuxAdditions.run || echo "VBoxLinuxAdditions.run failed."
    umount /tmp/vbox
    rm -rf /tmp/vbox
    rm -f "$HOME_DIR"/*.iso
}

cleanup() {
    # Remove development and kernel source packages
    yum -y remove gcc cpp kernel-devel kernel-headers perl
    yum -y clean all

    # Clean up network interface persistence
    rm -f /etc/udev/rules.d/70-persistent-net.rules;

    # shellcheck disable=SC2045
    for ndev in $(ls -1 /etc/sysconfig/network-scripts/ifcfg-*); do
        if [[ "$(basename "$ndev")" != "ifcfg-lo" ]]; then
            sed -i '/^HWADDR/d' "$ndev"
            sed -i '/^UUID/d' "$ndev"
        fi
    done

    rm -f VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?
}

minimize() {
    local swapuuid="$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)";

    if [ "x${swapuuid}" != "x" ]; then
        # Whiteout the swap partition to reduce box size
        # Swap is disabled till reboot
        swappart="$(readlink -f "/dev/disk/by-uuid/$swapuuid")";
        /sbin/swapoff "$swappart";
        dd if=/dev/zero of="$swappart" bs=1M || echo "ignore dd exit code $?"
        /sbin/mkswap -U "$swapuuid" "$swappart"
    fi

    dd if=/dev/zero of=/EMPTY bs=1M || echo "ignore dd exit code $?"
    rm -f /EMPTY
    # Block until the empty file has been removed, otherwise, Packer
    # will try to kill the box while the disk is still full and that's bad
    sync
}

main
