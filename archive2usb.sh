#!/bin/sh

# debug output and exit on error or use of undeclared variable or pipe error:
set -o xtrace -o errtrace -o errexit -o nounset -o pipefail

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# CONFIG {{{
USER=KONFEKT

BKP_LABEL=USB_LABEL
BKP_MOUNT=/run/media/"$USER"/"$BKP_LABEL"
BKP_FOLDER="$BKP_MOUNT"/"${HOSTNAME:-"$(uname -n)"}"
# }}}

ROOT_FOLDER=
HOME_FOLDER=/home/"$USER"

# mount {{{
if ! [ -d "$BKP_MOUNT" ] ; then
  mkdir --parents "$BKP_MOUNT"
fi
chown "$USER":users "$BKP_MOUNT"

unmount () {
  if [ -d "$BKP_MOUNT" ]; then
    sleep 3
    umount --verbose "$BKP_MOUNT"*
    rmdir --verbose "$BKP_MOUNT"*
  fi
}
trap unmount EXIT

if ! mountpoint --quiet "$BKP_MOUNT"; then
  mount --verbose --types ntfs --options windows_names LABEL="$BKP_LABEL" --target "$BKP_MOUNT"
  if ! mountpoint --quiet "$BKP_MOUNT"; then
    echo "Could not mount! Quitting."
    exit 1
  fi
fi
if ! [ -d "$BKP_FOLDER" ]; then
  echo "Backup folder inexistent on mount point! Quitting."
  exit 1
fi
# }}}

TODAY=$(date +%Y-%m-%d)
mkdir --parents "$BKP_FOLDER"

# BACKUP ~/

# For excludes, see http://askubuntu.com/questions/28477/what-is-safe-to-exclude-for-a-full-system-backup/28488#28488
# and for updating the /etc/fstab, see 
# https://wiki.archlinux.org/index.php/full_system_bacp_with_rsync#Update_the_fstab

mkdir --parents "$BKP_FOLDER/fsarchiver"
# cpu_cores=$((`grep -c \^processor /proc/cpuinfo`))
cpu_cores=$(getconf _NPROCESSORS_ONLN)
jobs=$(( cpu_cores < 2 ? 1 : $(( cpu_cores - 1 )) ))

# exclude: multimedia, downloaded data, index files and temp files
fsarchiver --jobs=$jobs --verbose --overwrite --allow-rw-mounted \
  --exclude="$HOME_FOLDER/Music" \
  --exclude="$HOME_FOLDER/Pictures" \
  --exclude="$HOME_FOLDER/Videos" \
  --exclude="$HOME_FOLDER/Downloads" \
  --exclude="$HOME_FOLDER/Bluetooth" \
  --exclude="$HOME_FOLDER/.cache/" \
  --exclude="$HOME_FOLDER/.local/share/Trash" \
  --exclude="$HOME_FOLDER/.local/share/baloo" \
  --exclude="$HOME_FOLDER/.local/share/recoll" \
  --exclude='.goldendict/index' \
  --exclude='.mozilla/firefox/*/*-backup-crashrecovery-*' \
  --exclude='.gvfs' \
  --exclude='.thumbnails' \
  --exclude='thumbnails' \
  --exclude='.cache' \
  --exclude='cache' \
  --exclude='*.tmp' \
  --exclude='temp' \
  --exclude='tmp' \
  --exclude='*.log' \
  --exclude='log' \
  --exclude='logs' \
  savedir "$BKP_FOLDER/fsarchiver/home_$TODAY.fsa" "$HOME_FOLDER"

# Backup / !
# exclude: boot and kernel modules, backups, home, removable media and temp files
fsarchiver --jobs=$jobs --verbose --overwrite --allow-rw-mounted \
  --exclude='/etc/fstab' \
  --exclude='/boot' \
  --exclude='/lib' \
  --exclude='/lib64' \
  --exclude='/.snapshots' \
  --exclude='/home' \
  --exclude='/media' \
  --exclude='/mnt' \
  --exclude='/run' \
  --exclude='/dev' \
  --exclude='/proc' \
  --exclude='/sys' \
  --exclude='/tmp' \
  --exclude='/var/run' \
  --exclude='/var/lock' \
  --exclude='/var/tmp' \
  --exclude='/var/cache' \
  --exclude='/var/lib/systemd/coredump' \
  --exclude='/lib/modules/*/volatile/.mounted' \
  savedir "$BKP_FOLDER/fsarchiver/root_$TODAY.fsa" "$ROOT_FOLDER"

# ROOT_DRIVE=/dev/sda
# # Backup MBR + Partition Table!
# mkdir --parents "$BKP_FOLDER/mbr"
# dd if=$ROOT_DRIVE of="$BKP_FOLDER/mbr/mbr_$TODAY" count=1 bs=512 
# mkdir --parents "$BKP_FOLDER/partition_table"
# sfdisk -d $ROOT_DRIVE > "$BKP_FOLDER/partition_table/partition_table_$TODAY.sfdisk"
