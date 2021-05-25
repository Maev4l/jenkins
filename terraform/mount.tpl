#!/bin/bash
mkdir ${mount_point}
mkfs -t ext4 ${device}
mount ${device} ${mount_point}