#!/bin/bash

SYNCTHING_DATA_DIR="${HOME}/syncthing/lanchelms-game-saves/lanchelms-deep-north"
VALHEIM_SAVES_DIR="${HOME}/lanchelms-valheim-data/saves"
WORLD_NAME="Dedicated" # Update if your world name changes

# Ensure directories exist
mkdir -p "${SYNCTHING_DATA_DIR}/characters_local"
mkdir -p "${SYNCTHING_DATA_DIR}/worlds_local"

# 1. Clone configs
echo "Cloning configs from ${VALHEIM_SAVES_DIR}..."
rsync -ai \
  --include='*.txt' \
  --include='prefs' \
  --exclude='*' \
  "${VALHEIM_SAVES_DIR}"/ \
  "${SYNCTHING_DATA_DIR}"/

# 2. Clone character .old files
echo "Cloning character .old files from ${VALHEIM_SAVES_DIR}/characters_local..."
rsync -ai \
  --include='*.old' \
  --exclude='*' \
  "${VALHEIM_SAVES_DIR}/characters_local/" \
  "${SYNCTHING_DATA_DIR}/characters_local/"

# 3. Handle the World Saves (Valheim 1.0 Backup Directory structure)
echo "Finding the latest world auto-backup directory..."

# Find all auto-backup directories for the specific world, sort them in reverse (newest first), and grab the top 1
LATEST_BACKUP_DIR=$(find "${VALHEIM_SAVES_DIR}/worlds_local" -maxdepth 1 -type d -name "${WORLD_NAME}_backup_auto-*" | sort -r | head -n 1)

if [ -n "${LATEST_BACKUP_DIR}" ]; then
    echo "Found latest backup: $(basename "${LATEST_BACKUP_DIR}")"
    TARGET_GZ="${SYNCTHING_DATA_DIR}/worlds_local/${WORLD_NAME}_latest_backup.tar.gz"
    tar -C "${LATEST_BACKUP_DIR}" -czf "${TARGET_GZ}" .
    echo "Successfully zipped into ${TARGET_GZ}"
else
    echo "No auto backup directory found for ${WORLD_NAME}!"
fi

echo "Sync script complete."

