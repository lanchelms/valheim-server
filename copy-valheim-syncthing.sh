exit 0

SYNCTHING_DATA_DIR="syncthing/lanchelms-game-saves/lanchelms-deep-north"
VALHEIM_SAVES_DIR="lanchelms-valheim-data/saves"

# Ensure directories exist
mkdir -p $SYNCTHING_DATA_DIR/characters_local
mkdir -p $SYNCTHING_DATA_DIR/worlds_local

# Clone configs
echo "cloning configs from $VALHEIM_SAVES_DIR"

rsync -ai \
  --include='*.txt' \
  --include='prefs' \
  --exclude='*' \
  "$VALHEIM_SAVES_DIR"/ \
  "$SYNCTHING_DATA_DIR"/

# Clone ".old" files, which are the newest non-primary files in the directory
echo "cloning character .old files from $VALHEIM_SAVES_DIR"

rsync -ai \
  --include='*.old' \
  --exclude='*' \
  "$VALHEIM_SAVES_DIR/characters_local"/ \
  "$SYNCTHING_DATA_DIR/characters_local"/

echo "cloning world save .old files from $VALHEIM_SAVES_DIR"

rsync -ai \
  --include='*.old' \
  --exclude='*' \
  "$VALHEIM_SAVES_DIR/worlds_local"/ \
  "$SYNCTHING_DATA_DIR/worlds_local"/

echo "copy explored file"

rsync -ai \
  --include='*.explored' \
  --exclude='*' \
  "$VALHEIM_SAVES_DIR/worlds_local"/ \
  "$SYNCTHING_DATA_DIR/worlds_local"/
