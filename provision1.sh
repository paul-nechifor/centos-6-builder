#!/bin/bash -eux

HOME_DIR="${HOME_DIR:-/home/vagrant}"

main() {
    sshd
    networking
    package_update
    reboot
    sleep 120
}

sshd() {
    echo "UseDNS no" >> /etc/ssh/sshd_config
    echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
}

networking() {
    echo 'RES_OPTIONS="single-request-reopen"' >> /etc/sysconfig/network
    service network restart
}

package_update() {
    yum -y update
}

main
