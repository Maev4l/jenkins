#!/bin/bash
mkdir ${mount_point}
mkfs -t ext4 ${device}
mount ${device} ${mount_point}
echo "${device} ${mount_point}  ext4    defaults    0   0 " >> /etc/fstab