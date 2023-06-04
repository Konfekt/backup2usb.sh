#!/bin/sh

# debug output and exit on error or use of undeclared variable or pipe error:
set -o xtrace -o errtrace -o nounset -o pipefail

if [ $(id -u) -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# CONFIG {{{
USER=KONFEKT

BKP_LABEL=USB_LABEL
BKP_MOUNT=/run/media/"$USER"/"$BKP_LABEL"
BKP_FOLDER="$BKP_MOUNT"/"${HOSTNAME:-"$(uname -n)"}"
# }}}

FROM_FOLDER=/home/"$USER"

# mount {{{
if ! [ -d "$BKP_MOUNT" ]; then
  mkdir --parents --verbose "$BKP_MOUNT"
fi
chown "$USER":users "$BKP_MOUNT"

unmount() {
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

# ask an external program to supply the passphrase:
# export BORG_PASSCOMMAND='pass show sync/rest'

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$(date)" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"
# Backup the most important directories into an archive named after
# the machine this script is currently running on:

export BORG_REPO="$BKP_FOLDER/borg${FROM_FOLDER}"
borg create \
  --verbose \
  --filter AME \
  --list \
  --stats \
  --show-rc \
  --compression lz4 \
  --exclude-caches \
  --exclude "$FROM_FOLDER/.cache/*" \
  --exclude "$FROM_FOLDER/Music/*" \
  --exclude "$FROM_FOLDER/Pictures/*" \
  --exclude "$FROM_FOLDER/Videos/*" \
  --exclude "$FROM_FOLDER/Downloads/*" \
  --exclude "$FROM_FOLDER/Bluetooth/*" \
  --exclude "$FROM_FOLDER/.local/share/Trash/*" \
  --exclude "$FROM_FOLDER/.local/share/baloo/*" \
  --exclude "$FROM_FOLDER/.local/share/recoll/*" \
  --exclude "$FROM_FOLDER/.mozilla/firefox/*-backup-crashrecovery-*/*" \
  --exclude '.goldendict/index/' \
  --exclude '*/Crash Reports/*' \
  --exclude '.gvfs' \
  --exclude '.thumbnails' \
  --exclude 'thumbnails' \
  --exclude '.cache/*' \
  --exclude '[Cc]ache*/*' \
  --exclude '*[Cc]ache/*' \
  --exclude '*.tmp' \
  --exclude 'temp/*' \
  --exclude 'tmp/*' \
  --exclude '*.log' \
  --exclude 'log/*' \
  --exclude 'logs/*' \
  ::'{hostname}-{now:%Y-%m-%d}' \
  "$FROM_FOLDER"/

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune \
  --list \
  --prefix '{hostname}-' \
  --show-rc \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6

prune_exit=$?

# use highest exit code as global exit code
global_exit=$((backup_exit > prune_exit ? backup_exit : prune_exit))

if [ ${global_exit} -eq 0 ]; then
  info "Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
  info "Backup and/or Prune finished with warnings"
else
  info "Backup and/or Prune finished with errors"
fi

exit ${global_exit}
