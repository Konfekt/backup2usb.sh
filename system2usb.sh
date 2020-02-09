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

mount --verbose  --types ntfs --options windows_names LABEL="$BKP_LABEL" --target "$BKP_MOUNT"
if ! mountpoint --quiet "$BKP_MOUNT" ; then
  echo "Could not mount! Quitting."
  exit 1
fi
if ! [ -d "$BKP_FOLDER" ] ; then
  echo "Backup folder inexistent on mount point! Quitting."
  exit 1
fi
# }}}

mkdir --parents "$BKP_FOLDER"/system-tar-and-restore

star.sh "$HOME_FOLDER"/.config/backups/usb/BackupRoot2USB.conf \
  --mode 0 --quiet \
  --destination "$BKP_FOLDER"/system-tar-and-restore
