These simple (`POSIX` compliant for `UNIX` based operating systems, such as `Linux`, `Free BSD` and `MacOS`) shell scripts

- back up all files and folders inside the `$HOME` folder and root directory `/`
- except those listed with `--exclude`

via `rsync`, [borg](https://borgbackup.readthedocs.io/en/stable/quickstart.html), [fsarchiver](http://www.fsarchiver.org/QuickStart) or [system-tar-and-restore](https://linoxide.com/linux-how-to/system-tar-restore-bash-script-linux-backup/) to a `USB` drive with an `NTFS` file system.

# Installation

1. Clone this repository, for example into `~/Downloads`
    ```sh
    cd ~/Downloads/
    git clone https://github.com/konfekt/backup2usb.sh
    ````
0. Copy `borg2usb.sh` `sync2usb.sh`, `archive2usb.sh` or `system2usb.sh` into a convenient folder, for example, `~/bin`
    ```sh
    cp ~/Downloads/sync2usb.sh/sync2usb.sh ~/bin/
    ```

    For `system2usb.sh`, an additional config file `BackupRoot2USB.conf` is needed that is assumed to sit inside `~/.config/backups/usb/`, therefore
    ```sh
    cp --recursive ~/Downloads/sync2usb.sh/backups/ ~/.config/
    ```

0. Inside `sync2usb.sh`, `archive2usb.sh` or `system2usb.sh`, replace

    - `KONFEKT` by your user name to log in to the `rsync` server
    - `USB_LABEL` by the label of your `NTFS` drive, and
    - the files and folders excluded by `--exclude ...` by those that suit you!

# Suggestions

The scripts assume that the backup files go into `$HOSTNAME/{rsync,fsarchiver,system-tar-and-restore}`  on your `USB` drive (where `$HOSTNAME` is the name of the computer).
If you prefer another path, then please adapt accordingly.

Place (some of) the scripts into `/etc/cron.weekly/` for a weekly backup.
