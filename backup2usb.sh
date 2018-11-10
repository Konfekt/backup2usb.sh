#!/bin/sh

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

ROOT_FOLDER=
HOME_FOLDER=/home/"$USER"

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

# Backup files:
# For excludes, see http://askubuntu.com/questions/28477/what-is-safe-to-exclude-for-a-full-system-backup/28488#28488
# and for updating the /etc/fstab, see 
# https://wiki.archlinux.org/index.php/full_system_bacp_with_rsync#Update_the_fstab

mkdir --parents "$BKP_FOLDER/rsync/home/$USER"
# exclude: multimedia, downloaded data, index files and temp files
  # --exclude='/Music/' \
  # --exclude='/Pictures/' \
  # --exclude='/Videos/' \
rsync -axEHA --delete --modify-window=1 --verbose --human-readable --info=progress2 \
  --exclude='/Downloads/' \
  --exclude='/Bluetooth/' \
  --exclude='/.cache/' \
  --exclude='/.local/share/Trash/' \
  --exclude='/.local/share/baloo/' \
  --exclude='/.local/share/recoll/' \
  --exclude='.goldendict/index/' \
  --exclude='.mozilla/firefox/*-backup-crashrecovery-*/' \
  --exclude='.thumbnails/' \
  --exclude='thumbnails/' \
  --exclude='*.log' \
  --exclude='log/' \
  --exclude='logs/' \
  --exclude='.[Cc]ache/' \
  --exclude='[Cc]ache/' \
  --exclude='*.tmp' \
  --exclude='[Tt]emp/' \
  --exclude='[Tt]mp/' \
  --exclude='*[<>":\|?*]*' \
  "$HOME_FOLDER"/ "$BKP_FOLDER/rsync/home/$USER"/

# exclude: boot and kernel modules, backups, home, removable media and temp files
mkdir --parents "$BKP_FOLDER/rsync"
rsync -axEHA --delete --modify-window=1 --verbose --human-readable --info=progress2 \
  --exclude='/home/' \
  --exclude='/.snapshots/' \
  --exclude='/media/' \
  --exclude='/mnt/' \
  --exclude='/run/' \
  --exclude='/dev/' \
  --exclude='/proc/' \
  --exclude='/sys/' \
  --exclude='/tmp/' \
  --exclude='/var/run/' \
  --exclude='/var/lock/' \
  --exclude='/var/tmp/' \
  --exclude='/var/lib/systemd/coredump/' \
  --exclude='/lib/modules/*/volatile/.mounted' \
  --exclude='*.log' \
  --exclude='log/' \
  --exclude='logs/' \
  --exclude='.[Cc]ache/' \
  --exclude='[Cc]ache/' \
  --exclude='*.tmp' \
  --exclude='[Tt]emp/' \
  --exclude='[Tt]mp/' \
  --exclude='*[<>":\|?*]*' \
  "$ROOT_FOLDER"/ "$BKP_FOLDER/rsync"/

# unmount
if [ -e "$BKP_FOLDER" ]; then
  umount --verbose "$BKP_MOUNT"*
  rmdir --verbose "$BKP_MOUNT"*
fi
