#!/usr/bin/env bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# IMPORTANT:
# Run the install-little-backup-box.sh script first
# to install the required packages and configure the system.

CONFIG_DIR=$(dirname "$0")
CONFIG="${CONFIG_DIR}/config.cfg"

source "$CONFIG"

# Set the ACT LED to heartbeat
sudo sh -c "echo heartbeat > /sys/class/leds/led0/trigger"

# Wait for a USB storage device (e.g., a USB flash drive)
STORAGE=$(ls /dev/* | grep "$STORAGE_DEV" | cut -d"/" -f3)
while [ -z ${STORAGE} ]
  do
  sleep 1
  STORAGE=$(ls /dev/* | grep "$STORAGE_DEV" | cut -d"/" -f3)
done

# When the card reader is detected, mount it
mount /dev/"$STORAGE_DEV" "$STORAGE_MOUNT_POINT"

# Set the ACT LED to blink at 1000ms to indicate that the card reader has been mounted
sudo sh -c "echo timer > /sys/class/leds/led0/trigger"
sudo sh -c "echo 1000 > /sys/class/leds/led0/delay_on"

# If display support is enabled, notify that the card reader has been mounted
if [ $DISP = true ]; then
    oled r
    oled +a "Card reader OK"
    oled +b "Working..."
    sudo oled s
fi

# Create  a .id random identifier file if doesn't exist
cd "$STORAGE_MOUNT_POINT"
if [ ! -f *.id ]; then
  random=$(echo $RANDOM)
  touch $(date -d "today" +"%Y%m%d%H%M")-$random.id
fi
ID_FILE=$(ls *.id)
ID="${ID_FILE%.*}"
cd

# Set the backup path
BACKUP_PATH="$BAK_DIR"/"$ID"


# Perform backup using rsync
if [ $DISP = true ]; then
  rsync -avh --info=progress2 --exclude "*.id" "$STORAGE_MOUNT_POINT"/ "$BACKUP_PATH" | ./oled-rsync-progress.sh exclude-file.txt
  sudo touch "$STORAGE_MOUNT_POINT"/ "$BACKUP_PATH"
else
  rsync -avh --info=progress2 --exclude "*.id" "$STORAGE_MOUNT_POINT"/ "$BACKUP_PATH"
  sudo touch "$STORAGE_MOUNT_POINT"/ "$BACKUP_PATH"
fi

# If display support is enabled, notify that the backup is complete
if [ $DISP = true ]; then
    oled r
    oled +a "Backup complete"
    oled +b "Shutdown"
    sudo oled s
fi
# Shutdown
sync
shutdown -h now
