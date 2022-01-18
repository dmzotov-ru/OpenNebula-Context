# This scripts define new volatile disks and will create swap partition and mount second disk as /DATA. UUID will be writed to /etc/fstab
# Tested on CentOS 


#!/bin/bash
swapoff /dev/mapper/centos-swap
DEVICE="sdc"
MOUNTPOINT="/DATA"
SWAP_UUID="$(blkid -s UUID -o value /dev/sdb)"

mount_data_disk() {
if [ -z "$(lsblk -f | grep "^${DEVICE}.*${MOUNTPOINT}$")" ]; then
   echo "The device $DEVICE isn't mounted as $MOUNTPOINT"
   if  [ -d "$MOUNTPOINT" ]; then
        mount /dev/$DEVICE $MOUNTPOINT
        echo "The device $DEVICE has been mounted as $MOUNTPOINT"
   else
        mkdir $MOUNTPOINT
        mount /dev/$DEVICE $MOUNTPOINT
        echo "The mountpoint $MOUNTPOINT has been created and device $DEVICE mounted"   
   fi
else
  echo "The device $DEVICE has already been mounted as $MOUNTPOINT"
fi
}



if [ "$(uname -s)" = 'Linux' ] && [ -n "$(lsblk -f | grep -w $DEVICE)" ]; then
    echo "There is device $DEVICE found"
    mount_data_disk
fi

sed -i "s/\/dev\/mapper\/centos-swap/UUID=${SWAP_UUID}/g" /etc/fstab
