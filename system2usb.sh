#! /usr/bin/env sh 

# To mount the archive, see https://unix.stackexchange.com/questions/31669/is-it-possible-to-mount-a-gzip-compressed-dd-image-on-the-fly/138081#138081

# Mount ...
#
# ... by Archivemount:
#
#   archivemount sda1.img.xz /mnt

# ... by NBD:
#
# DIRECTLY:
#
#   nbdkit pixz file=sda1.img.xz --run 'guestfish --format=raw -a $nbd -i'
#
# OR:
#
# Serve it with nbdkit:
#
#   nbdkit --no-fork --user nobody --group nobody -i 127.0.0.1 pixz file=sda1.img.xz
#
# Connect to the NBD server:
#
#   nbd-client 127.0.0.1 10809 /dev/nbd0 -nofork
#
# Mount it read-only:
#
#   mount -o ro /dev/nbd0 sda1
#
# When done:
#
#   umount /dev/nbd0
#   nbd-client -d /dev/nbd0
#
# Stop nbdkit by pressing Ctrl+C (or with kill).

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# CONFIG {{{
USER=KONFEKT

BKP_LABEL=USB_LABEL
[ -z "$HOSTNAME" ] && HOSTNAME="$(uname -n)"
BKP_SUBFOLDER=$HOSTNAME
# CONFIG }}}

MOUNT=/run/media/"$USER"
BKP_MOUNT="$MOUNT"/"$BKP_LABEL"
BKP_FOLDER="$BKP_MOUNT"/"$BKP_SUBFOLDER"

# mount
if ! [ -e "$BKP_MOUNT" ] ; then
  mkdir --parents "$BKP_MOUNT"
  chown "$USER":users "$BKP_MOUNT"
  mount --verbose --types ntfs LABEL="$BKP_LABEL" --target "$BKP_MOUNT"
fi
sleep 1
if ! mountpoint --quiet "$BKP_MOUNT" ; then
  rmdir --verbose "$BKP_MOUNT"
  exit 1
fi

mkdir --parents "$BKP_FOLDER"/system-tar-and-restore

/home/"$USER"/bin/star.sh /home/"$USER"/.config/backups/usb/BackupRoot2USB.conf \
  --mode 0 --quiet \
  --destination "$BKP_FOLDER"/system-tar-and-restore

# unmount
if [ -e "$BKP_FOLDER" ]; then
  umount --verbose "$BKP_MOUNT"*
  rmdir --verbose "$BKP_MOUNT"*
fi
